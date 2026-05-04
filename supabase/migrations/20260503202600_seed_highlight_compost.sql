-- Adds default "compost" highlight tag (Dart: SeedHighlightTags, highlight_icons compost).

INSERT INTO highlight_tags (id, title, label, icon_key, body, sort_order)
SELECT '00000000-0000-4000-8000-00000000000e'::uuid,
       'Compost-friendly growing',
       'Compost',
       'compost',
       $BODY$These picks work well with home composting loops: spent potting mix, safe green waste and non-diseased trimmings can feed your pile (follow local compost rules). Richer humus means happier roots next season.

इस टैग से हम घरेलू कम्पोस्ट साइकल को प्रोत्साहित करते हैं — सुखी टहनियाँ, खाद्य अवशेषों के सुरक्षित हिस्से और पुरानी मिट्टी (बीमार न हो) का इस्तेमाल करके अगली फसल के लिए नरम, जीवंत मिट्टी बनाइए।$BODY$::text,
       140
WHERE NOT EXISTS (
  SELECT 1 FROM highlight_tags ht
  WHERE ht.id = '00000000-0000-4000-8000-00000000000e'::uuid OR ht.icon_key = 'compost'
);

NOTIFY pgrst, 'reload schema';
