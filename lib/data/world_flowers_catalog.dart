/// Common flower names from many regions (English labels) with short shop-style blurbs.
class WorldFlower {
  const WorldFlower(this.name, this.snippet);

  final String name;
  final String snippet;
}

List<WorldFlower> _parseWorldFlowers(String raw) {
  final out = <WorldFlower>[];
  for (final line in raw.split('\n')) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final i = t.indexOf('|');
    if (i < 0) continue;
    final name = t.substring(0, i).trim();
    final sn = t.substring(i + 1).trim();
    if (name.isEmpty) continue;
    out.add(WorldFlower(name, sn));
  }
  out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}

// Data rows are intentionally long (flower catalogue).
const String _kWorldFlowersRaw = """
African Daisy|Colourful daisy blooms; heat-tolerant and great for sunny beds.
Ageratum|Soft mounds of flossy blooms; edging and containers.
Alstroemeria|Long-lasting Peruvian lily spikes; prized as cut flowers.
Amaryllis|Bold indoor winter bulbs with huge trumpet blooms.
Anemone|Delicate poppy relatives; woodland or spring pots.
Aquilegia Columbine|Elegant nectar-rich spurs; pollinator favourite.
Arabian Jasmine|Highly fragrant jasmine for warm climates and evening scent.
Asian Bleeding Heart|Arched sprays of heart-shaped flowers; shady charm.
Australian Tea Tree|Fine-leathy foliage and small flowers (Melaleuca‑type look).
Baby's Breath|Clouds of tiny white blooms; bouquet filler favourite.
Balloon Flower|Puffed buds that pop open into bell stars.
Bee Balm|Mint family tubes loved by hummingbirds and bees.
Begonia|Tuberous or wax types; shaded patio colour.
Bellflower Campanula|Bell-shaped spikes; cottage borders.
Bird of Paradise|Tropical crane flowers; striking architecture.
Blanket Flower Gaillardia|Rust-red and gold discs; prairie tough.
Bleeding Heart|Classic arching hearts; spring woodland.
Bottlebrush|Australian brushes of red bristles along stems.
Bougainvillea|Paper bracts in hot colours; climbers for sun walls.
Busy Lizzie Impatiens|Shade-loving nonstop colour in pots.
Buttercup Wild|Bright yellow cups for meadows — check local species suitability.
California Poppy|Ethereal silky orange bowls; drought adapted.
Calla Lily|Elegant spathe blooms; modern borders or cuts.
Camellia|Glossy evergreen with rose-like winter flowers.
Candytuft|Low white foam for rock gardens and paths.
Canna Lily|Bold leaves and torch blooms; tropical drama.
Carnation|Frilled clove-scented classics for cuts and beds.
Chamomile|Daisy herbs for teas; gentle lawn alternative in patches.
Cherry Blossom Ornamental|Spring pink clouds on small flowering trees.
Chrysanthemum|Autumn mums in endless garden forms.
Clematis|Twining stars in purple, pink, and white.
Cockscomb Celosia|Velvet crests or plumes; long-lasting colour.
Columbine|Nodding spurred flowers; self-sows in cool climates.
Coneflower Echinacea|Pink daisies with raised cones; prairie staple.
Coreopsis|Tickseed yellows and reds; long bloom season.
Cosmos|Feathery foliage and starry daisies on tall wands.
Crocus|First spring bulbs often pushing through snow.
Crown Imperial Fritillaria|Regal orange bells with a musky note.
Cyclamen|Cool-season heart-leaf gems for shade pots.
Daffodil|Trumpet and cup narcissus — spring cheer.
Dahlia|Dinnerplate to pompon tubers; cut-flower stars.
Daisy Shasta|Classic white rays with yellow eyes; easy borders.
Daylily Hemerocallis|One-day trumpets in endless colours; tough.
Delphinium|Tall spires of true blues; back of border.
Dianthus Pinks|Spicy clove pinks and garden carnations.
Drumstick Allium|Round purple globes on slim stems; modern accents.
Dusty Miller|Silvery leaves that set off bright petals.
English Bluebell|Woodland bells (use true native forms where required).
English Lavender|Fragrant grey mounds and bee highways.
Evening Primrose|Sunset-opening cups; moth gardens.
Fan Flower Scaevola|Trailing lavender fans; heat-proof baskets.
Flamingo Flower Anthurium|Waxy spathes; bright houseplant or humid shade.
Flax Flower Linum|Sky-blue cups on airy stems.
Forget-me-not|Sky-blue clouds; self-seeding spring romance.
Foxglove Digitalis|Spotted towers for hummingbirds — note toxicity to pets.
Freesia|Strongly scented funnel clusters; spring bulbs or annuals.
French Marigold|Compact oranges and golds; useful companion edging.
Gardenia|Waxy white perfume; acid soil and humidity.
Geranium Cranesbill|Hardy perennial mounds distinct from tender pelargoniums.
Gerbera Daisy|Bold flat faces for patio pots and bouquets.
Gladiolus|Sword leaves and summer spikes — classic cuts.
Globe Amaranth Gomphrena|Bubblegum spheres; everlasting dried colour.
Goldenrod|Late gold wands wrongly blamed for hay fever.
Grevillea|Spider or toothbrush flowers; Australian hummingbird magnet.
Gypsophila|See Baby's Breath — cloudy white mass.
Heliotrope|Vanilla-purple clusters; fragrant container thriller.
Hellebore Christmas Rose|Winter-facing bowl flowers in subtle tones.
Hibiscus|Tropical trumpets; standards and shrubs for sun.
Hollyhock|Tall cottage spires along fences.
Honesty Lunaria|Silvery moon seedpods after purple blooms.
Hyacinth|Dense fragrant spring spikes; pots and perfume.
Hydrangea|Bigleaf lacecaps and mopheads; soil can shift hues.
Ice Plant|Jewelled succulent daisies; dry sunny groundcover.
Indian Paintbrush|Semi-parasitic wild beauty — specialised native use.
Ixora|Tropical shrub clusters; warm-climate hedging.
Jacob's Ladder Polemonium|Ferny leaves and soft blue ladders.
Japanese Anemone|Late summer dancing singles; part shade grace.
Japanese Cherry|Ornamental Prunus for spring corridors of pink.
Japanese Iris|Elegant wetland irises over sword leaves.
Jerusalem Artichoke Sunchoke|Tall sunflower-relative tubers plus yellow blooms.
Jonquil|Pale fragrant narcissus group; pots and pathways.
King Protea|Crown‑like cones; signature South African cut flower.
Lady's Slipper Orchid|Shoe-shaped beauties — specialised growing.
Larkspur Consolida|Cornfield blues and pinks — cool-season annual spikes.
Laurel Bay|Sweet bay for cooking and evergreen structure.
Lavender Cotton Santolina|Grey mounds with yellow buttons — Mediterranean flair.
Licorice Plant Helichrysum|Trailing silver curls; foliage contrast.
Lilac Common|Perfumed purple panicles — spring perfume walls.
Lily Asiatic|Bold spots and clean colours; easy summer bulbs.
Lily Calla|See Calla Lily — sculptural elegance.
Lily Day|See Daylily — landscape workhorse.
Lily Martagon|Turk's cap recurved petals; woodland regal.
Lily of the Valley|Bell racemes and sweet scent — spreading groundcover.
Lobelia|Electric blues or trailing whites; edges and spillers.
Loosestrife Lythrum|Spiked colour — choose sterile cultivars where invasive.
Love-in-a-Mist Nigella|Lacy foliage and dreamy blue stars.
Lupine|Pea-family spires in cool colours; nitrogen fixing.
Magnolia|Saucer blooms on bare branches — early spring grandeur.
Mallow Hollyhock Cousin|Open funnel flowers on tall stems.
Marigold African|Large pompons; tall background colour.
Marigold French|See French Marigold — compact edging.
Mexican Petunia Ruellia|Heat-proof lavender trumpets; check regional invasiveness.
Mexican Sunflower Tithonia|Fiery orange discs for butterflies.
Monkshood Aconitum|Hooded blues — highly toxic; handle with care.
Moonflower Ipomoea|Huge white night-opening trumpets; trellis romance.
Morning Glory|Twining funnels — choose non-invasive types locally.
Nasturtium|Peppery edible rounds; poor-soil champion.
Nemesia|Fragrant little snapdragon faces; cool-season baskets.
Nerine|Autumn amaryllis relatives; delicate spider blooms.
Orchid Cattleya|Showy epiphytes for bright humidity.
Orchid Cymbidium|Arching sprays for cool bright porches.
Orchid Dendrobium|Canes of clustered blooms; warm conservatories.
Orchid Moth Phalaenopsis|Long-lasting indoor classics.
Oriental Lily|Huge fragrance — plant away from low windows on breezes.
Oriental Poppy Papaver|Silky crepe bowls on hairy foliage — true perennial poppies.
Pansy|Whiskered faces for cool weather pots.
Passionflower|Intricate purple-white geometry; host for fritillaries.
Peace Lily Spathiphyllum|White flags in low light; forgiving houseplant.
Peony Herbaceous|Ant-filled buds open to lush bowls — long-lived.
Periwinkle Vinca|Trailing blues — use only where not invasive.
Petunia|Trumpet cascades; sun baskets and beds.
Phlox Garden|Fragrant summer panicles; mildew-resistant breeds help.
Pink Dianthus|See Dianthus — cottage edging.
Plumeria Frangipani|Leis and lei fragrance; pots brought indoors cold zones.
Polar Geranium|Pelargonium types for windowsills — vivid clusters.
Polar Primrose Primula|Rosettes of spring cups; moist shade pots.
Polyanthus Primrose|Strung clusters in candy colours early season.
Poppy Californian|See California Poppy.
Poppy Cornfield Papaver|Papery annual cups scattered in meadows.
Pot Marigold Calendula|Edible petals and cool-season citrus tones.
Powder Puff Calliandra|Pink spherical fireworks; tropical accents.
Primrose Cowslip|Traditional yellow clusters nodding above rosettes.
Protea Pin Cushion Leucospermum|Pin-cushion heads; dry Mediterranean conditions.
Purple Coneflower|See Coneflower.
Queen Anne's Lace|Lacy umbels — caution: resembles toxic lookalikes in the wild.
Rain Lily Zephyranthes|Surprise blooms after summer showers.
Ranunculus Persian|Layered rose-like corms; cool spring cuts.
Rhododendron Azalea|Spring trumpets on acid woodland slopes.
Rock Rose Cistus|Paper flowers on sun-baked slopes; Mediterranean.
Rose English|See Rose — bush and climbing forms for arbours.
Rose Hybrid Tea|Cut-flower classic high-centred blooms on long stems.
Rose Rugosa|Salt-tough hedges with hips and scent.
Sage Salvia|Spikes from scarlet to blue; hummingbird highway.
Scabious Pincushion|Buttons on wiry stems; butterfly favourite.
Scarlet Sage|See Sage — tropical red annual types.
Scented Geranium|Fuzzy leaves of rose, lemon, mint — brush and release.
Shasta Daisy|See Daisy Shasta.
Silene Catchfly|Sticky stems and bright stars; rock garden charm.
Snapdragon Antirrhinum|Dragon-mouth spikes; cool weather favourite.
Snowdrop Galanthus|First white drops in late winter chill.
Stock Matthiola|Spicy evening fragrance in dense spikes.
Sunflower Helianthus|Iconic seed heads; dwarf to giant forms.
Sweet Alyssum|Honey-scented white or purple carpets.
Sweet Pea Lathyrus|Old-fashioned fragrance on winged stems.
Tickseed|See Coreopsis.
Tiger Lily Lancifolium|Black-spotted orange recurved petals.
Toad Lily Tricyrtis|Orchid-like freckles in moist shade autumn.
Tradescantia Spiderwort|Jewel-tone three-petaled blooms; woodland edges.
Tulip Darwin Hybrid|Classic big cups returning in cold winters.
Verbena|Tight clusters trailing or upright; butterfly landing pads.
Virgina Creeper Vine|Five-finger blazing autumn reds — woody vine.
Wallflower Cheiranthus|Spicy clusters on woody bases; spring bridges.
Water Lily Hardy|Floating pads with rising cups — pond centerpiece.
Wild Bergamot Monarda|Bee balm relatives — see Bee Balm.
Wisteria|Dripping violet or white cascades — strong structure needed.
Yellow Alyssum Basket|Basket‑of‑gold spring foam on walls.
Yellow Cosmos Sulphureus|Sunny orange-yellow annual cosmos relative.
Yellow Flag Iris Pseudacoris|Water-margin yellow flags — check wetland rules.
Zinnia|Bright summer daisies; butterfly landing pads — deadhead for waves.
Angelonia Summer Snapdragon|Heat-proof snap lookalikes — nonstop spikes.
Cuphea Firecracker|Tiny cigars hummingbirds dart for.
Cuphea Mickey Mouse|Eared orange tubes; quirky patio curiosity.
Cuphea Violet|Small purple cigars; edging colour.
Cuphea Candy Corn|Yellow-orange tubes along stems.
Lantana|Clusters shifting colour heat to heat — tender shrub or annual.
Mandevilla|Tropical trumpet vines — trellis jewels.
Oleander|Toxic but tough flowering hedge for warm climates.
Plumbago|Pale china-blue sticky shrubs or climbers — butterfly blue.
Russelia Firecracker Bush|Fine stems of red tubular fireworks.
Ruellia Dwarf|Compact petunia lookalikes; check invasive notes regionally.
Thunbergia Black-eyed Susan Vine|Orange discs with dark eyes on twining stems.
Angel Trumpet Brugmansia|Huge dangling trumpets — night fragrance; toxic.
Blue Sage Salvia azurea|Tall airy blues for prairie mixes.
Bolivian Sunset Gloxinia Relative|tubular reds for shade patios.
Boltonia Daisy|Late white clouds — aster family resilience.
Brazilian Verbena Verbena bonariensis|Wiry wands bobbing lavender — pollinator fave.
Chocolate Cosmos|Rare dark-maroon cosmos scent — treat as tender tuber where cold.
Columbine Alpine|Tiny spurred gems for gritty troughs.
Coral Bells Heuchera|Foliage first; airy wands of bells second.
Cup Plant Silphium|Towering prairie perennial with nectar reservoirs.
Dalmatian Bellflower|Suitably robust blue bells for walls.
Dalmatian Cranesbill|See Geranium — dalmatium forms exist.
Dicentra Burning Hearts|Bronzy fern leaves and red dangling hearts.
Dutch Crocus|Egg-yolk mixes with purple veining — lawns allowed some places.
Egret Flower Pecteilis|Porch orchid‑like beauties — niche bulbs.
Farewell-to-spring Clarkia|Tissue-pink cups closing the spring show.
Farewell Summer Sedum|'Autumn Joy' tone — succulent stars for pollinators later.
Foamflower Tiarella|Foamy ivory plumes; shade tapestry.
Garden Phlox|Panicled fragrance — mildew-resistant clones help.
Glory Bush Tibouchina|Purple puffballs on woody stems — tropics/subtropics.
Godetia|Satiny cups in pastel sheets — spring sow in cool climates.
Golden Groundsel Ligularia|Dramatic foliage and yellow daisy towers — moist shade feet.
Honeywort Cerinthe|Sea-green bracts dripping blue kisses — avant-garde edging.
Jacobinia Justicia|Tropical shrimp flowers for humid shade.
Kentucky Wisteria|Less aggressive alternative where noted — still plan supports.
Lady Banks Rose|Nearly thornless spring clouds of tiny roses on arches.
Lavender Butterfly Bush Buddleja|Sterile hybrids available where seeding is a worry.
Louisiana Iris|Swamp iris elegance in hot humid summers.
Mountain Laurel Kalmia|Rhodora relatives with intricate spring cups.
Nepeta Catmint|Grey haze adored by bees; repeat blooming trim tricks.
Ninebark Physocarpus|'Summer Wine' shrubs with pollinator ivory buttons.
Oleander Dwarf|Mini hedges — still toxic sap; choose wisely.
Ozark Sundrops Oenothera|Evening genus relatives for sunny fronts.
Pale Purple Coneflower|Refined prairie coneflower for lean soils.
Pearl Bush Exochorda|Fluttering bridal white fountains in spring.
Perennial Sunflower Helianthus|Clumping giants without annual resow fuss.
Pink Muhly Grass|Pink cotton-candy clouds as grass inflorescences spike.
Purple Heart Tradescantia|Trailing magenta stems — frost tender spills.
Purpletop Vervain|see Verbena loosely — airy Verbena relatives used in prairie mixes.
Red Hot Poker Kniphofia|Torch lily spikes hummingbirds patrol.
Ribbon Grass Phalaris|Variegated leaves — sterile clumps preferred.
Rock Jasmine Androsace|Tiny cushion alpine stars for troughs.
Saffron Crocus|Autumn blooming spice crocus — true culinary stigma harvest.
Savannah Iris|Louisiana Iris garden shorthand — wetland grace.
Smoke Bush Cotinus|Purple puffs — shrub architecture with drifting seeds.
Southern Magnolia|Evergreen waxy blooms with rusty undersides — large‑leaf grandeur.
Spider Flower Cleome|Tall scented spidery spheres — pollinator scaffolding.
Spider Lily Hymenocallis|Tropical bog white fireworks on arching stalks.
Stokes Aster|Cornflower-esque blue-purple daisies for sunny edges.
Sweet William Dianthus barbatus|Flat clusters scented for cottage edging.
Twinspur Diascia|Tiny snapdragon slippers trailing cool baskets.
Twinflower Linnaea|Delicate woodland pairs naming Linnaeus quietly.
Whitlow Grass Draba|Tiny yellow alpine sparks for gritty screes.
""";

final List<WorldFlower> kWorldFlowers = _parseWorldFlowers(_kWorldFlowersRaw);

String? snippetForFlowerNameExact(String typed) {
  final key = typed.trim().toLowerCase();
  if (key.isEmpty) return null;
  for (final w in kWorldFlowers) {
    if (w.name.toLowerCase() == key) return w.snippet;
  }
  return null;
}

Iterable<WorldFlower> filterWorldFlowers(String query, {int maxResults = 12}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const Iterable<WorldFlower>.empty();
  var n = 0;
  return kWorldFlowers.where((w) {
    if (n >= maxResults) return false;
    final hit = w.name.toLowerCase().contains(q);
    if (hit) n++;
    return hit;
  });
}
