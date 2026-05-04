-- Shop visibility: when false, product is hidden from the customer grid (admin still sees it).

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS visible_in_shop boolean NOT NULL DEFAULT true;

NOTIFY pgrst, 'reload schema';
