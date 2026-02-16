import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_common.dart';

class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() =>
      _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(adminCustomersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Customer Management',
            subtitle: 'View and manage customer accounts',
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
                hint: 'Search by name or email...',
                onChanged: (v) =>
                    ref.read(adminCustomerSearchProvider.notifier).state = v,
                onClear: () {
                  _searchController.clear();
                  ref.read(adminCustomerSearchProvider.notifier).state = '';
                },
              ),
              AdminFilterChips(
                options: const ['active', 'inactive'],
                selected: _getActiveFilter(ref),
                onSelected: (v) {
                  final notifier =
                      ref.read(adminCustomerActiveFilterProvider.notifier);
                  if (v == 'active') {
                    notifier.state = true;
                  } else if (v == 'inactive') {
                    notifier.state = false;
                  } else {
                    notifier.state = null;
                  }
                  ref.read(adminCustomerPageProvider.notifier).state = 1;
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Table
          customersAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminCustomersProvider)),
            data: (result) {
              final customers =
                  List<Map<String, dynamic>>.from(result['data'] ?? []);
              final total = result['total'] ?? 0;
              final page = result['page'] ?? 1;
              final totalPages = result['total_pages'] ?? 1;

              if (customers.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.people_outlined,
                    title: 'No customers found');
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
                        columnSpacing: 24,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        columns: const [
                          DataColumn(label: Text('CUSTOMER')),
                          DataColumn(label: Text('EMAIL')),
                          DataColumn(label: Text('PHONE')),
                          DataColumn(label: Text('ORDERS')),
                          DataColumn(label: Text('TOTAL SPENT')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('JOINED')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: customers.map((c) {
                          final isActive = c['is_active'] == true;
                          return DataRow(cells: [
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      AppColors.primary.withAlpha(20),
                                  child: Text(
                                    (c['full_name'] ?? 'U')
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(c['full_name'] ?? 'N/A',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            )),
                            DataCell(Text(c['email'] ?? '',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text(c['phone'] ?? 'N/A',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text('${c['order_count'] ?? 0}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))),
                            DataCell(Text(
                                '₹${(c['total_spent'] ?? 0).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.success.withAlpha(20)
                                    : AppColors.error.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )),
                            DataCell(Text(_formatDate(c['created_at']),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight))),
                            DataCell(
                              Switch(
                                value: isActive,
                                activeColor: AppColors.success,
                                onChanged: (_) =>
                                    _toggleActive(c['id'], ref),
                              ),
                            ),
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
                        child: Text('$total customers total',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textLight)),
                      ),
                      AdminPagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onPageChanged: (p) => ref
                            .read(adminCustomerPageProvider.notifier)
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

  String? _getActiveFilter(WidgetRef ref) {
    final v = ref.watch(adminCustomerActiveFilterProvider);
    if (v == true) return 'active';
    if (v == false) return 'inactive';
    return null;
  }

  Future<void> _toggleActive(String? userId, WidgetRef ref) async {
    if (userId == null) return;
    try {
      await AdminService().toggleCustomerActive(userId);
      ref.invalidate(adminCustomersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return '';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dt.toString()));
    } catch (_) {
      return dt.toString().substring(0, 10);
    }
  }
}
