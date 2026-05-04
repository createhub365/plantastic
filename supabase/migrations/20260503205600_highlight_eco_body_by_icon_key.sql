-- Fixes empty eco detail in Admin / shopper when row id is not the seeded UUID.
UPDATE highlight_tags
SET body = $e$
This plant carries the eco-friendly highlight because it suits a gentler grow routine: you can lean on mild organic feeding, skip heavy chemical sprays, and reuse sturdy pots while it still thrives. It works well with peat-light or renewable potting mixes and mindful watering—so you enjoy lush green at home with a lighter everyday footprint.
$e$
WHERE icon_key = 'eco';

NOTIFY pgrst, 'reload schema';
