import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;
    return Scaffold(
      appBar: isWide ? null : _buildAppBar(context),
      drawer: isWide ? null : Drawer(child: _AdminSidebar()),
      body: Row(
        children: [
          if (isWide) _AdminSidebar(),
          Expanded(
            child: Column(
              children: [
                if (isWide) _AdminTopBar(),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F6FA),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    return AppBar(
      title: Text(_getTitleForPath(loc)),
      backgroundColor: const Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Back to App',
          onPressed: () => context.go('/home'),
        ),
      ],
    );
  }

  String _getTitleForPath(String path) {
    if (path.contains('/vendors')) return 'Vendors';
    if (path.contains('/orders')) return 'Orders';
    if (path.contains('/customers')) return 'Customers';
    if (path.contains('/categories')) return 'Categories';
    if (path.contains('/products')) return 'Products';
    if (path.contains('/transactions')) return 'Transactions';
    if (path.contains('/payouts')) return 'Payouts';
    if (path.contains('/coupons')) return 'Coupons';
    if (path.contains('/reviews')) return 'Reviews';
    if (path.contains('/settings')) return 'Settings';
    return 'Dashboard';
  }
}

class _AdminTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Breadcrumb
          Row(
            children: [
              InkWell(
                onTap: () => context.go('/admin'),
                child: Text('Admin',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              if (loc != '/admin') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.grey.shade400),
                ),
                Text(
                  _breadcrumbLabel(loc),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          const Spacer(),
          // Refresh
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: Colors.grey.shade500, size: 20),
            tooltip: 'Refresh',
            onPressed: () {
              // Trigger rebuild by navigating to same route
              context.go(loc);
            },
          ),
          const SizedBox(width: 4),
          // Back to storefront
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: const Text('Storefront'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _breadcrumbLabel(String path) {
    final segment = path.replaceAll('/admin/', '').replaceAll('/admin', '');
    if (segment.isEmpty) return 'Dashboard';
    return segment
        .split('/')
        .first
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}

class _AdminSidebar extends StatelessWidget {
  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/admin') return 0;
    if (location.startsWith('/admin/vendors')) return 1;
    if (location.startsWith('/admin/orders')) return 2;
    if (location.startsWith('/admin/customers')) return 3;
    if (location.startsWith('/admin/categories')) return 4;
    if (location.startsWith('/admin/products')) return 5;
    if (location.startsWith('/admin/transactions')) return 6;
    if (location.startsWith('/admin/payouts')) return 7;
    if (location.startsWith('/admin/coupons')) return 8;
    if (location.startsWith('/admin/reviews')) return 9;
    if (location.startsWith('/admin/settings')) return 10;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    return Container(
      width: 260,
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFF8F5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GroceryAdmin',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('Management Panel',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Section: MAIN
          _SectionLabel(label: 'MAIN'),
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () => _navigate(context, '/admin'),
          ),
          _NavItem(
            icon: Icons.store_rounded,
            label: 'Vendors',
            isSelected: selectedIndex == 1,
            onTap: () => _navigate(context, '/admin/vendors'),
          ),
          _NavItem(
            icon: Icons.shopping_bag_rounded,
            label: 'Orders',
            isSelected: selectedIndex == 2,
            onTap: () => _navigate(context, '/admin/orders'),
          ),
          _NavItem(
            icon: Icons.people_rounded,
            label: 'Customers',
            isSelected: selectedIndex == 3,
            onTap: () => _navigate(context, '/admin/customers'),
          ),
          _NavItem(
            icon: Icons.category_rounded,
            label: 'Categories',
            isSelected: selectedIndex == 4,
            onTap: () => _navigate(context, '/admin/categories'),
          ),
          _NavItem(
            icon: Icons.inventory_2_rounded,
            label: 'Products',
            isSelected: selectedIndex == 5,
            onTap: () => _navigate(context, '/admin/products'),
          ),
          const SizedBox(height: 8),
          // Section: FINANCE
          _SectionLabel(label: 'FINANCE'),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
            isSelected: selectedIndex == 6,
            onTap: () => _navigate(context, '/admin/transactions'),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Payouts',
            isSelected: selectedIndex == 7,
            onTap: () => _navigate(context, '/admin/payouts'),
          ),
          const SizedBox(height: 8),
          // Section: ENGAGEMENT
          _SectionLabel(label: 'ENGAGEMENT'),
          _NavItem(
            icon: Icons.local_offer_rounded,
            label: 'Coupons',
            isSelected: selectedIndex == 8,
            onTap: () => _navigate(context, '/admin/coupons'),
          ),
          _NavItem(
            icon: Icons.reviews_rounded,
            label: 'Reviews',
            isSelected: selectedIndex == 9,
            onTap: () => _navigate(context, '/admin/reviews'),
          ),
          const Spacer(),
          // Settings
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isSelected: selectedIndex == 10,
            onTap: () => _navigate(context, '/admin/settings'),
          ),
          // Back to app
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Storefront'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white12),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String path) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    context.go(path);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 20, 8),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white30,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2)),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: isSelected
            ? AppColors.primary.withAlpha(40)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withAlpha(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(icon,
                    color: isSelected ? AppColors.primary : Colors.white38,
                    size: 20),
                const SizedBox(width: 14),
                Text(label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white60,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    )),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
