-- Rename coir item label (not a brush).
UPDATE kit_catalog_items
SET label = 'Coconut coir'
WHERE id = '11111111-1111-4111-a111-000000000104'::uuid;

NOTIFY pgrst, 'reload schema';
