import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

// ═══════════════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════════════

final adminDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return await ref.read(adminServiceProvider).getDashboard();
});

final adminRevenueChartProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String period, int days})>(
        (ref, params) async {
  return await ref
      .read(adminServiceProvider)
      .getRevenueChart(period: params.period, days: params.days);
});

final adminRecentOrdersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(adminServiceProvider).getRecentOrders(limit: 10);
});

final adminTopVendorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(adminServiceProvider).getTopVendors(limit: 5);
});

final adminTopProductsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(adminServiceProvider).getTopProducts(limit: 5);
});

// ═══════════════════════════════════════════════════════════════
// VENDORS
// ═══════════════════════════════════════════════════════════════

final adminVendorStatusFilterProvider = StateProvider<String?>((ref) => null);
final adminVendorSearchProvider = StateProvider<String>((ref) => '');
final adminVendorPageProvider = StateProvider<int>((ref) => 1);

final adminVendorsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final status = ref.watch(adminVendorStatusFilterProvider);
  final search = ref.watch(adminVendorSearchProvider);
  final page = ref.watch(adminVendorPageProvider);
  return await ref.read(adminServiceProvider).getVendors(
        page: page,
        status: status,
        search: search.isNotEmpty ? search : null,
      );
});

final adminVendorDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, vendorId) async {
  return await ref.read(adminServiceProvider).getVendorDetail(vendorId);
});

// ═══════════════════════════════════════════════════════════════
// ORDERS
// ═══════════════════════════════════════════════════════════════

final adminOrderStatusFilterProvider = StateProvider<String?>((ref) => null);
final adminOrderPaymentFilterProvider = StateProvider<String?>((ref) => null);
final adminOrderSearchProvider = StateProvider<String>((ref) => '');
final adminOrderPageProvider = StateProvider<int>((ref) => 1);

final adminOrdersProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final status = ref.watch(adminOrderStatusFilterProvider);
  final paymentStatus = ref.watch(adminOrderPaymentFilterProvider);
  final search = ref.watch(adminOrderSearchProvider);
  final page = ref.watch(adminOrderPageProvider);
  return await ref.read(adminServiceProvider).getOrders(
        page: page,
        status: status,
        paymentStatus: paymentStatus,
        search: search.isNotEmpty ? search : null,
      );
});

final adminOrderDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, orderId) async {
  return await ref.read(adminServiceProvider).getOrderDetail(orderId);
});

// ═══════════════════════════════════════════════════════════════
// CUSTOMERS
// ═══════════════════════════════════════════════════════════════

final adminCustomerSearchProvider = StateProvider<String>((ref) => '');
final adminCustomerPageProvider = StateProvider<int>((ref) => 1);
final adminCustomerActiveFilterProvider = StateProvider<bool?>((ref) => null);

final adminCustomersProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final search = ref.watch(adminCustomerSearchProvider);
  final page = ref.watch(adminCustomerPageProvider);
  final isActive = ref.watch(adminCustomerActiveFilterProvider);
  return await ref.read(adminServiceProvider).getCustomers(
        page: page,
        search: search.isNotEmpty ? search : null,
        isActive: isActive,
      );
});

// ═══════════════════════════════════════════════════════════════
// PRODUCTS
// ═══════════════════════════════════════════════════════════════

final adminProductStatusFilterProvider = StateProvider<String?>((ref) => null);
final adminProductSearchProvider = StateProvider<String>((ref) => '');
final adminProductPageProvider = StateProvider<int>((ref) => 1);
final adminProductLowStockProvider = StateProvider<bool>((ref) => false);

final adminProductsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final status = ref.watch(adminProductStatusFilterProvider);
  final search = ref.watch(adminProductSearchProvider);
  final page = ref.watch(adminProductPageProvider);
  final lowStock = ref.watch(adminProductLowStockProvider);
  return await ref.read(adminServiceProvider).getProducts(
        page: page,
        status: status,
        search: search.isNotEmpty ? search : null,
        lowStock: lowStock,
      );
});

final adminCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(adminServiceProvider).getCategories();
});

// ═══════════════════════════════════════════════════════════════
// TRANSACTIONS
// ═══════════════════════════════════════════════════════════════

final adminTransactionStatusFilterProvider =
    StateProvider<String?>((ref) => null);
final adminTransactionSearchProvider = StateProvider<String>((ref) => '');
final adminTransactionPageProvider = StateProvider<int>((ref) => 1);

final adminTransactionsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final status = ref.watch(adminTransactionStatusFilterProvider);
  final search = ref.watch(adminTransactionSearchProvider);
  final page = ref.watch(adminTransactionPageProvider);
  return await ref.read(adminServiceProvider).getTransactions(
        page: page,
        status: status,
        search: search.isNotEmpty ? search : null,
      );
});

// ═══════════════════════════════════════════════════════════════
// PAYOUTS
// ═══════════════════════════════════════════════════════════════

final adminPayoutStatusFilterProvider = StateProvider<String?>((ref) => null);
final adminPayoutPageProvider = StateProvider<int>((ref) => 1);

final adminPayoutsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final status = ref.watch(adminPayoutStatusFilterProvider);
  final page = ref.watch(adminPayoutPageProvider);
  return await ref.read(adminServiceProvider).getPayouts(
        page: page,
        status: status,
      );
});

// ═══════════════════════════════════════════════════════════════
// COUPONS
// ═══════════════════════════════════════════════════════════════

final adminCouponActiveFilterProvider = StateProvider<bool?>((ref) => null);
final adminCouponPageProvider = StateProvider<int>((ref) => 1);

final adminCouponsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final isActive = ref.watch(adminCouponActiveFilterProvider);
  final page = ref.watch(adminCouponPageProvider);
  return await ref
      .read(adminServiceProvider)
      .getCoupons(page: page, isActive: isActive);
});

// ═══════════════════════════════════════════════════════════════
// REVIEWS
// ═══════════════════════════════════════════════════════════════

final adminReviewApprovedFilterProvider = StateProvider<bool?>((ref) => null);
final adminReviewStatusFilterProvider = StateProvider<String?>((ref) => null);
final adminReviewPageProvider = StateProvider<int>((ref) => 1);

final adminReviewsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final statusFilter = ref.watch(adminReviewStatusFilterProvider);
  bool? isApproved;
  if (statusFilter == 'approved') isApproved = true;
  if (statusFilter == 'pending') isApproved = false;
  final page = ref.watch(adminReviewPageProvider);
  return await ref
      .read(adminServiceProvider)
      .getReviews(page: page, isApproved: isApproved);
});
