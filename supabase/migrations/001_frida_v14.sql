-- FRIDA v1.4 migration
-- Jalankan setelah memeriksa duplikasi employee_id (lihat query di README).

-- ID SF unik, tidak peka huruf besar/kecil, dan mengabaikan spasi tepi.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE employee_id IS NOT NULL AND btrim(employee_id) <> ''
    GROUP BY upper(btrim(employee_id))
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'Ditemukan employee_id duplikat. Jalankan query audit di README, rapikan akun duplikat, lalu jalankan migrasi kembali.';
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_employee_id_unique_idx
ON public.profiles (upper(btrim(employee_id)))
WHERE employee_id IS NOT NULL AND btrim(employee_id) <> '';

-- Email akun SF hanya dapat dibaca melalui fungsi ini oleh Manager/Super Admin.
-- Dipakai untuk menampilkan daftar pengguna di menu Manajemen.
CREATE OR REPLACE FUNCTION public.manager_sf_email_list(target_user_ids uuid[])
RETURNS TABLE(id uuid, email text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.is_manager_or_admin() THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  RETURN QUERY
  SELECT u.id, u.email::text
  FROM auth.users u
  JOIN public.profiles p ON p.id = u.id
  WHERE u.id = ANY(target_user_ids)
    AND p.role = 'sf';
END;
$$;

GRANT EXECUTE ON FUNCTION public.manager_sf_email_list(uuid[]) TO authenticated;

-- Definisi ulang RPC radius dengan urutan stabil untuk pagination.
-- Frontend v1.4 mengambil data per 1.000 baris menggunakan .range().
CREATE OR REPLACE FUNCTION public.odps_within_radius(
  center_lat double precision,
  center_lon double precision,
  radius_m integer DEFAULT 1000,
  status_filter text[] DEFAULT NULL
)
RETURNS TABLE (
  id bigint, odp_name text, latitude double precision, longitude double precision,
  status_2 text, total_port integer, used_port integer, avai_port integer,
  sto_desc text, sifa_kecamatan text, sifa_desa text, tanggal_go_live date,
  distance_m double precision
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  SELECT o.id, o.odp_name, o.latitude, o.longitude, o.status_2,
         o.total_port, o.used_port, o.avai_port, o.sto_desc,
         o.sifa_kecamatan, o.sifa_desa, o.tanggal_go_live,
         extensions.st_distance(
           o.location,
           extensions.st_setsrid(extensions.st_makepoint(center_lon, center_lat),4326)::extensions.geography
         ) AS distance_m
  FROM public.odps o
  WHERE public.is_approved_user()
    AND o.map_valid = true
    AND o.location IS NOT NULL
    AND radius_m BETWEEN 100 AND 10000
    AND extensions.st_dwithin(
      o.location,
      extensions.st_setsrid(extensions.st_makepoint(center_lon, center_lat),4326)::extensions.geography,
      radius_m
    )
    AND (status_filter IS NULL OR o.status_2 = ANY(status_filter))
  ORDER BY distance_m, o.id;
$$;

GRANT EXECUTE ON FUNCTION public.odps_within_radius(double precision,double precision,integer,text[]) TO authenticated;
