import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_common.dart';

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  ConsumerState<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends ConsumerState<AdminCouponsScreen> {
  final _currencyFmt =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(adminCouponsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminPageHeader(
                  title: 'Coupon Management',
                  subtitle: 'Create and manage discount coupons',
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Coupon'),
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
          couponsAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminCouponsProvider)),
            data: (result) {
              final coupons =
                  List<Map<String, dynamic>>.from(result['data'] ?? []);
              final total = result['total'] ?? 0;
              final page = result['page'] ?? 1;
              final totalPages = result['total_pages'] ?? 1;

              if (coupons.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'No coupons found');
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
                          DataColumn(label: Text('CODE')),
                          DataColumn(label: Text('TYPE')),
                          DataColumn(label: Text('VALUE')),
                          DataColumn(label: Text('MIN ORDER')),
                          DataColumn(label: Text('USAGE')),
                          DataColumn(label: Text('ACTIVE')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: coupons.map((c) {
                          final isActive = c['is_active'] == true;
                          final discType = c['discount_type'] ?? 'percentage';
                          final discVal = c['discount_value'] ?? 0;
                          final usedCount = c['used_count'] ?? 0;
                          final maxUses = c['max_uses'] ?? 0;

                          return DataRow(cells: [
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.primary.withAlpha(40)),
                              ),
                              child: Text(c['code'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5)),
                            )),
                            DataCell(Text(
                                discType == 'percentage'
                                    ? 'Percentage'
                                    : 'Fixed',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text(
                                discType == 'percentage'
                                    ? '${discVal}%'
                                    : '₹$discVal',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))),
                            DataCell(Text(
                                _currencyFmt
                                    .format(c['min_order_amount'] ?? 0),
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text(
                                maxUses > 0
                                    ? '$usedCount / $maxUses'
                                    : '$usedCount / ∞',
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Switch(
                              value: isActive,
                              onChanged: (_) => _toggleCoupon(c),
                              activeColor: AppColors.success,
                            )),
                            DataCell(IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: AppColors.error),
                              tooltip: 'Delete',
                              onPressed: () => _deleteCoupon(c),
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
                        child: Text('$total coupons',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textLight)),
                      ),
                      AdminPagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onPageChanged: (p) => ref
                            .read(adminCouponPageProvider.notifier)
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

  Future<void> _toggleCoupon(Map<String, dynamic> coupon) async {
    try {
      final service = ref.read(adminServiceProvider);
      await service.toggleCoupon(coupon['id']);
      ref.invalidate(adminCouponsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _deleteCoupon(Map<String, dynamic> coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text(
            'Are you sure you want to delete coupon "${coupon['code']}"?'),
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
    try {
      final service = ref.read(adminServiceProvider);
      await service.deleteCoupon(coupon['id']);
      ref.invalidate(adminCouponsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Coupon deleted'),
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

  void _showCreateDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController(text: '0');
    final maxDiscountCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController(text: '0');
    String discountType = 'percentage';
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Coupon'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Coupon Code',
                        hintText: 'e.g. SAVE20',
                        prefixIcon: Icon(Icons.local_offer_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Min 3 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: discountType,
                      decoration: const InputDecoration(
                        labelText: 'Discount Type',
                        prefixIcon: Icon(Icons.percent),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'percentage',
                            child: Text('Percentage (%)')),
                        DropdownMenuItem(
                            value: 'fixed',
                            child: Text('Fixed Amount (₹)')),
                      ],
                      onChanged: (v) => setDialogState(
                          () => discountType = v ?? 'percentage'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: valueCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Discount Value',
                            ),
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n <= 0) return 'Invalid';
                              if (discountType == 'percentage' && n > 100)
                                return 'Max 100%';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: minOrderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Order (₹)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: maxDiscountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Discount (₹)',
                              hintText: 'Optional',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: maxUsesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Uses (0=∞)',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isCreating = true);
                      try {
                        final service = ref.read(adminServiceProvider);
                        await service.createCoupon({
                          'code': codeCtrl.text.trim(),
                          'discount_type': discountType,
                          'discount_value':
                              double.parse(valueCtrl.text.trim()),
                          'min_order_amount':
                              double.tryParse(minOrderCtrl.text.trim()) ?? 0,
                          'max_discount_amount':
                              maxDiscountCtrl.text.trim().isNotEmpty
                                  ? double.tryParse(
                                      maxDiscountCtrl.text.trim())
                                  : null,
                          'max_uses':
                              int.tryParse(maxUsesCtrl.text.trim()) ?? 0,
                        });
                        ref.invalidate(adminCouponsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Coupon created!'),
                            backgroundColor: AppColors.success,
                          ));
                        }
                      } catch (e) {
                        setDialogState(() => isCreating = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.error,
                          ));
                        }
                      }
                    },
              child: isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
