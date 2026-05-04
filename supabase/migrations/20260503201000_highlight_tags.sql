-- Reusable product "highlights" (eco-friendly, vastu, oxygen, etc.) + per-product assignments.

CREATE TABLE IF NOT EXISTS highlight_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
  title text NOT NULL,
  label text NOT NULL DEFAULT '',
  icon_key text NOT NULL DEFAULT 'eco',
  body text NOT NULL DEFAULT '',
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_highlight_tags_sort ON highlight_tags (sort_order ASC);

ALTER TABLE products
ADD COLUMN IF NOT EXISTS highlight_tag_ids uuid[] NOT NULL DEFAULT '{}'::uuid[];

ALTER TABLE highlight_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "highlight_tags_select_all" ON highlight_tags FOR SELECT USING (true);

CREATE POLICY "highlight_tags_insert_authenticated" ON highlight_tags FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "highlight_tags_update_authenticated" ON highlight_tags FOR UPDATE TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "highlight_tags_delete_authenticated" ON highlight_tags FOR DELETE TO authenticated USING (true);

NOTIFY pgrst, 'reload schema';
