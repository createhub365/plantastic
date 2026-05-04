-- Carousel slides + banner sizing + glass tuning for shop_home_banner.

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS slides jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS carousel_interval_ms integer NOT NULL DEFAULT 5000;

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS banner_height_px integer NOT NULL DEFAULT 160;

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS banner_min_height_px integer NOT NULL DEFAULT 120;

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS banner_max_height_px integer NOT NULL DEFAULT 280;

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS glass_blur boolean NOT NULL DEFAULT true;

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS glass_sigma double precision NOT NULL DEFAULT 14;

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS glass_fill_alpha double precision NOT NULL DEFAULT 0.10;

ALTER TABLE public.shop_home_banner
  ADD COLUMN IF NOT EXISTS glass_border_alpha double precision NOT NULL DEFAULT 0.28;

NOTIFY pgrst, 'reload schema';
