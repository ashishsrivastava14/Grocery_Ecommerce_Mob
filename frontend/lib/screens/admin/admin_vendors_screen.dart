import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminVendorsScreen extends ConsumerStatefulWidget {
  const AdminVendorsScreen({super.key});

  @override
  ConsumerState<AdminVendorsScreen> createState() => _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends ConsumerState<AdminVendorsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(adminVendorsProvider);
    final statusFilter = ref.watch(adminVendorStatusFilterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Vendor Management',
            subtitle: 'Manage vendor applications & accounts',
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
                hint: 'Search vendors by name or city...',
                onChanged: (v) =>
                    ref.read(adminVendorSearchProvider.notifier).state = v,
                onClear: () {
                  _searchController.clear();
                  ref.read(adminVendorSearchProvider.notifier).state = '';
                },
              ),
              AdminFilterChips(
                options: const [
                  'pending', 'under_review', 'approved', 'rejected', 'suspended'
                ],
                selected: statusFilter,
                onSelected: (v) {
                  ref.read(adminVendorStatusFilterProvider.notifier).state = v;
                  ref.read(adminVendorPageProvider.notifier).state = 1;
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Table
          vendorsAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminVendorsProvider)),
            data: (result) {
              final vendors = List<Map<String, dynamic>>.from(result['data'] ?? []);
              final total = result['total'] ?? 0;
              final page = result['page'] ?? 1;
              final totalPages = result['total_pages'] ?? 1;

              if (vendors.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.store_outlined,
                    title: 'No vendors found',
                    subtitle: 'Try adjusting your filters');
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
                        columnSpacing: 24,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        columns: const [
                          DataColumn(label: Text('STORE NAME')),
                          DataColumn(label: Text('CITY')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('RATING')),
                          DataColumn(label: Text('ORDERS')),
                          DataColumn(label: Text('COMMISSION')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: vendors.map((v) {
                          return DataRow(cells: [
                            DataCell(
                              InkWell(
                                onTap: () => context
                                    .go('/admin/vendors/${v['id']}'),
                                child: Text(v['store_name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.primary)),
                              ),
                            ),
                            DataCell(Text(v['city'] ?? 'N/A',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(AdminStatusBadge(
                                status: v['status'] ?? '')),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: AppColors.starYellow),
                                const SizedBox(width: 2),
                                Text(
                                    '${(v['rating'] ?? 0).toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            )),
                            DataCell(Text('${v['total_orders'] ?? 0}',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text(
                                '${((v['commission_rate'] ?? 0) * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(_VendorActions(
                              vendorId: v['id'],
                              status: v['status'] ?? '',
                              onUpdate: () =>
                                  ref.invalidate(adminVendorsProvider),
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
                        child: Text('$total vendors total',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textLight)),
                      ),
                      AdminPagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onPageChanged: (p) =>
                            ref.read(adminVendorPageProvider.notifier).state = p,
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
}

class _VendorActions extends StatelessWidget {
  final String vendorId;
  final String status;
  final VoidCallback onUpdate;

  const _VendorActions({
    required this.vendorId,
    required this.status,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'pending' || status == 'under_review') ...[
          _ActionBtn(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            tooltip: 'Approve',
            onTap: () => _updateStatus(context, 'approved'),
          ),
          const SizedBox(width: 4),
          _ActionBtn(
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            tooltip: 'Reject',
            onTap: () => _updateStatus(context, 'rejected'),
          ),
        ],
        if (status == 'approved')
          _ActionBtn(
            icon: Icons.block_rounded,
            color: AppColors.warning,
            tooltip: 'Suspend',
            onTap: () => _updateStatus(context, 'suspended'),
          ),
        if (status == 'suspended')
          _ActionBtn(
            icon: Icons.restore_rounded,
            color: AppColors.success,
            tooltip: 'Reactivate',
            onTap: () => _updateStatus(context, 'approved'),
          ),
        const SizedBox(width: 4),
        _ActionBtn(
          icon: Icons.visibility_rounded,
          color: AppColors.info,
          tooltip: 'View Details',
          onTap: () => context.go('/admin/vendors/$vendorId'),
        ),
      ],
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await AdminService().updateVendor(vendorId, {'status': newStatus});
      onUpdate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vendor ${newStatus == 'approved' ? 'approved' : newStatus}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

