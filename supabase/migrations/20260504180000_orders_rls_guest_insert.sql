-- Shopper checkout uses the anon Supabase role (guest). Admin reads orders signed in + plantastic_staff.
-- INSERT ... RETURNING requires SELECT privileges + matching RLS; we keep guest SELECT denied and the app inserts without `.select()`.

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orders_anon_insert" ON public.orders;
CREATE POLICY "orders_anon_insert"
    ON public.orders
    AS PERMISSIVE
    FOR INSERT
    TO anon
    WITH CHECK (true);

DROP POLICY IF EXISTS "orders_authenticated_insert" ON public.orders;
CREATE POLICY "orders_authenticated_insert"
    ON public.orders
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "orders_staff_select" ON public.orders;
CREATE POLICY "orders_staff_select"
    ON public.orders
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (EXISTS (
        SELECT 1
        FROM public.plantastic_staff s
        WHERE s.user_id = auth.uid()
            AND COALESCE(s.is_admin, FALSE) IS TRUE));

DROP POLICY IF EXISTS "orders_staff_update" ON public.orders;
CREATE POLICY "orders_staff_update"
    ON public.orders
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (EXISTS (
        SELECT 1
        FROM public.plantastic_staff s
        WHERE s.user_id = auth.uid()
            AND COALESCE(s.is_admin, FALSE) IS TRUE));

DROP POLICY IF EXISTS "orders_staff_delete" ON public.orders;
CREATE POLICY "orders_staff_delete"
    ON public.orders
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (EXISTS (
        SELECT 1
        FROM public.plantastic_staff s
        WHERE s.user_id = auth.uid()
            AND COALESCE(s.is_admin, FALSE) IS TRUE));

NOTIFY pgrst, 'reload schema';
