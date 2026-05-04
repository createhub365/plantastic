-- Singleton shop home hero (cover image/video vs gradient). Public read; admins edit.

CREATE TABLE IF NOT EXISTS public.shop_home_banner (
  id smallint PRIMARY KEY DEFAULT 1,
  CONSTRAINT shop_home_banner_singleton CHECK (id = 1),
  updated_at timestamptz NOT NULL DEFAULT now(),
  media_kind text NOT NULL DEFAULT 'gradient'
    CHECK (media_kind IN ('gradient', 'image', 'video')),
  media_url text,
  title_overlay text NOT NULL DEFAULT 'Grow your own garden 🌱'
);

INSERT INTO public.shop_home_banner (id, media_kind, media_url, title_overlay)
VALUES (1, 'gradient', NULL, 'Grow your own garden 🌱')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.shop_home_banner ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "shop_home_banner_select_all" ON public.shop_home_banner;
CREATE POLICY "shop_home_banner_select_all"
  ON public.shop_home_banner FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "shop_home_banner_staff_insert" ON public.shop_home_banner;
CREATE POLICY "shop_home_banner_staff_insert"
  ON public.shop_home_banner FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.plantastic_staff s
      WHERE s.user_id = auth.uid()
        AND COALESCE(s.is_admin, FALSE) IS TRUE
    )
  );

DROP POLICY IF EXISTS "shop_home_banner_staff_update" ON public.shop_home_banner;
CREATE POLICY "shop_home_banner_staff_update"
  ON public.shop_home_banner FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.plantastic_staff s
      WHERE s.user_id = auth.uid()
        AND COALESCE(s.is_admin, FALSE) IS TRUE
    )
  )
  WITH CHECK (true);

NOTIFY pgrst, 'reload schema';
