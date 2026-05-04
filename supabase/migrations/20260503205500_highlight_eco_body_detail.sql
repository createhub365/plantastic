-- Richer detail copy for Eco-friendly highlight (id ...001).

UPDATE highlight_tags
SET body = $e$
This plant carries the eco-friendly highlight because it suits a gentler grow routine: you can lean on mild organic feeding, skip heavy chemical sprays, and reuse sturdy pots while it still thrives. It works well with peat-light or renewable potting mixes and mindful watering—so you enjoy lush green at home with a lighter everyday footprint.
$e$
WHERE id = '00000000-0000-4000-8000-000000000001'::uuid;

NOTIFY pgrst, 'reload schema';
