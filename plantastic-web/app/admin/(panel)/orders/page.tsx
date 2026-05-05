import { AdminOrdersPanel } from "@/components/admin/admin-orders-panel";
import { parseShopOrderRow } from "@/lib/catalog/parse-shop-order";
import { createSupabaseServerClient } from "@/lib/supabase/server-client";
import { colors } from "@/lib/theme/colors";

export default async function AdminOrdersPage() {
  try {
    const supabase = await createSupabaseServerClient();
    const { data, error } = await supabase
      .from("orders")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) {
      return (
        <div>
          <h1 className="text-2xl font-semibold">Orders</h1>
          <p className="mt-2 text-sm text-red-600">{error.message}</p>
        </div>
      );
    }

    const rows = Array.isArray(data) ? data : [];
    const orders = rows.map((r) =>
      parseShopOrderRow(r as Record<string, unknown>),
    );

    return (
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Orders</h1>
        <p className="mt-1 text-sm" style={{ color: colors.textSecondary }}>
          Pending / shipped / delivered — matches Flutter fulfilment statuses.
        </p>
        <div className="mt-6">
          <AdminOrdersPanel orders={orders} />
        </div>
      </div>
    );
  } catch (e) {
    return (
      <div>
        <h1 className="text-2xl font-semibold">Orders</h1>
        <p className="mt-2 text-sm">{e instanceof Error ? e.message : "Failed to load."}</p>
      </div>
    );
  }
}
