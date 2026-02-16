import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final statusFilter = ref.watch(adminProductStatusFilterProvider);
    final lowStock = ref.watch(adminProductLowStockProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Product Management',
            subtitle: 'Monitor all products across vendors',
          ),
          const SizedBox(height: 20),
          // Toolbar
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminSearchBar(
                controller: _searchController,
                hint: 'Search products...',
                onChanged: (v) =>
                    ref.read(adminProductSearchProvider.notifier).state = v,
                onClear: () {
                  _searchController.clear();
                  ref.read(adminProductSearchProvider.notifier).state = '';
                },
              ),
              FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16,
                        color: lowStock ? Colors.white : AppColors.error),
                    const SizedBox(width: 4),
                    Text('Low Stock'),
                  ],
                ),
                selected: lowStock,
                onSelected: (v) {
                  ref.read(adminProductLowStockProvider.notifier).state = v;
                  ref.read(adminProductPageProvider.notifier).state = 1;
                },
                selectedColor: AppColors.error,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: lowStock ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: lowStock ? AppColors.error : Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminFilterChips(
            options: const ['active', 'draft', 'out_of_stock', 'discontinued'],
            selected: statusFilter,
            onSelected: (v) {
              ref.read(adminProductStatusFilterProvider.notifier).state = v;
              ref.read(adminProductPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 20),
          productsAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminProductsProvider)),
            data: (result) {
              final products =
                  List<Map<String, dynamic>>.from(result['data'] ?? []);
              final total = result['total'] ?? 0;
              final page = result['page'] ?? 1;
              final totalPages = result['total_pages'] ?? 1;

              if (products.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found');
              }

              return Column(
                children: [
                  AdminCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 64,
                        columnSpacing: 20,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        columns: const [
                          DataColumn(label: Text('PRODUCT')),
                          DataColumn(label: Text('VENDOR')),
                          DataColumn(label: Text('CATEGORY')),
                          DataColumn(label: Text('PRICE')),
                          DataColumn(label: Text('STOCK')),
                          DataColumn(label: Text('SOLD')),
                          DataColumn(label: Text('RATING')),
                          DataColumn(label: Text('STATUS')),
                        ],
                        rows: products.map((p) {
                          final stock = p['stock_quantity'] ?? 0;
                          final threshold = p['low_stock_threshold'] ?? 10;
                          final isLow = stock <= threshold &&
                              p['status'] == 'active';

                          return DataRow(cells: [
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: p['image_url'] != null
                                      ? Image.network(
                                          p['image_url'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _imagePlaceholder(),
                                        )
                                      : _imagePlaceholder(),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 160,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(p['name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      if (p['is_featured'] == true)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.starYellow
                                                .withAlpha(30),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text('Featured',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.starYellow,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            )),
                            DataCell(SizedBox(
                              width: 100,
                              child: Text(p['vendor_name'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            )),
                            DataCell(Text(p['category_name'] ?? 'N/A',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('₹${p['price'] ?? 0}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                if (p['compare_at_price'] != null &&
                                    p['compare_at_price'] > 0)
                                  Text('₹${p['compare_at_price']}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textLight,
                                          decoration:
                                              TextDecoration.lineThrough)),
                              ],
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLow)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(right: 4),
                                    child: Icon(
                                        Icons.warning_amber_rounded,
                                        size: 14,
                                        color: AppColors.error),
                                  ),
                                Text('$stock',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isLow
                                          ? AppColors.error
                                          : AppColors.textPrimary,
                                    )),
                              ],
                            )),
                            DataCell(Text('${p['total_sold'] ?? 0}',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14,
                                    color: AppColors.starYellow),
                                const SizedBox(width: 2),
                                Text(
                                    '${(p['avg_rating'] ?? 0).toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            )),
                            DataCell(AdminStatusBadge(
                                status: p['status'] ?? '')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 12),
                        child: Text('$total products total',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textLight)),
                      ),
                      AdminPagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onPageChanged: (p) => ref
                            .read(adminProductPageProvider.notifier)
                            .state = p,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey.shade100,
      child: const Icon(Icons.image, size: 18, color: Colors.grey),
    );
  }
}
