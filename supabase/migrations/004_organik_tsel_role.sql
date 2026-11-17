-- FRIDA role expansion: Organik TSEL
-- Apply in Supabase SQL Editor after reviewing the current production schema.

BEGIN;

-- Organik TSEL keeps the cluster selected at registration for organizational reference,
-- but has global read access to ODPs in Bekasi and KarPur.
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_cluster_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_cluster_role_check
  CHECK (
    (role = 'super_admin' AND cluster_id IS NULL)
    OR (role IN ('sf','manager','organik_tsel') AND cluster_id IS NOT NULL)
  ) NOT VALID;

CREATE OR REPLACE FUNCTION public.frida_can_access_odp(target_kabupaten text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT public.frida_is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.account_status = 'approved'
        AND p.role = 'organik_tsel'
    )
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

-- Only Super Admin may promote an approved SF account. Keep its selected cluster_id.
CREATE OR REPLACE FUNCTION public.set_organik_tsel(
  target_user_id uuid
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT public.frida_is_super_admin() THEN
    RAISE EXCEPTION 'Only Super Admin can assign Organik TSEL.';
  END IF;

  UPDATE public.profiles
  SET role = 'organik_tsel',
      updated_at = now()
  WHERE id = target_user_id
    AND role = 'sf'
    AND account_status = 'approved';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Target harus akun SF yang sudah approved.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.set_organik_tsel(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_organik_tsel(uuid) TO authenticated;

COMMIT;

-- After validation:
-- ALTER TABLE public.profiles VALIDATE CONSTRAINT profiles_cluster_role_check;
