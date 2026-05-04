# Plantastic Supabase migrations

Ye SQL files **`public.products` columns** aur **`storage` bucket (`product-images`)** dono ko defined state mein rakhte hain taaki Flutter uploads / URLs stable rahein.

## Naye project / dubara kabhi mismatch na aaye — rule

1. **Schema sirf migration files se badlo** — Dashboard mein bucket/table randomly mat banao/delete karo jo SQL mein na ho (ya phir migration mein wo change add karo).
2. **`supabase/migrations/` ke applied files kabhi overwrite mat karo** — Flutter / Supabase diff tools hash mismatch aur drift dete hain. Naya change = **naya `YYYYMMDDHHMMSS_name.sql`** file.
3. **Production par deploy**: files ko ** naam ke chronological order** mein ek hi direction mein chalao (`db push` ya SQL Editor paste).

## Apply karne ka tareeka

### Option A — Supabase CLI (recommended)

```bash
cd plantastic
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

CLI latest rakho (`npm i -g supabase` / official install docs).

### Option B — Dashboard → SQL Editor

`supabase/migrations/` ke andar **sorted by filename**, har file ka **poora** content run karo (pehli se aakhri tak).

`.env` / app mein **`SUPABASE_PRODUCT_IMAGES_BUCKET`** set karke bucket name mismatch avoid karo; default naam `product-images` hai (`ProductImageUploadService`).

## `DatabaseSchemaMismatch` / 503 Storage

- Sab migrations apply karke **`NOTIFY pgrst`** walé steps run ho chuke hon (files ke end par hai).
- **Supabase Dashboard → Project Settings**: brief **pause resume** kabhi transient platform sync fix karta hai.
- Errors **persist** karti hon to ye often **hosted platform** Ki taraf reconciliation issue hota hai → **Dashboard → Support** ticket with project ref + approximate time.

Ye README + versioned migrations workflow hi long-term **permanent** discipline hai; cloud-side bugs ke liye support channel zaroori rehta hai.
