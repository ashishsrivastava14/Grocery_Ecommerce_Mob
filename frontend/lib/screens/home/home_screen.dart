import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/search_bar_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final featuredProducts = ref.watch(featuredProductsProvider);
    final popularProducts = ref.watch(popularProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with greeting and notification
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfacePink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          Text(
                            'Welcome Back!',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SearchBarWidget(
                  onTap: () => context.push('/search'),
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  height: 42,
                  child: categories.when(
                    data: (cats) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cats.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return CategoryChip(
                            category: ProductCategory(
                              id: 'all',
                              name: 'All',
                              slug: 'all',
                            ),
                            isSelected: true,
                            onTap: () {},
                          );
                        }
                        final cat = cats[index - 1];
                        return CategoryChip(
                          category: cat,
                          isSelected: false,
                          onTap: () => context.push(
                            '/products?categoryId=${cat.id}&title=${cat.name}',
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ),
            ),

            // Featured banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _FeaturedBanner(),
              ),
            ),

            // Popular Items
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: SectionHeader(
                  title: 'Popular Items',
                  actionText: 'View All',
                  onActionTap: () => context.push('/products?title=Popular'),
                ),
              ),
            ),

            // Popular items grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              sliver: popularProducts.when(
                data: (products) => SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= products.length) return null;
                      return ProductCard(product: products[index]);
                    },
                    childCount: products.length,
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: Center(child: Text('Failed to load products')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD4C4),
            Color(0xFFFFE8DE),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Content
          Positioned(
            left: 20,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heart icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border,
                      color: AppColors.textPrimary, size: 20),
                ),
                const SizedBox(height: 40),
                Text(
                  'Fresh Strawberry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$25',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      '/kg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Placeholder for product image
          Positioned(
            right: 16,
            top: 16,
            bottom: 16,
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.surfacePink.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 60, color: AppColors.primary),
              ),
            ),
          ),
          // Add button
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
