import 'package:flutter/material.dart';

import '../../theme/admin_shell.dart';
import '../../theme/app_theme.dart';

/// Primary navigation rail for the admin dashboard (desktop + drawer).
class AdminDashboardSidebar extends StatelessWidget {
  const AdminDashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  static const _entries = <({IconData icon, String label})>[
    (icon: Icons.inventory_2_outlined, label: 'Products'),
    (icon: Icons.shopping_cart_outlined, label: 'Orders'),
    (icon: Icons.checklist_rtl_outlined, label: 'Kit items'),
    (icon: Icons.layers_outlined, label: 'Kit presets'),
    (icon: Icons.auto_awesome_outlined, label: 'Highlights'),
    (icon: Icons.panorama_wide_angle_select_outlined, label: 'Home banner'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const railBg = Colors.white;
    const subtleBorder = Color(0xFFE2E8F0);

    return Material(
      color: railBg,
      child: SizedBox(
        width: AdminShell.sidebarWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.eco_rounded, color: scheme.primary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Plantastic Admin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Catalogue & fulfilment',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Divider(height: 1, thickness: 1, color: subtleBorder),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                itemCount: _entries.length,
                itemBuilder: (context, i) {
                  final e = _entries[i];
                  final selected = i == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _SidebarNavTile(
                      icon: e.icon,
                      label: e.label,
                      selected: selected,
                      onTap: () => onSelect(i),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, thickness: 1, color: subtleBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: TextButton.icon(
                onPressed: onSignOut,
                icon: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
                label: Text(
                  'Sign out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatefulWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeBg = AppTheme.forestBright.withValues(
      alpha: widget.selected ? 0.14 : 0,
    );
    final hoverBg = scheme.primary.withValues(alpha: _hover ? 0.06 : 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          hoverColor: scheme.primary.withValues(alpha: 0.07),
          splashColor: scheme.primary.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: AdminShell.motionMedium,
            curve: AdminShell.motionCurve,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Color.alphaBlend(hoverBg, activeBg),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.selected
                    ? AppTheme.forestBright.withValues(alpha: 0.45)
                    : const Color(0xFFE2E8F0).withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 22,
                  color: widget.selected
                      ? AppTheme.forestBright
                      : const Color(0xFF4A5568),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: widget.selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      letterSpacing: 0.1,
                      color: widget.selected
                          ? const Color(0xFF1A202C)
                          : const Color(0xFF4A5568),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
