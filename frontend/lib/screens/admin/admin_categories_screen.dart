import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_common.dart';
import 'widgets/admin_status_badge.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: AdminPageHeader(
                  title: 'Category Management',
                  subtitle: 'Organize products into categories and subcategories',
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCategoryDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Category'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          categoriesAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminCategoriesProvider)),
            data: (categories) {
              if (categories.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.category_outlined, title: 'No categories found');
              }

              // Build hierarchical structure
              final roots = categories
                  .where((c) => c['parent_id'] == null)
                  .toList()
                ..sort((a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0));

              return AdminCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: roots.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _CategoryTile(
                      category: roots[index],
                      allCategories: categories,
                      level: 0,
                      onEdit: (cat) => _showCategoryDialog(context, category: cat),
                      onDelete: _deleteCategory,
                      onToggle: _toggleCategory,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {Map<String, dynamic>? category}) {
    final service = ref.read(adminServiceProvider);
    final isEdit = category != null;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: category?['name'] ?? '');
    final slugCtrl = TextEditingController(text: category?['slug'] ?? '');
    final descCtrl = TextEditingController(text: category?['description'] ?? '');
    final iconUrlCtrl = TextEditingController(text: category?['icon_url'] ?? '');
    final imageUrlCtrl = TextEditingController(text: category?['image_url'] ?? '');
    final sortOrderCtrl = TextEditingController(
        text: (category?['sort_order'] ?? 0).toString());
    String? parentId = category?['parent_id'];
    bool isActive = category?['is_active'] ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'Create Category'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Name*',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 2) ? 'Min 2 characters' : null,
                      onChanged: (v) {
                        if (!isEdit && slugCtrl.text.isEmpty) {
                          slugCtrl.text = v
                              .toLowerCase()
                              .replaceAll(RegExp(r'[^\w\s-]'), '')
                              .replaceAll(' ', '-');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: slugCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL Slug*',
                        prefixIcon: Icon(Icons.link),
                        helperText: 'e.g., fresh-vegetables',
                      ),
                      validator: (v) => (v == null || v.length < 2)
                          ? 'Min 2 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: service.getCategories(),
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? [];
                        final filteredCats = isEdit
                            ? categories
                                .where((c) => c['id'] != category!['id'])
                                .toList()
                            : categories;

                        return DropdownButtonFormField<String>(
                          value: parentId,
                          decoration: const InputDecoration(
                            labelText: 'Parent Category',
                            prefixIcon: Icon(Icons.account_tree),
                            helperText: 'Leave empty for main category',
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('None (Main Category)')),
                            ...filteredCats.map((c) => DropdownMenuItem(
                                  value: c['id'],
                                  child: Text(c['name']),
                                )),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => parentId = v),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: iconUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Icon URL',
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: imageUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Banner Image URL',
                        prefixIcon: Icon(Icons.photo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: sortOrderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sort Order',
                        prefixIcon: Icon(Icons.sort),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Show in app'),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'slug': slugCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'icon_url': iconUrlCtrl.text.trim(),
                          'image_url': imageUrlCtrl.text.trim(),
                          'parent_id': parentId,
                          'sort_order': int.tryParse(sortOrderCtrl.text) ?? 0,
                          'is_active': isActive,
                        };

                        if (isEdit) {
                          await service.updateCategory(category!['id'], data);
                        } else {
                          await service.createCategory(data);
                        }

                        ref.invalidate(adminCategoriesProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isEdit
                                ? 'Category updated!'
                                : 'Category created!'),
                            backgroundColor: AppColors.success,
                          ));
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.error,
                          ));
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final products = category['products_count'] ?? 0;
    String? moveToId;

    if (products > 0) {
      final allCategories = await ref.read(adminServiceProvider).getCategories();
      final otherCategories = allCategories
          .where((c) => c['id'] != category['id'])
          .toList();

      if (!mounted) return;

      moveToId = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Category Has Products'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'This category has $products products. Move them to another category before deleting.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Move products to'),
                items: otherCategories
                    .map((c) => DropdownMenuItem<String>(
                          value: c['id'],
                          child: Text(c['name']),
                        ))
                    .toList(),
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        ),
      );

      if (moveToId == null) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${category['name']}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Delete')),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    try {
      final service = ref.read(adminServiceProvider);
      await service.deleteCategory(category['id'], moveProductsTo: moveToId);
      ref.invalidate(adminCategoriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Category deleted'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _toggleCategory(Map<String, dynamic> category) async {
    try {
      final service = ref.read(adminServiceProvider);
      await service.updateCategory(category['id'], {
        'is_active': !(category['is_active'] ?? false),
      });
      ref.invalidate(adminCategoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final Map<String, dynamic> category;
  final List<Map<String, dynamic>> allCategories;
  final int level;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>) onToggle;

  const _CategoryTile({
    required this.category,
    required this.allCategories,
    required this.level,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final children = allCategories
        .where((c) => c['parent_id'] == category['id'])
        .toList()
      ..sort((a, b) => (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0));

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + (level * 40.0), right: 16),
          leading: category['icon_url'] != null
              ? CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(25),
                  backgroundImage: NetworkImage(category['icon_url']),
                )
              : CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(25),
                  child: Icon(Icons.category, color: AppColors.primary, size: 20),
                ),
          title: Row(
            children: [
              Text(category['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (level == 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Main',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          subtitle: Text(category['slug'],
              style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminStatusBadge(
                  status: category['is_active'] == true ? 'active' : 'inactive'),
              const SizedBox(width: 8),
              Switch(
                value: category['is_active'] == true,
                onChanged: (_) => onToggle(category),
                activeColor: AppColors.success,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit',
                onPressed: () => onEdit(category),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                tooltip: 'Delete',
                onPressed: () => onDelete(category),
              ),
            ],
          ),
        ),
        if (children.isNotEmpty)
          ...children.map((child) => _CategoryTile(
                category: child,
                allCategories: allCategories,
                level: level + 1,
                onEdit: onEdit,
                onDelete: onDelete,
                onToggle: onToggle,
              )),
      ],
    );
  }
}
