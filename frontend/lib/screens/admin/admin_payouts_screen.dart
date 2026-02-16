import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminPayoutsScreen extends ConsumerWidget {
  const AdminPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(adminPayoutsProvider);
    final statusFilter = ref.watch(adminPayoutStatusFilterProvider);
    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Vendor Payouts',
            subtitle: 'Track and manage vendor payout settlements',
          ),
          const SizedBox(height: 20),
          AdminFilterChips(
            options: const ['pending', 'processing', 'paid', 'failed'],
            selected: statusFilter,
            onSelected: (v) {
              ref.read(adminPayoutStatusFilterProvider.notifier).state = v;
              ref.read(adminPayoutPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 20),
          payoutsAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminPayoutsProvider)),
            data: (result) {
              final payouts =
                  List<Map<String, dynamic>>.from(result['data'] ?? []);
              final total = result['total'] ?? 0;
              final page = result['page'] ?? 1;
              final totalPages = result['total_pages'] ?? 1;

              if (payouts.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No payouts found');
              }

              return Column(
                children: [
                  AdminCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 56,
                        columnSpacing: 24,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        columns: const [
                          DataColumn(label: Text('PAYOUT ID')),
                          DataColumn(label: Text('VENDOR')),
                          DataColumn(label: Text('GROSS')),
                          DataColumn(label: Text('COMMISSION')),
                          DataColumn(label: Text('NET AMOUNT')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('DATE')),
                        ],
                        rows: payouts.map((p) {
                          return DataRow(cells: [
                            DataCell(Text(
                                '#${p['id']?.toString().padLeft(5, '0') ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))),
                            DataCell(SizedBox(
                              width: 120,
                              child: Text(p['vendor_name'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            )),
                            DataCell(Text(
                                currencyFmt.format(p['amount'] ?? 0),
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text(
                                currencyFmt.format(
                                    p['commission_deducted'] ?? 0),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary))),
                            DataCell(Text(
                                currencyFmt.format(p['net_amount'] ?? 0),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13))),
                            DataCell(AdminStatusBadge(
                                status: p['status'] ?? '')),
                            DataCell(Text(
                                _formatDate(p['created_at']),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight))),
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
                        child: Text('$total payouts',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textLight)),
                      ),
                      AdminPagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onPageChanged: (p) => ref
                            .read(adminPayoutPageProvider.notifier)
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

  String _formatDate(String? iso) {
    if (iso == null) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
