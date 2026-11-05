
-- FRIDA v1.4.2: optimasi pengambilan data ODP dalam satu request
-- Fungsi lama tetap dipertahankan untuk kompatibilitas aplikasi versi sebelumnya.

CREATE OR REPLACE FUNCTION public.odps_within_radius_batch(
  center_lat double precision,
  center_lon double precision,
  radius_m integer DEFAULT 1000,
  status_filter text[] DEFAULT NULL
)
RETURNS TABLE(odps jsonb)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'odp_name', q.odp_name,
        'latitude', q.latitude,
        'longitude', q.longitude,
        'status_2', q.status_2,
        'total_port', q.total_port,
        'used_port', q.used_port,
        'avai_port', q.avai_port,
        'sto_desc', q.sto_desc,
        'sifa_kecamatan', q.sifa_kecamatan,
        'sifa_desa', q.sifa_desa,
        'tanggal_go_live', q.tanggal_go_live,
        'distance_m', q.distance_m
      )
      ORDER BY q.distance_m, q.id
    ),
    '[]'::jsonb
  ) AS odps
  FROM (
    SELECT
      o.id,
      o.odp_name,
      o.latitude,
      o.longitude,
      o.status_2,
      o.total_port,
      o.used_port,
      o.avai_port,
      o.sto_desc,
      o.sifa_kecamatan,
      o.sifa_desa,
      o.tanggal_go_live,
      extensions.st_distance(
        o.location,
        extensions.st_setsrid(
          extensions.st_makepoint(center_lon, center_lat), 4326
        )::extensions.geography
      ) AS distance_m
    FROM public.odps o
    WHERE public.is_approved_user()
      AND o.map_valid = true
      AND o.location IS NOT NULL
      AND radius_m BETWEEN 100 AND 10000
      AND extensions.st_dwithin(
        o.location,
        extensions.st_setsrid(
          extensions.st_makepoint(center_lon, center_lat), 4326
        )::extensions.geography,
        radius_m
      )
      AND (
        status_filter IS NULL
        OR o.status_2 = ANY(status_filter)
      )
  ) q;
$$;

GRANT EXECUTE ON FUNCTION public.odps_within_radius_batch(
  double precision,
  double precision,
  integer,
  text[]
) TO authenticated;
