import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final statusFilter = ref.watch(adminOrderStatusFilterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Order Management',
            subtitle: 'Monitor and manage all orders',
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
                hint: 'Search by order number...',
                onChanged: (v) =>
                    ref.read(adminOrderSearchProvider.notifier).state = v,
                onClear: () {
                  _searchController.clear();
                  ref.read(adminOrderSearchProvider.notifier).state = '';
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminFilterChips(
            options: const [
              'pending',
              'confirmed',
              'preparing',
              'ready_for_pickup',
              'out_for_delivery',
              'delivered',
              'cancelled',
            ],
            selected: statusFilter,
            onSelected: (v) {
              ref.read(adminOrderStatusFilterProvider.notifier).state = v;
              ref.read(adminOrderPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 20),
          // Table
          ordersAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminOrdersProvider)),
            data: (result) {
              final orders =
                  List<Map<String, dynamic>>.from(result['data'] ?? []);
              final total = result['total'] ?? 0;
              final page = result['page'] ?? 1;
              final totalPages = result['total_pages'] ?? 1;

              if (orders.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No orders found');
              }

              return Column(
                children: [
                  AdminCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 60,
                        columnSpacing: 20,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        columns: const [
                          DataColumn(label: Text('ORDER #')),
                          DataColumn(label: Text('CUSTOMER')),
                          DataColumn(label: Text('VENDOR')),
                          DataColumn(label: Text('ITEMS')),
                          DataColumn(label: Text('AMOUNT')),
                          DataColumn(label: Text('PAYMENT')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: orders.map((o) {
                          return DataRow(cells: [
                            DataCell(InkWell(
                              onTap: () =>
                                  context.go('/admin/orders/${o['id']}'),
                              child: Text(o['order_number'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.primary)),
                            )),
                            DataCell(Text(o['customer_name'] ?? 'N/A',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(SizedBox(
                              width: 120,
                              child: Text(o['vendor_name'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            )),
                            DataCell(Text('${o['items_count'] ?? 0}',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text('₹${o['total_amount'] ?? 0}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))),
                            DataCell(AdminStatusBadge(
                                status: o['payment_status'] ?? '')),
                            DataCell(AdminStatusBadge(
                                status: o['status'] ?? '')),
                            DataCell(Text(
                                _formatDate(o['created_at']),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight))),
                            DataCell(IconButton(
                              icon: const Icon(Icons.visibility_rounded,
                                  size: 18, color: AppColors.info),
                              onPressed: () =>
                                  context.go('/admin/orders/${o['id']}'),
                              tooltip: 'View Details',
                            )),
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
                        child: Text('$total orders total',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textLight)),
                      ),
                      AdminPagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onPageChanged: (p) => ref
                            .read(adminOrderPageProvider.notifier)
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

  String _formatDate(dynamic dt) {
    if (dt == null) return '';
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(dt.toString()));
    } catch (_) {
      return dt.toString().substring(0, 10);
    }
  }
}
