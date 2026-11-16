-- FRIDA Cluster Expansion - Migration 003
-- REVIEW BEFORE APPLYING. Apply only after validating against the live schema.
-- Existing approved/pending SF profiles are assigned to BEKASI.
-- Super Admin remains global (cluster_id NULL).

BEGIN;

CREATE TABLE IF NOT EXISTS public.clusters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code IN ('BEKASI','KARPUR')),
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.clusters (code, name)
VALUES
  ('BEKASI', 'Bekasi'),
  ('KARPUR', 'Karawang & Purwakarta')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS cluster_id uuid
  REFERENCES public.clusters(id);

-- Existing SF accounts belong to Bekasi. Super Admin is global.
UPDATE public.profiles p
SET cluster_id = c.id
FROM public.clusters c
WHERE c.code = 'BEKASI'
  AND p.role = 'sf'
  AND p.cluster_id IS NULL;

UPDATE public.profiles
SET cluster_id = NULL
WHERE role = 'super_admin';

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_cluster_role_check
  CHECK (
    (role = 'super_admin' AND cluster_id IS NULL)
    OR (role IN ('sf','manager') AND cluster_id IS NOT NULL)
  ) NOT VALID;

-- Internal helpers use SECURITY DEFINER to avoid recursive RLS evaluation.
CREATE OR REPLACE FUNCTION public.frida_is_approved_user()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.account_status = 'approved'
  );
$$;

CREATE OR REPLACE FUNCTION public.frida_is_super_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.account_status = 'approved'
      AND p.role = 'super_admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.current_user_cluster_id()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT p.cluster_id
  FROM public.profiles p
  WHERE p.id = auth.uid()
    AND p.account_status = 'approved'
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_manager_or_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.account_status = 'approved'
      AND p.role IN ('manager','super_admin')
  );
$$;

CREATE OR REPLACE FUNCTION public.frida_can_manage_profile(target_user_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    public.frida_is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.profiles actor
      JOIN public.profiles target ON target.id = target_user_id
      WHERE actor.id = auth.uid()
        AND actor.account_status = 'approved'
        AND actor.role = 'manager'
        AND target.role = 'sf'
        AND target.cluster_id = actor.cluster_id
    );
$$;

CREATE OR REPLACE FUNCTION public.frida_can_read_session(target_user_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT target_user_id = auth.uid()
    OR public.frida_is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.profiles actor
      JOIN public.profiles target ON target.id = target_user_id
      WHERE actor.id = auth.uid()
        AND actor.account_status = 'approved'
        AND actor.role = 'manager'
        AND target.role = 'sf'
        AND target.cluster_id = actor.cluster_id
    );
$$;

CREATE OR REPLACE FUNCTION public.frida_can_access_odp(target_kabupaten text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT public.frida_is_super_admin()
    OR (
      public.frida_is_approved_user()
      AND (
        (public.current_user_cluster_id() = (SELECT id FROM public.clusters WHERE code='BEKASI')
          AND upper(btrim(coalesce(target_kabupaten,''))) = 'BEKASI')
        OR
        (public.current_user_cluster_id() = (SELECT id FROM public.clusters WHERE code='KARPUR')
          AND upper(btrim(coalesce(target_kabupaten,''))) IN ('KARAWANG','PURWAKARTA'))
      )
    );
$$;

-- Keep compatibility with existing frontend and older SQL functions.
CREATE OR REPLACE FUNCTION public.is_approved_user()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$ SELECT public.frida_is_approved_user(); $$;

-- New registrations must submit cluster_code in Supabase auth metadata.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  selected_cluster_id uuid;
  selected_cluster_code text;
BEGIN
  selected_cluster_code := upper(btrim(coalesce(new.raw_user_meta_data->>'cluster_code','')));
  IF selected_cluster_code NOT IN ('BEKASI','KARPUR') THEN
    RAISE EXCEPTION 'Cluster wajib dipilih saat registrasi.';
  END IF;

  SELECT id INTO selected_cluster_id
  FROM public.clusters
  WHERE code = selected_cluster_code;

  IF selected_cluster_id IS NULL THEN
    RAISE EXCEPTION 'Cluster registrasi tidak valid.';
  END IF;

  INSERT INTO public.profiles
    (id, full_name, employee_id, phone, role, account_status, cluster_id)
  VALUES (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    nullif(new.raw_user_meta_data->>'employee_id',''),
    nullif(new.raw_user_meta_data->>'phone',''),
    'sf',
    'pending',
    selected_cluster_id
  );
  RETURN new;
END;
$$;

-- ODP read access is constrained by the administrative territory.
DROP POLICY IF EXISTS odp_read_approved ON public.odps;
CREATE POLICY odp_read_approved ON public.odps
FOR SELECT TO authenticated
USING (public.frida_can_access_odp(sifa_kabupaten));

-- Profiles: self, Super Admin globally, Manager only own-cluster SF.
DROP POLICY IF EXISTS profile_read_self_or_manager ON public.profiles;
CREATE POLICY profile_read_self_or_manager ON public.profiles
FOR SELECT TO authenticated
USING (
  id = auth.uid()
  OR public.frida_is_super_admin()
  OR public.frida_can_manage_profile(id)
);

-- Session visibility uses a SECURITY DEFINER helper (no RLS recursion).
DROP POLICY IF EXISTS session_read_self_or_manager ON public.access_sessions;
CREATE POLICY session_read_self_or_manager ON public.access_sessions
FOR SELECT TO authenticated
USING (public.frida_can_read_session(user_id));

-- Radius functions keep their existing signatures and filter by cluster.
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
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = public, extensions, pg_temp
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
    AND public.frida_can_access_odp(o.sifa_kabupaten)
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

CREATE OR REPLACE FUNCTION public.odps_within_radius_batch(
  center_lat double precision,
  center_lon double precision,
  radius_m integer DEFAULT 1000,
  status_filter text[] DEFAULT NULL
)
RETURNS TABLE(odps jsonb)
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = public, extensions, pg_temp
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id, 'odp_name', q.odp_name,
        'latitude', q.latitude, 'longitude', q.longitude,
        'status_2', q.status_2, 'total_port', q.total_port,
        'used_port', q.used_port, 'avai_port', q.avai_port,
        'sto_desc', q.sto_desc, 'sifa_kecamatan', q.sifa_kecamatan,
        'sifa_desa', q.sifa_desa, 'tanggal_go_live', q.tanggal_go_live,
        'distance_m', q.distance_m
      ) ORDER BY q.distance_m, q.id
    ), '[]'::jsonb
  ) AS odps
  FROM (
    SELECT o.id, o.odp_name, o.latitude, o.longitude, o.status_2,
      o.total_port, o.used_port, o.avai_port, o.sto_desc,
      o.sifa_kecamatan, o.sifa_desa, o.tanggal_go_live,
      extensions.st_distance(
        o.location,
        extensions.st_setsrid(extensions.st_makepoint(center_lon,center_lat),4326)::extensions.geography
      ) AS distance_m
    FROM public.odps o
    WHERE public.is_approved_user()
      AND public.frida_can_access_odp(o.sifa_kabupaten)
      AND o.map_valid = true
      AND o.location IS NOT NULL
      AND radius_m BETWEEN 100 AND 10000
      AND extensions.st_dwithin(
        o.location,
        extensions.st_setsrid(extensions.st_makepoint(center_lon,center_lat),4326)::extensions.geography,
        radius_m
      )
      AND (status_filter IS NULL OR o.status_2 = ANY(status_filter))
  ) q;
$$;

-- Manager can only manage SF profiles in the same cluster; Super Admin is global.
CREATE OR REPLACE FUNCTION public.manager_sf_email_list(target_user_ids uuid[])
RETURNS TABLE(id uuid, email text)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public, auth, pg_temp
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
    AND p.role = 'sf'
    AND public.frida_can_manage_profile(p.id);
END;
$$;

CREATE OR REPLACE FUNCTION public.set_sf_account_status(
  target_user_id uuid,
  new_status public.fira_account_status
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF new_status NOT IN ('approved','rejected','disabled') THEN
    RAISE EXCEPTION 'Status akun tidak valid.';
  END IF;
  IF NOT public.frida_can_manage_profile(target_user_id) THEN
    RAISE EXCEPTION 'Not authorized for this cluster or user.';
  END IF;

  UPDATE public.profiles
  SET account_status = new_status,
      approved_by = CASE WHEN new_status = 'approved' THEN auth.uid() ELSE approved_by END,
      approved_at = CASE WHEN new_status = 'approved' THEN now() ELSE approved_at END,
      updated_at = now()
  WHERE id = target_user_id AND role = 'sf';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Akun SF tidak ditemukan.';
  END IF;
END;
$$;

-- Only Super Admin can promote an approved SF to Manager.
CREATE OR REPLACE FUNCTION public.set_cluster_manager(
  target_user_id uuid,
  cluster_code text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  selected_cluster_id uuid;
BEGIN
  IF NOT public.frida_is_super_admin() THEN
    RAISE EXCEPTION 'Only Super Admin can assign a Manager.';
  END IF;

  SELECT id INTO selected_cluster_id
  FROM public.clusters
  WHERE code = upper(btrim(cluster_code));

  IF selected_cluster_id IS NULL THEN
    RAISE EXCEPTION 'Cluster tidak valid.';
  END IF;

  UPDATE public.profiles
  SET role = 'manager',
      cluster_id = selected_cluster_id,
      updated_at = now()
  WHERE id = target_user_id
    AND role = 'sf'
    AND account_status = 'approved';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Target harus akun SF yang sudah approved.';
  END IF;
END;
$$;

-- Cluster directory is readable by approved users.
ALTER TABLE public.clusters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS clusters_read_approved ON public.clusters;
CREATE POLICY clusters_read_approved ON public.clusters
FOR SELECT TO authenticated
USING (public.is_approved_user());

-- Function permissions. RLS helper functions are executable by authenticated users.
REVOKE ALL ON FUNCTION public.frida_is_approved_user() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.frida_is_super_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.current_user_cluster_id() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_manager_or_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.frida_can_manage_profile(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.frida_can_read_session(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.frida_can_access_odp(text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.is_approved_user() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.manager_sf_email_list(uuid[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_sf_account_status(uuid, public.fira_account_status) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_cluster_manager(uuid, text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.frida_is_approved_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.frida_is_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_user_cluster_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_manager_or_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.frida_can_manage_profile(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.frida_can_read_session(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.frida_can_access_odp(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_approved_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.manager_sf_email_list(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_sf_account_status(uuid, public.fira_account_status) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_cluster_manager(uuid, text) TO authenticated;

GRANT EXECUTE ON FUNCTION public.odps_within_radius(
  double precision,double precision,integer,text[]
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.odps_within_radius_batch(
  double precision,double precision,integer,text[]
) TO authenticated;

COMMIT;

-- After validation, validate the deferred constraint separately:
-- ALTER TABLE public.profiles VALIDATE CONSTRAINT profiles_cluster_role_check;
--
-- Post-migration checks:
-- SELECT c.code, count(*) FROM public.profiles p
-- LEFT JOIN public.clusters c ON c.id=p.cluster_id
-- WHERE p.role IN ('sf','manager') GROUP BY c.code ORDER BY c.code;
-- SELECT role, account_status, count(*) FROM public.profiles GROUP BY role,account_status;
