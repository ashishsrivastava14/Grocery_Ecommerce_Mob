import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/product.dart';

class CategoryChip extends StatelessWidget {
  final ProductCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.iconUrl != null && category.iconUrl!.isNotEmpty) ...[
              Image.network(
                category.iconUrl!,
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => Icon(
                  _getCategoryIcon(category.name),
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                _getCategoryIcon(category.name),
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit') || lower.contains('vegetable')) {
      return Icons.eco;
    } else if (lower.contains('dairy') || lower.contains('milk')) {
      return Icons.water_drop;
    } else if (lower.contains('meat') || lower.contains('fish') || lower.contains('seafood')) {
      return Icons.set_meal;
    } else if (lower.contains('bakery') || lower.contains('bread')) {
      return Icons.bakery_dining;
    } else if (lower.contains('beverage') || lower.contains('drink') || lower.contains('juice')) {
      return Icons.local_cafe;
    } else if (lower.contains('snack') || lower.contains('chip')) {
      return Icons.fastfood;
    } else if (lower.contains('frozen')) {
      return Icons.ac_unit;
    } else if (lower.contains('organic') || lower.contains('health')) {
      return Icons.spa;
    } else if (lower.contains('spice') || lower.contains('condiment')) {
      return Icons.restaurant;
    } else {
      return Icons.category;
    }
  }
}
