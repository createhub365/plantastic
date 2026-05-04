import 'package:flutter/material.dart';

import '../../models/shop_order.dart';
import '../../services/admin_orders_service.dart';
import '../../theme/admin_shell.dart';
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

  static const List<String> _statusChoices = [
    'pending',
    'shipped',
    'delivered',
  ];

  String _normalizeStatus(String raw) {
    final x = raw.trim().toLowerCase();
    if (_statusChoices.contains(x)) return x;
    return 'pending';
  }

  String _statusLabel(String code) {
    return switch (code) {
      'shipped' => 'Shipped',
      'delivered' => 'Delivered',
      _ => 'Pending',
    };
  }

  String _shortOrderId(String id) {
    final t = id.trim();
    if (t.length <= 10) return t;
    return '${t.substring(0, 8)}…';
  }

  Future<void> _setStatus(int index, String next) async {
    final o = _orders[index];
    final canon = _normalizeStatus(next);
    final prev = o.status;
    setState(() => _orders[index] = o.copyWith(status: canon));
    try {
      await AdminOrdersService.updateOrderStatus(id: o.id, status: canon);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as ${_statusLabel(canon)}')),
      );
    } catch (e) {
      setState(() => _orders[index] = o.copyWith(status: prev));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status not saved — ensure `orders.status` exists and RLS allows updates: $e',
          ),
        ),
      );
    }
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
          bottom: MediaQuery.paddingOf(context).bottom + 28,
          top: 4,
          left: 0,
          right: 0,
        ),
        itemCount: _orders.length,
        itemBuilder: (context, i) {
          final o = _orders[i];
          final dt = o.createdAt;
          final dateStr = dt != null
              ? '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2)}:${dt.minute.toString().padLeft(2)}'
              : '—';
          final tt = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;

          final statusCanon = _normalizeStatus(o.status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminShell.cardRadiusSm),
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: i == 0,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                collapsedBackgroundColor: Colors.white,
                backgroundColor: AdminShell.dashboardCanvas.withValues(
                  alpha: 0.55,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                  ),
                ),
                title: Text(
                  'Order #${_shortOrderId(o.id)}',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '₹${o.total} • ${_statusLabel(statusCanon)}\n'
                    '$dateStr • ${o.customerName}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(
                      height: 1.42,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: statusCanon,
                        borderRadius: BorderRadius.circular(12),
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                        items: [
                          for (final code in _statusChoices)
                            DropdownMenuItem(
                              value: code,
                              child: Text(_statusLabel(code)),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) _setStatus(i, v);
                        },
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          height: 26,
                          color: scheme.outline.withValues(alpha: 0.35),
                        ),
                        _line('Phone', o.phone),
                        _line(
                          'Address',
                          '${o.addressLine1}\n${o.city} ${o.postalCode}',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, top: 4),
                          child: Text(
                            'Items',
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface.withValues(alpha: 0.93),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...o.rawItems.map(
                          (it) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '• ${it['title']} — ${it['kit_label'] ?? it['kit']} × ${it['qty']} @ ₹${it['unitPrice']}',
                              style: tt.bodyMedium?.copyWith(
                                height: 1.45,
                                color: scheme.onSurface.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
