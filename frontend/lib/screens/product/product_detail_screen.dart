import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Failed to load product',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(productDetailProvider(widget.productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (product) => _buildContent(context, product),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Product product) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Product Image
            SliverToBoxAdapter(
              child: _ProductImageSection(
                product: product,
                selectedIndex: _selectedImageIndex,
                onImageSelected: (i) =>
                    setState(() => _selectedImageIndex = i),
                onBack: () => context.pop(),
              ),
            ),

            // Product Info
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Favorite
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.unitType,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border_rounded),
                          color: AppColors.textLight,
                          iconSize: 28,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < product.avgRating.floor()
                                ? Icons.star_rounded
                                : index < product.avgRating
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded,
                            color: AppColors.starYellow,
                            size: 20,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${product.avgRating.toStringAsFixed(1)} (${product.totalReviews} reviews)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Price and Quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '/${product.unitType}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (product.isOnSale) ...[
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '\$${product.compareAtPrice?.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textLight,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Quantity selector
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _QuantityButton(
                                icon: Icons.remove,
                                onTap: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add,
                                isPrimary: true,
                                onTap: () {
                                  setState(() => _quantity++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Delivery info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              color: AppColors.success, size: 24),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Free Delivery',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Estimated 25-30 min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nutritional info
                    if (product.nutritionalInfo != null &&
                        product.nutritionalInfo!.isNotEmpty) ...[
                      const Text(
                        'Nutritional Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: product.nutritionalInfo!.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Spacer for bottom button
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Add to Cart button
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).addItem(product, _quantity);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to cart'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'Add to Cart  •  \$${(product.price * _quantity).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductImageSection extends StatelessWidget {
  final Product product;
  final int selectedIndex;
  final ValueChanged<int> onImageSelected;
  final VoidCallback onBack;

  const _ProductImageSection({
    required this.product,
    required this.selectedIndex,
    required this.onImageSelected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      color: AppColors.surfacePink,
      child: Stack(
        children: [
          // Main image
          Center(
            child: product.primaryImageUrl.isNotEmpty
                ? Image.network(
                    product.primaryImageUrl,
                    fit: BoxFit.contain,
                    height: 220,
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    size: 120,
                    color: AppColors.textLight,
                  ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),

          // Share button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.share_outlined, size: 18),
            ),
          ),

          // Image thumbnails
          if (product.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(product.images.length, (index) {
                  return GestureDetector(
                    onTap: () => onImageSelected(index),
                    child: Container(
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedIndex == index
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          product.images[index].imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image,
                            size: 24,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}
