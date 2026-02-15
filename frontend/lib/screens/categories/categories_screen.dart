import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../widgets/smart_image.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('All Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Failed to load categories'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(categoriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories available'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryCard(category: cat);
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ProductCategory category;

  const _CategoryCard({required this.category});

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                      ? SmartImage(
                          imageUrl: category.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: Center(
                            child: Icon(
                              _getCategoryIcon(category.name),
                              size: 48,
                              color: AppColors.primary.withAlpha(180),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            _getCategoryIcon(category.name),
                            size: 48,
                            color: AppColors.primary.withAlpha(180),
                          ),
                        ),
                ),
              ),
            ),
            // Label
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (category.description != null)
                      Text(
                        category.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
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
