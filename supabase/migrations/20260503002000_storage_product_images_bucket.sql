-- Plantastic: `product-images` Storage bucket + RLS (aligned with Flutter [ProductImageUploadService] bucket default).
--
-- WHY: Missing bucket / policies or schema drift breaks uploads with Storage errors (incl. schema mismatch reports).
-- Idempotent: safe to re-run. Do NOT edit applied migration files; add a new timestamped file for changes.

INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Public URLs in the shop require anonymous SELECT on objects in this bucket.
DROP POLICY IF EXISTS "plantastic_product_images_public_read"
  ON storage.objects;
CREATE POLICY "plantastic_product_images_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

-- Admin editor uploads while signed in use the authenticated JWT.
DROP POLICY IF EXISTS "plantastic_product_images_authenticated_insert"
  ON storage.objects;
CREATE POLICY "plantastic_product_images_authenticated_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'product-images');

DROP POLICY IF EXISTS "plantastic_product_images_authenticated_update"
  ON storage.objects;
CREATE POLICY "plantastic_product_images_authenticated_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'product-images')
  WITH CHECK (bucket_id = 'product-images');

DROP POLICY IF EXISTS "plantastic_product_images_authenticated_delete"
  ON storage.objects;
CREATE POLICY "plantastic_product_images_authenticated_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'product-images');

NOTIFY pgrst, 'reload schema';
