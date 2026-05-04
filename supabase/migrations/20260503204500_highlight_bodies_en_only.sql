-- English-only highlight detail bodies (Hindi paragraphs removed).

UPDATE highlight_tags
SET body = $e$
This plant is tagged eco-friendly because it suits low-chemical care and greener potting habits. Choosing it supports a softer footprint while you still enjoy strong, healthy green at home.
$e$
WHERE id = '00000000-0000-4000-8000-000000000001'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant is pollinator-friendly: its flowers invite bees and butterflies for nectar. Growing it means colour for you and a small buffet for neighbourhood pollinators.
$e$
WHERE id = '00000000-0000-4000-8000-000000000002'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant is air purifying: broad leaves help catch dust and balance room humidity. People keep it indoors so the air around it feels cleaner and easier to breathe.
$e$
WHERE id = '00000000-0000-4000-8000-000000000003'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant brings oxygen and freshness to your corner. Photosynthesis keeps it lively by day—a natural lift for stale rooms.
$e$
WHERE id = '00000000-0000-4000-8000-000000000004'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant is home-friendly: compact habit and forgiving care make it slot into flats, rentals and balconies without needing a big garden.
$e$
WHERE id = '00000000-0000-4000-8000-000000000005'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant is chosen as vastu-positive green for the house—traditionally tied to calm entrances and light-filled corners. Pair it with good sunlight and airflow in your layout.
$e$
WHERE id = '00000000-0000-4000-8000-000000000006'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant carries forest-calm vibes: dense green foliage gives a woodland hush at home—ideal when you want nature's quiet tone on a shelf or railing.
$e$
WHERE id = '00000000-0000-4000-8000-000000000007'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant is water-wise: it rests well between drinks, so slips in watering sting less than thirsty tropicals. A simple soak-then-dry rhythm keeps it happy.
$e$
WHERE id = '00000000-0000-4000-8000-000000000008'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant is sun-loving—its colours and branching open up brightest in direct light. Reserve a sunny sill or railing for full effect.
$e$
WHERE id = '00000000-0000-4000-8000-000000000009'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant brings energising pops of colour—yellows or magentas that wake up patios and windowsills without extra decor.
$e$
WHERE id = '00000000-0000-4000-8000-00000000000a'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant is among customer favourites—it wins trust because it behaves predictably and stays lovable season after season.
$e$
WHERE id = '00000000-0000-4000-8000-00000000000b'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant supports wellness at home—the gentle chore of wiping leaves lifts mood and softens harsh screen-heavy days.
$e$
WHERE id = '00000000-0000-4000-8000-00000000000c'::uuid;

UPDATE highlight_tags
SET body = $e$
This product carries the recycling-wise note: empty packs and trays can go to local recycle streams—less plastic guilt while you garden.
$e$
WHERE id = '00000000-0000-4000-8000-00000000000d'::uuid;

UPDATE highlight_tags
SET body = $e$
This plant fits compost-loving growers—the trim you trim (when healthy) can feed soil cycles at home alongside safe kitchen scraps.
$e$
WHERE id = '00000000-0000-4000-8000-00000000000e'::uuid;

NOTIFY pgrst, 'reload schema';
