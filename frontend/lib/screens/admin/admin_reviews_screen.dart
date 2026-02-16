import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() =>
      _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(adminReviewsProvider);
    final statusFilter = ref.watch(adminReviewStatusFilterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Review Moderation',
            subtitle: 'Monitor and moderate customer reviews',
          ),
          const SizedBox(height: 20),
          AdminFilterChips(
            options: const ['approved', 'pending'],
            selected: statusFilter,
            onSelected: (v) {
              ref.read(adminReviewStatusFilterProvider.notifier).state = v;
              ref.read(adminReviewPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 20),
          reviewsAsync.when(
            loading: () => const AdminLoadingState(),
            error: (e, _) => AdminErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminReviewsProvider)),
            data: (result) {
              final reviews =
                  List<Map<String, dynamic>>.from(result['data'] ?? []);
              final total = result['total'] ?? 0;
              final page = result['page'] ?? 1;
              final totalPages = result['total_pages'] ?? 1;

              if (reviews.isEmpty) {
                return const AdminEmptyState(
                    icon: Icons.rate_review_outlined,
                    title: 'No reviews found');
              }

              return Column(
                children: [
                  ...reviews.map((r) => _ReviewCard(
                        review: r,
                        onToggleApproval: () => _toggleApproval(r),
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 12),
                        child: Text('$total reviews',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textLight)),
                      ),
                      AdminPagination(
                        currentPage: page,
                        totalPages: totalPages,
                        onPageChanged: (p) => ref
                            .read(adminReviewPageProvider.notifier)
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

  Future<void> _toggleApproval(Map<String, dynamic> review) async {
    try {
      final service = ref.read(adminServiceProvider);
      await service.toggleReviewApproval(review['id']);
      ref.invalidate(adminReviewsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(review['is_approved'] == true
              ? 'Review unapproved'
              : 'Review approved'),
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
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onToggleApproval;

  const _ReviewCard({required this.review, required this.onToggleApproval});

  @override
  Widget build(BuildContext context) {
    final isApproved = review['is_approved'] == true;
    final rating = (review['rating'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApproved ? Colors.grey.shade200 : AppColors.warning.withAlpha(80),
          width: isApproved ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withAlpha(25),
                child: Text(
                    (review['user_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['user_name'] ?? 'Anonymous',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                        _formatDate(review['created_at']),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              // Rating Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < rating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 18,
                          color: i < rating.round()
                              ? AppColors.starYellow
                              : Colors.grey.shade300,
                        )),
              ),
              const SizedBox(width: 12),
              // Approval Toggle
              Switch(
                value: isApproved,
                onChanged: (_) => onToggleApproval(),
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Product info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(review['product_name'] ?? 'Unknown Product',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Review title
          if (review['title'] != null && review['title'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(review['title'],
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          // Review comment
          Text(review['comment'] ?? '',
              style:
                  const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.5)),
          const SizedBox(height: 8),
          // Status badge
          Row(
            children: [
              AdminStatusBadge(
                  status: isApproved ? 'approved' : 'pending'),
              const Spacer(),
              if (review['vendor_reply'] != null)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.reply_rounded,
                        size: 14, color: AppColors.textLight),
                    SizedBox(width: 4),
                    Text('Vendor replied',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
