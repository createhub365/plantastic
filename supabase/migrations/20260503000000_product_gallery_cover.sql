-- Product gallery / cover images + kit-level image subsets (stored inside `kits` json).
-- IMPORTANT: Run `20260503002000_storage_product_images_bucket.sql` too (bucket + Storage RLS) so uploads succeed.
-- Ensure Storage bucket `product-images` exists and has appropriate policies before uploads.

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS gallery_urls jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS cover_image_url text NOT NULL DEFAULT '';

-- Backfill only when legacy `image_urls` exists on this project.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'products'
      AND column_name = 'image_urls'
  ) THEN
    UPDATE products
    SET gallery_urls = COALESCE(to_jsonb(image_urls), '[]'::jsonb)
    WHERE (gallery_urls IS NULL OR gallery_urls = '[]'::jsonb)
      AND image_urls IS NOT NULL;
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
