import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 20, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfacePink,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.primary, width: 2.5),
                    ),
                    child: user?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    user?.fullName ?? 'Guest User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Orders section
                _SectionCard(
                  children: [
                    _MenuTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Orders',
                      subtitle: 'Track & manage orders',
                      onTap: () => context.push('/orders'),
                    ),
                    _MenuTile(
                      icon: Icons.favorite_outline,
                      title: 'Favorites',
                      subtitle: 'Products you love',
                      onTap: () {},
                    ),
                    _MenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Delivery Addresses',
                      subtitle: 'Manage your addresses',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Payment section
                _SectionCard(
                  children: [
                    _MenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      subtitle: 'Balance & transactions',
                      onTap: () {},
                      trailing: Text(
                        '\$0.00',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _MenuTile(
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      subtitle: 'Manage cards & UPI',
                      onTap: () {},
                    ),
                    _MenuTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Coupons',
                      subtitle: 'Available offers',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Settings section
                _SectionCard(
                  children: [
                    _MenuTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage preferences',
                      onTap: () {},
                    ),
                    _MenuTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'FAQ, contact us',
                      onTap: () {},
                    ),
                    _MenuTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'Terms, privacy, licenses',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Logout
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.shadow, blurRadius: 8),
                    ],
                  ),
                  child: ListTile(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref.read(authStateProvider.notifier).logout();
                                context.go('/login');
                              },
                              child: const Text('Logout',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.logout, color: AppColors.error, size: 20),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textLight),
                  ),
                ),

                const SizedBox(height: 24),

                // App version
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 68),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfacePink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textLight),
    );
  }
}
