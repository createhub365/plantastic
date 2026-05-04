import 'package:flutter/material.dart';

import '../../models/shop_order.dart';
import '../../services/admin_orders_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_widgets.dart';

class AdminOrdersPanel extends StatefulWidget {
  const AdminOrdersPanel({super.key});

  @override
  State<AdminOrdersPanel> createState() => _AdminOrdersPanelState();
}

class _AdminOrdersPanelState extends State<AdminOrdersPanel>
    with AutomaticKeepAliveClientMixin {
  List<ShopOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _orders = await AdminOrdersService.fetchOrders();
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const AdminBusyView(message: 'Fetching orders…');
    }
    if (_error != null) {
      return AdminErrorView(message: _error!, onRetry: _load);
    }
    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            AdminEmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle:
                  'When customers check out, their orders appear here with full details.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          top: 12,
          left: 14,
          right: 14,
        ),
        itemCount: _orders.length,
        itemBuilder: (context, i) {
          final o = _orders[i];
          final dt = o.createdAt;
          final dateStr = dt != null
              ? '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2)}:${dt.minute.toString().padLeft(2)}'
              : '—';

          return Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.surfaceBorder.withValues(alpha: 0.6),
              ),
            ),
            child: ExpansionTile(
              initiallyExpanded: i == 0,
              collapsedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              leading: CircleAvatar(
                backgroundColor: AppTheme.mintGlow.withValues(alpha: 0.15),
                child: Icon(
                  Icons.currency_rupee_rounded,
                  size: 20,
                  color: AppTheme.mintGlow.withValues(alpha: 0.95),
                ),
              ),
              title: Text(
                '₹${o.total}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('$dateStr • ${o.customerName}'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line('Phone', o.phone),
                      _line(
                        'Address',
                        '${o.addressLine1}\n${o.city} ${o.postalCode}',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Items',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...o.rawItems.map(
                        (it) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• ${it['title']} — ${it['kit_label'] ?? it['kit']} × ${it['qty']} @ ₹${it['unitPrice']}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label:\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
