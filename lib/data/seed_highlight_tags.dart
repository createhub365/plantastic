import '../models/highlight_tag.dart';

/// Default highlight catalogue (Synced with Supabase seed migrations).
/// Offline / no-Supabase: used as catalogue; online uses DB rows when present.
abstract final class SeedHighlightTags {
  static const List<
    (
      String id,
      String title,
      String label,
      String iconKey,
      String body,
      int order,
    )
  >
  defs = [
    (
      '00000000-0000-4000-8000-000000000001',
      'Eco-friendly growing',
      'Eco-friendly',
      'eco',
      'This plant carries the eco-friendly highlight because it suits a gentler grow routine: '
          'you can lean on mild organic feeding, skip heavy chemical sprays, and reuse sturdy '
          'pots while it still thrives. It works well with peat-light or renewable potting mixes '
          'and mindful watering—so you enjoy lush green at home with a lighter everyday footprint.',
      10,
    ),
    (
      '00000000-0000-4000-8000-000000000002',
      'Pollinator-friendly blooms',
      'Pollinator friendly',
      'local_florist',
      'This plant is pollinator-friendly: its flowers invite bees and butterflies for nectar. '
          'Growing it means colour for you and a small buffet for neighbourhood pollinators.',
      20,
    ),
    (
      '00000000-0000-4000-8000-000000000003',
      'Indoor air helpers',
      'Air purifying',
      'air',
      'This plant is air purifying: broad leaves help catch dust and balance room humidity. '
          'People keep it indoors so the air around it feels cleaner and easier to breathe.',
      30,
    ),
    (
      '00000000-0000-4000-8000-000000000004',
      'Freshness & green mood',
      'Oxygen & freshness',
      'oxygen',
      'This plant brings oxygen and freshness to your corner. Photosynthesis keeps it lively '
          'by day—a natural lift for stale rooms.',
      40,
    ),
    (
      '00000000-0000-4000-8000-000000000005',
      'Home & balcony ready',
      'Home friendly',
      'home',
      'This plant is home-friendly: compact habit and forgiving care make it slot into flats, '
          'rentals and balconies without needing a big garden.',
      50,
    ),
    (
      '00000000-0000-4000-8000-000000000006',
      'Vastu-positive greens',
      'Vastu',
      'vastu',
      'This plant is chosen as vastu-positive green for the house—traditionally tied to calm '
          'entrances and light-filled corners. Pair it with good sunlight and airflow in your '
          'layout.',
      60,
    ),
    (
      '00000000-0000-4000-8000-000000000007',
      'Forest-calming foliage',
      'Forest calm',
      'forest',
      'This plant carries forest-calm vibes: dense green foliage gives a woodland hush at '
          'home—ideal when you want nature\'s quiet tone on a shelf or railing.',
      70,
    ),
    (
      '00000000-0000-4000-8000-000000000008',
      'Moderate watering',
      'Water wise',
      'water_drop',
      'This plant is water-wise: it rests well between drinks, so slips in watering sting less '
          'than thirsty tropicals. A simple soak-then-dry rhythm keeps it happy.',
      80,
    ),
    (
      '00000000-0000-4000-8000-000000000009',
      'Sun-loving varieties',
      'Sun lover',
      'wb_sunny',
      'This plant is sun-loving—its colours and branching open up brightest in direct light. '
          'Reserve a sunny sill or railing for full effect.',
      90,
    ),
    (
      '00000000-0000-4000-8000-00000000000a',
      'Energising colour pops',
      'Energy',
      'energy',
      'This plant brings energising pops of colour—yellows or magentas that wake up patios and '
          'windowsills without extra decor.',
      100,
    ),
    (
      '00000000-0000-4000-8000-00000000000b',
      'Customer favourites',
      'Favourite picks',
      'favorite',
      'This plant is among customer favourites—it wins trust because it behaves predictably '
          'and stays lovable season after season.',
      110,
    ),
    (
      '00000000-0000-4000-8000-00000000000c',
      'Wellness & mindful care',
      'Wellness',
      'health',
      'This plant supports wellness at home—the gentle chore of wiping leaves lifts mood and '
          'softens harsh screen-heavy days.',
      120,
    ),
    (
      '00000000-0000-4000-8000-00000000000d',
      'Less waste footprint',
      'Recycling wise',
      'recycling',
      'This product carries the recycling-wise note: empty packs and trays can go to local '
          'recycle streams—less plastic guilt while you garden.',
      130,
    ),
    (
      '00000000-0000-4000-8000-00000000000e',
      'Compost-friendly growing',
      'Compost',
      'compost',
      'This plant fits compost-loving growers—the trim you trim (when healthy) can feed soil '
          'cycles at home alongside safe kitchen scraps.',
      140,
    ),
  ];

  static List<HighlightTag> catalog() => [
    for (final (id, title, label, iconKey, body, order) in defs)
      HighlightTag(
        id: id,
        title: title,
        label: label,
        iconKey: iconKey,
        body: body,
        sortOrder: order,
      ),
  ];
}
