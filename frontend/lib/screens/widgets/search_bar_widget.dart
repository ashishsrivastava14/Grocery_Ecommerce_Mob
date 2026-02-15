import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final bool autofocus;
  final String hintText;

  const SearchBarWidget({
    super.key,
    this.onTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.autofocus = false,
    this.hintText = 'Search groceries, fruits, vegetables...',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          enabled: !readOnly,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.textLight,
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 50,
              minHeight: 24,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 36,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}
