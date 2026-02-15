import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../widgets/product_card.dart';
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
            // ─── Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          Text(
                            'FreshMart Grocery - QuickPrepAI',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
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

            // ─── Search bar ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SearchBarWidget(
                  onTap: () => context.push('/search'),
                ),
              ),
            ),

            // ─── Promo Banner Carousel ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  height: 170,
                  child: featuredProducts.when(
                    data: (products) {
                      final bannerProducts = products.take(3).toList();
                      if (bannerProducts.isEmpty) return const SizedBox();
                      return PageView.builder(
                        controller: PageController(viewportFraction: 0.9),
                        itemCount: bannerProducts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _PromoBanner(
                              product: bannerProducts[index],
                              colorIndex: index,
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ),
            ),

            // ─── "Shop by Category" section header + horizontal scroll ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: SectionHeader(
                  title: 'Shop by Category',
                  actionText: 'View All',
                  onActionTap: () => context.push('/categories'),
                ),
              ),
            ),

            // Category grid (2 rows, scrollable horizontally)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  height: 220,
                  child: categories.when(
                    data: (cats) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: (cats.length / 2).ceil(),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, colIndex) {
                        final topIndex = colIndex * 2;
                        final bottomIndex = topIndex + 1;
                        return Column(
                          children: [
                            if (topIndex < cats.length)
                              _CategoryTile(category: cats[topIndex]),
                            const SizedBox(height: 12),
                            if (bottomIndex < cats.length)
                              _CategoryTile(category: cats[bottomIndex])
                            else
                              const SizedBox(height: 100),
                          ],
                        );
                      },
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (_, __) => const Center(
                      child: Text('Failed to load categories'),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Featured Products ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SectionHeader(
                  title: 'Featured Deals',
                  actionText: 'View All',
                  onActionTap: () => context.push('/products?title=Featured'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: featuredProducts.when(
                  data: (products) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) => SizedBox(
                      width: 165,
                      child: ProductCard(product: products[index]),
                    ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),

            // ─── Popular Items grid ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SectionHeader(
                  title: 'Popular Items',
                  actionText: 'View All',
                  onActionTap: () => context.push('/products?title=Popular'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              sliver: popularProducts.when(
                data: (products) => SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}

// ─── Promo Banner ───
class _PromoBanner extends StatelessWidget {
  final Product product;
  final int colorIndex;

  const _PromoBanner({required this.product, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [const Color(0xFFFF9A76), const Color(0xFFFFD4C4)],
      [const Color(0xFF85E89D), const Color(0xFFC8F7C5)],
      [const Color(0xFF82B1FF), const Color(0xFFBBDEFB)],
    ];
    final colors = gradients[colorIndex % gradients.length];

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Text content
            Positioned(
              left: 20,
              top: 20,
              bottom: 20,
              width: MediaQuery.of(context).size.width * 0.38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (product.isOnSale)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/${product.unitType}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Product image
            Positioned(
              right: 10,
              top: 10,
              bottom: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product.primaryImageUrl.isNotEmpty
                    ? Image.network(
                        product.primaryImageUrl,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 140,
                          height: 140,
                          color: Colors.white24,
                          child: const Icon(Icons.image,
                              size: 48, color: Colors.white70),
                        ),
                      )
                    : Container(
                        width: 140,
                        height: 140,
                        color: Colors.white24,
                        child: const Icon(Icons.shopping_bag,
                            size: 48, color: Colors.white70),
                      ),
              ),
            ),
            // Shop now button
            Positioned(
              left: 20,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Shop Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Tile ───
class _CategoryTile extends StatelessWidget {
  final ProductCategory category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final bgColors = [
      const Color(0xFFFFE0D6),
      const Color(0xFFFFF3D0),
      const Color(0xFFE8F5E9),
      const Color(0xFFE8EAF6),
      const Color(0xFFFCE4EC),
      const Color(0xFFE0F7FA),
      const Color(0xFFF3E5F5),
      const Color(0xFFFFF8E1),
    ];
    final bgColor = bgColors[category.name.length % bgColors.length];

    return GestureDetector(
      onTap: () => context.push(
        '/products?categoryId=${category.id}&title=${category.name}',
      ),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category image or icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        category.iconUrl!,
                        width: 30,
                        height: 30,
                        errorBuilder: (_, __, ___) => Icon(
                          _getCategoryIcon(category.name),
                          size: 26,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(category.name),
                      size: 26,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit')) return Icons.apple;
    if (lower.contains('vegetable')) return Icons.eco;
    if (lower.contains('dairy') || lower.contains('egg')) return Icons.water_drop;
    if (lower.contains('bakery') || lower.contains('bread')) return Icons.bakery_dining;
    if (lower.contains('meat') || lower.contains('poultry')) return Icons.set_meal;
    if (lower.contains('seafood') || lower.contains('fish')) return Icons.phishing;
    if (lower.contains('beverage') || lower.contains('drink')) return Icons.local_cafe;
    if (lower.contains('snack') || lower.contains('chip')) return Icons.fastfood;
    if (lower.contains('frozen')) return Icons.ac_unit;
    if (lower.contains('rice') || lower.contains('grain')) return Icons.grain;
    if (lower.contains('spice') || lower.contains('herb')) return Icons.spa;
    if (lower.contains('oil') || lower.contains('ghee')) return Icons.water;
    if (lower.contains('pasta') || lower.contains('noodle')) return Icons.ramen_dining;
    if (lower.contains('sauce') || lower.contains('condiment')) return Icons.local_dining;
    if (lower.contains('organic') || lower.contains('health')) return Icons.favorite;
    if (lower.contains('baby')) return Icons.child_care;
    if (lower.contains('personal')) return Icons.spa;
    if (lower.contains('household') || lower.contains('cleaning')) return Icons.cleaning_services;
    if (lower.contains('chocolate') || lower.contains('sweet')) return Icons.cake;
    if (lower.contains('pet')) return Icons.pets;
    return Icons.category;
  }
}
