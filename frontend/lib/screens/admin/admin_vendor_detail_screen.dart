import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminVendorDetailScreen extends ConsumerWidget {
  final String vendorId;
  const AdminVendorDetailScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminVendorDetailProvider(vendorId));

    return detailAsync.when(
      loading: () => const AdminLoadingState(),
      error: (e, _) => AdminErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminVendorDetailProvider(vendorId))),
      data: (vendor) => _VendorDetail(vendor: vendor, vendorId: vendorId),
    );
  }
}

class _VendorDetail extends ConsumerWidget {
  final Map<String, dynamic> vendor;
  final String vendorId;

  const _VendorDetail({required this.vendor, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Header
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/admin/vendors'),
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
                    Text(vendor['store_name'] ?? 'Vendor',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [
                      AdminStatusBadge(status: vendor['status'] ?? ''),
                      const SizedBox(width: 12),
                      Text('ID: ${vendorId.substring(0, 8)}...',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textLight)),
                    ]),
                  ],
                ),
              ),
              _buildActionButtons(context, ref),
            ],
          ),
          const SizedBox(height: 24),
          // Stats Row
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final children = [
              _MiniStat(
                  label: 'Total Revenue',
                  value: '₹${_fmt(vendor['total_revenue'])}',
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.success),
              _MiniStat(
                  label: 'Total Orders',
                  value: '${vendor['total_orders_count'] ?? 0}',
                  icon: Icons.shopping_bag_rounded,
                  color: AppColors.primary),
              _MiniStat(
                  label: 'Products',
                  value: '${vendor['products_count'] ?? 0}',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.info),
              _MiniStat(
                  label: 'Rating',
                  value: '${(vendor['rating'] ?? 0).toStringAsFixed(1)}',
                  icon: Icons.star_rounded,
                  color: AppColors.starYellow),
            ];
            if (isWide) {
              return Row(
                  children:
                      children.map((c) => Expanded(child: c)).toList());
            }
            return GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: children,
            );
          }),
          const SizedBox(height: 24),
          // Details Grid
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStoreInfo(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildBusinessInfo(context)),
                ],
              );
            }
            return Column(children: [
              _buildStoreInfo(context),
              const SizedBox(height: 24),
              _buildBusinessInfo(context),
            ]);
          }),
          const SizedBox(height: 24),
          _buildBankInfo(context),
          // Documents
          if ((vendor['documents'] as List?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 24),
            _buildDocuments(context),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final status = vendor['status'] ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'pending' || status == 'under_review') ...[
          ElevatedButton.icon(
            onPressed: () => _updateStatus(context, ref, 'approved'),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _updateStatus(context, ref, 'rejected'),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        if (status == 'approved')
          OutlinedButton.icon(
            onPressed: () => _updateStatus(context, ref, 'suspended'),
            icon: const Icon(Icons.block_rounded, size: 18),
            label: const Text('Suspend'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        if (status == 'suspended')
          ElevatedButton.icon(
            onPressed: () => _updateStatus(context, ref, 'approved'),
            icon: const Icon(Icons.restore_rounded, size: 18),
            label: const Text('Reactivate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }

  Widget _buildStoreInfo(BuildContext context) {
    return AdminCard(
      title: 'Store Information',
      child: Column(
        children: [
          _InfoRow(label: 'Store Name', value: vendor['store_name'] ?? 'N/A'),
          _InfoRow(label: 'Description', value: vendor['description'] ?? 'No description'),
          _InfoRow(label: 'Address', value: vendor['address'] ?? 'N/A'),
          _InfoRow(label: 'City', value: vendor['city'] ?? 'N/A'),
          _InfoRow(label: 'State', value: vendor['state'] ?? 'N/A'),
          _InfoRow(label: 'Pincode', value: vendor['pincode'] ?? 'N/A'),
          _InfoRow(label: 'Contact Email', value: vendor['user_email'] ?? 'N/A'),
          _InfoRow(label: 'Contact Phone', value: vendor['user_phone'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo(BuildContext context) {
    return AdminCard(
      title: 'Business Details',
      child: Column(
        children: [
          _InfoRow(label: 'GSTIN', value: vendor['gstin'] ?? 'N/A'),
          _InfoRow(label: 'PAN Number', value: vendor['pan_number'] ?? 'N/A'),
          _InfoRow(label: 'FSSAI License', value: vendor['fssai_license'] ?? 'N/A'),
          _InfoRow(
              label: 'Commission Rate',
              value:
                  '${((vendor['commission_rate'] ?? 0) * 100).toStringAsFixed(1)}%'),
          _InfoRow(
              label: 'Delivery Radius',
              value: '${vendor['delivery_radius'] ?? 'N/A'} km'),
          _InfoRow(
              label: 'Min Order Amount',
              value: '₹${vendor['min_order_amount'] ?? 0}'),
          _InfoRow(
              label: 'Member Since',
              value: _formatDate(vendor['created_at'])),
        ],
      ),
    );
  }

  Widget _buildBankInfo(BuildContext context) {
    return AdminCard(
      title: 'Bank Details',
      child: Column(
        children: [
          _InfoRow(label: 'Bank Name', value: vendor['bank_name'] ?? 'N/A'),
          _InfoRow(
              label: 'Account Holder',
              value: vendor['bank_account_name'] ?? 'N/A'),
          _InfoRow(
              label: 'Account Number',
              value: vendor['bank_account_number'] ?? 'N/A'),
          _InfoRow(label: 'IFSC Code', value: vendor['bank_ifsc'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDocuments(BuildContext context) {
    final docs = List<Map<String, dynamic>>.from(vendor['documents'] ?? []);
    return AdminCard(
      title: 'Documents',
      child: Column(
        children: docs
            .map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.description_rounded,
                          color: AppColors.info, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['document_type'] ?? 'Document',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(d['document_url'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      AdminStatusBadge(
                          status: d['is_verified'] == true
                              ? 'approved'
                              : 'pending'),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String status) async {
    try {
      await AdminService().updateVendor(vendorId, {'status': status});
      ref.invalidate(adminVendorDetailProvider(vendorId));
      ref.invalidate(adminVendorsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Vendor $status successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _fmt(dynamic amount) {
    final num value = amount is num ? amount : 0;
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return 'N/A';
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dt.toString()));
    } catch (_) {
      return dt.toString();
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
