-- Optional per-gallery-slide labels (flower name + canned snippet), order matches gallery_urls.
ALTER TABLE public.products
    ADD COLUMN IF NOT EXISTS gallery_slide_meta jsonb NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.products.gallery_slide_meta IS
    'Parallel to gallery_urls: [{ "flower_name": "Rose", "snippet": "…" }]';
