import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminTransactionsScreen extends ConsumerStatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  ConsumerState<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState
    extends ConsumerState<AdminTransactionsScreen> {
  final _searchController = TextEditingController();
  final _currencyFmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txnAsync = ref.watch(adminTransactionsProvider);
    final statusFilter = ref.watch(adminTransactionStatusFilterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Transactions',
            subtitle: 'All payment transactions across the platform',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AdminSearchBar(
                controller: _searchController,
                hint: 'Search by order number...',
                onChanged: (v) =>
                    ref.read(adminTransactionSearchProvider.notifier).state = v,
                onClear: () {
                  _searchController.clear();
                  ref.read(adminTransactionSearchProvider.notifier).state = '';
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminFilterChips(
            options: const ['pending', 'completed', 'failed', 'refunded'],
            selected: statusFilter,
            onSelected: (v) {
              ref.read(adminTransactionStatusFilterProvider.notifier).state = v;
              ref.read(adminTransactionPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 20),
          txnAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminTransactionsProvider)),
            data: (result) {
              final transactions =
                  List<Map<String, dynamic>>.from(result['data'] ?? []);
              final total = result['total'] ?? 0;
              final page = result['page'] ?? 1;
              final totalPages = result['total_pages'] ?? 1;

              if (transactions.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions found');
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
                          DataColumn(label: Text('TXN ID')),
                          DataColumn(label: Text('ORDER')),
                          DataColumn(label: Text('CUSTOMER')),
                          DataColumn(label: Text('METHOD')),
                          DataColumn(label: Text('AMOUNT')),
                          DataColumn(label: Text('COMMISSION')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('DATE')),
                        ],
                        rows: transactions.map((t) {
                          return DataRow(cells: [
                            DataCell(Text(
                                '#${t['id']?.toString().padLeft(5, '0') ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))),
                            DataCell(Text(
                                t['order_number'] ?? '#${t['order_id'] ?? ''}',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text(t['customer_name'] ?? 'N/A',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(_methodChip(
                                t['payment_method'] ?? 'unknown')),
                            DataCell(Text(
                                _currencyFmt.format(t['amount'] ?? 0),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))),
                            DataCell(Text(
                                _currencyFmt
                                    .format(t['platform_commission'] ?? 0),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary))),
                            DataCell(AdminStatusBadge(
                                status: t['payment_status'] ??
                                    t['status'] ??
                                    '')),
                            DataCell(Text(
                                _formatDate(t['created_at']),
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
                        child: Text('$total transactions',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textLight)),
                      ),
                      AdminPagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onPageChanged: (p) => ref
                            .read(adminTransactionPageProvider.notifier)
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

  Widget _methodChip(String method) {
    IconData icon;
    switch (method.toLowerCase()) {
      case 'upi':
        icon = Icons.account_balance;
        break;
      case 'card':
        icon = Icons.credit_card;
        break;
      case 'wallet':
        icon = Icons.account_balance_wallet;
        break;
      case 'cod':
        icon = Icons.money;
        break;
      default:
        icon = Icons.payment;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(method.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
