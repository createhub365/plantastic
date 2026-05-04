-- Raise max object size for `product-images` (hero banner videos hit HTTP 413 otherwise).
-- Limit is in bytes (100 MiB).

UPDATE storage.buckets
SET file_size_limit = 104857600
WHERE id = 'product-images';
