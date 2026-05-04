-- Default highlight catalogue (icons match highlight_icons.dart / SeedHighlightTags in app).
-- Skips rows if that id OR icon_key already exists.

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000001'::uuid,
       'Eco-friendly growing',
       'Eco-friendly',
       'eco',
       $BODY$These picks lean toward peat-free mixes, biodegradable pots where possible and minimal chemical inputs so you can grow with a lighter footprint. Pair with rainwater or greywater-conscious watering where local rules allow.

यह टैग उन उत्पादों पर लगता है जिन्हें हम कम खाद-रासायनिक, जीवाणु-अनुकूल मिट्टी और पुनर्वापर योग्य सामग्री की ओर रखना चाहते हैं — घर या बालकनी बगीचे के लिए हरियाली का जिम्मेदार चुनाव।$BODY$::text,
       10
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000001'::uuid OR ht.icon_key = 'eco'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000002'::uuid,
       'Pollinator-friendly blooms',
       'Pollinator friendly',
       'local_florist',
       $BODY$Flowers that bees, butterflies and hoverflies love — open, nectar-rich forms and mixed colours to keep your patch buzzing from spring to late summer.

ये फूल परागण करने वाले कीड़ों के लिए अच्छे होते हैं; बालकनी या बॉर्डर पर लगाकर आप स्थानिक परागणकों को सपोर्ट कर सकते हैं।$BODY$::text,
       20
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000002'::uuid OR ht.icon_key = 'local_florist'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000003'::uuid,
       'Indoor air helpers',
       'Air purifying',
       'air',
       $BODY$Many foliage plants help buffer dust and moderate humidity indoors. Place near bright indirect light, wipe leaves monthly, and avoid over-watering for best effect.

कुछ पौधे इनडोर हवा में नमी और धूल संतुलन में मदद कर सकते हैं — रोशनी और पानी संतुलित रखें।$BODY$::text,
       30
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000003'::uuid OR ht.icon_key = 'air'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000004'::uuid,
       'Freshness & green mood',
       'Oxygen & freshness',
       'oxygen',
       $BODY$Plants brighten rooms and moods; through photosynthesis they refresh the vibe of any corner. Rotate pots for even growth and breathable potting mixes.

हरियाली कमरे की ताजगी और मन का माहौल बेहतर करती है; हल्की मिट्टी और धूप से स्वस्थ पौधा।$BODY$::text,
       40
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000004'::uuid OR ht.icon_key = 'oxygen'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000005'::uuid,
       'Home & balcony ready',
       'Home friendly',
       'home',
       $BODY$Compact varieties, patio pots and repeatable sowing windows — ideal for renters and urban balconies without a full yard.

छोटे स्पेस, किराये या बालकनी के लिए उपयुक्त — कम जगह में भी रंगीन फसल या जड़ी-फूल।$BODY$::text,
       50
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000005'::uuid OR ht.icon_key = 'home'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000006'::uuid,
       'Vastu-positive greens',
       'Vastu',
       'vastu',
       $BODY$Chosen for uplifting green forms and placements that traditionally pair well with east/north-facing light and clutter-free entrances — always combine with good light and airflow in your layout.

ग्रीनरी को साफ, हवादार स्थान और अच्छी रोशनी से जोड़ें; स्थानीय वास्तु सलाह के साथ मिलकर आजमाएं।$BODY$::text,
       60
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000006'::uuid OR ht.icon_key = 'vastu'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000007'::uuid,
       'Forest-calming foliage',
       'Forest calm',
       'forest',
       $BODY$Deep greens and structured leaves bring a quiet "mini-forest" feel to desks and corners; great with moss-top dressings and grouped pots.

गहरे हरे पत्ते राहत देने वाला माहौल देते हैं; समूह में रखने पर बेहतर नमी संतुलन।$BODY$::text,
       70
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000007'::uuid OR ht.icon_key = 'forest'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000008'::uuid,
       'Moderate watering',
       'Water wise',
       'water_drop',
       $BODY$Prefer soak-then-dry cycles or drought-tolerant seedlings where noted; mulching cuts evaporation on hot balconies.

अधिकांश बीज या पौधों में पानी तभी जब ऊपरी मिट्टी सूखने लगे; गर्मियों में मल्चिंग मददगार।$BODY$::text,
       80
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000008'::uuid OR ht.icon_key = 'water_drop'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-000000000009'::uuid,
       'Sun-loving varieties',
       'Sun lover',
       'wb_sunny',
       $BODY$Give ≥6 hours of direct sun for best colour and branching; fade plastic covers gradually so seedlings don't scorch.

इन्हें दिन में कई घंटे धूप चाहिए; धीरे-धीरे पॉलीहाउस से बाहर निकालकर हार्डन करें।$BODY$::text,
       90
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-000000000009'::uuid OR ht.icon_key = 'wb_sunny'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-00000000000a'::uuid,
       'Energising colour pops',
       'Energy',
       'energy',
       $BODY$Warm yellows and magentas perk up patios; contrast with charcoal pots for a vivid pop.

जीवंत रंग ऊर्जा भरते हैं — गमले और पौधों का कॉन्ट्रास्ट सजावट का आधार बनिए।$BODY$::text,
       100
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-00000000000a'::uuid OR ht.icon_key = 'energy'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-00000000000b'::uuid,
       'Customer favourites',
       'Favourite picks',
       'favorite',
       $BODY$Backed by steady nursery demand — reliable germination habits and forgiving care for starters.

बार-बार पसंद आने वाले विकल्प; शुरुआती बागवानों के लिए अक्सर सहज होते हैं।$BODY$::text,
       110
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-00000000000b'::uuid OR ht.icon_key = 'favorite'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-00000000000c'::uuid,
       'Wellness & mindful care',
       'Wellness',
       'health',
       $BODY$Routine pruning, grooming and propagation can settle the mind — these kits pair well with journaling or balcony tea breaks.

थोड़ी देखभाल दिनचर्या में ध्यान जोड़ती है — पत्ते साफ रखना और निराई तनाव कम कर सकता है।$BODY$::text,
       120
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-00000000000c'::uuid OR ht.icon_key = 'health'
);

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-00000000000d'::uuid,
       'Less waste footprint',
       'Recycling wise',
       'recycling',
       $BODY$Recycle plastic labels and trays locally; compost spent media where facilities exist and reuse sturdy pots.

खाली पैकेट व ट्रे की स्थानीय रिसाइक्लिंग; मजबूत गमले दोबारा इस्तेमाल कीजिए और मिट्टी योग्य हो तो खाद में डालिए।$BODY$::text,
       130
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-00000000000d'::uuid OR ht.icon_key = 'recycling'
);

NOTIFY pgrst, 'reload schema';
