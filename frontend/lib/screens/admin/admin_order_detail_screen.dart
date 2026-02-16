import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminOrderDetailProvider(orderId));
    return detailAsync.when(
      loading: () => const AdminLoadingState(),
      error: (e, _) => AdminErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminOrderDetailProvider(orderId))),
      data: (order) => _OrderDetail(order: order, orderId: orderId),
    );
  }
}

class _OrderDetail extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;
  final String orderId;
  const _OrderDetail({required this.order, required this.orderId});

  @override
  ConsumerState<_OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends ConsumerState<_OrderDetail> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/admin/orders'),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ${o['order_number'] ?? ''}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [
                      AdminStatusBadge(status: o['status'] ?? ''),
                      const SizedBox(width: 8),
                      AdminStatusBadge(status: o['payment_status'] ?? ''),
                      const SizedBox(width: 12),
                      Text(_formatDate(o['created_at']),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textLight)),
                    ]),
                  ],
                ),
              ),
              _buildStatusUpdateButton(context),
            ],
          ),
          const SizedBox(height: 24),
          // Main content grid
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildLeftColumn(context)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildRightColumn(context)),
                ],
              );
            }
            return Column(children: [
              _buildLeftColumn(context),
              const SizedBox(height: 24),
              _buildRightColumn(context),
            ]);
          }),
          const SizedBox(height: 24),
          // Status History
          _buildStatusHistory(context),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateButton(BuildContext context) {
    final status = widget.order['status'] ?? '';
    final nextStatuses = _getNextStatuses(status);
    if (nextStatuses.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      onSelected: (newStatus) => _updateStatus(newStatus),
      enabled: !_updating,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_updating)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
            else
              const Icon(Icons.update_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Update Status',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
      itemBuilder: (context) => nextStatuses
          .map((s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    AdminStatusBadge(status: s),
                  ],
                ),
              ))
          .toList(),
    );
  }

  List<String> _getNextStatuses(String current) {
    switch (current) {
      case 'pending':
        return ['confirmed', 'cancelled'];
      case 'confirmed':
        return ['preparing', 'cancelled'];
      case 'preparing':
        return ['ready_for_pickup'];
      case 'ready_for_pickup':
        return ['out_for_delivery'];
      case 'out_for_delivery':
        return ['delivered'];
      default:
        return [];
    }
  }

  Widget _buildLeftColumn(BuildContext context) {
    final o = widget.order;
    final items = List<Map<String, dynamic>>.from(o['items'] ?? []);

    return Column(
      children: [
        // Order Items
        AdminCard(
          title: 'Order Items (${items.length})',
          padding: EdgeInsets.zero,
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No items'))
              : Column(
                  children: items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Row(
                        children: [
                          if (item['product_image_url'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['product_image_url'],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.image,
                                      size: 20, color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_rounded,
                                  size: 20, color: Colors.grey),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['product_name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(
                                    '₹${item['unit_price']} × ${item['quantity']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight)),
                              ],
                            ),
                          ),
                          Text('₹${item['total_price'] ?? 0}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    final o = widget.order;
    return Column(
      children: [
        // Payment Summary
        AdminCard(
          title: 'Payment Summary',
          child: Column(
            children: [
              _SummaryRow(label: 'Subtotal', value: '₹${o['subtotal'] ?? 0}'),
              _SummaryRow(
                  label: 'Delivery Fee', value: '₹${o['delivery_fee'] ?? 0}'),
              if ((o['discount_amount'] ?? 0) > 0)
                _SummaryRow(
                    label: 'Discount',
                    value: '-₹${o['discount_amount']}',
                    valueColor: AppColors.success),
              if ((o['tax_amount'] ?? 0) > 0)
                _SummaryRow(
                    label: 'Tax', value: '₹${o['tax_amount']}'),
              const Divider(height: 20),
              _SummaryRow(
                  label: 'Total',
                  value: '₹${o['total_amount'] ?? 0}',
                  isBold: true),
              const SizedBox(height: 8),
              _SummaryRow(
                  label: 'Commission',
                  value:
                      '₹${o['commission_amount'] ?? 0} (${((o['commission_rate'] ?? 0) * 100).toStringAsFixed(0)}%)'),
              _SummaryRow(
                  label: 'Vendor Payout',
                  value: '₹${o['vendor_payout_amount'] ?? 0}',
                  valueColor: AppColors.success),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Customer & Vendor Info
        AdminCard(
          title: 'Customer & Vendor',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoItem(
                  icon: Icons.person_rounded,
                  label: 'Customer',
                  value: o['customer_name'] ?? 'N/A'),
              _InfoItem(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: o['customer_email'] ?? 'N/A'),
              const Divider(height: 20),
              _InfoItem(
                  icon: Icons.store_rounded,
                  label: 'Vendor',
                  value: o['vendor_name'] ?? 'N/A'),
              _InfoItem(
                  icon: Icons.payment_rounded,
                  label: 'Payment',
                  value: o['payment_method'] ?? 'N/A'),
              if (o['coupon_code'] != null)
                _InfoItem(
                    icon: Icons.local_offer_rounded,
                    label: 'Coupon',
                    value: o['coupon_code']),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Delivery Address
        if (o['delivery_address'] != null)
          AdminCard(
            title: 'Delivery Address',
            child: Text(
              _formatAddress(o['delivery_address']),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusHistory(BuildContext context) {
    final history =
        List<Map<String, dynamic>>.from(widget.order['status_history'] ?? []);
    if (history.isEmpty) return const SizedBox.shrink();

    return AdminCard(
      title: 'Status History',
      child: Column(
        children: history.map((h) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                AdminStatusBadge(status: h['status'] ?? ''),
                const SizedBox(width: 12),
                if (h['note'] != null)
                  Expanded(
                      child: Text(h['note'],
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary))),
                Text(_formatDate(h['created_at']),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await AdminService()
          .updateOrderStatus(widget.orderId, newStatus, null);
      ref.invalidate(adminOrderDetailProvider(widget.orderId));
      ref.invalidate(adminOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return '';
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(dt.toString()));
    } catch (_) {
      return dt.toString();
    }
  }

  String _formatAddress(dynamic addr) {
    if (addr is Map) {
      return [
        addr['street'],
        addr['city'],
        addr['state'],
        addr['pincode']
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    }
    return addr?.toString() ?? '';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow(
      {required this.label,
      required this.value,
      this.isBold = false,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
