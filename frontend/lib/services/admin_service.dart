import 'api_service.dart';

class AdminService {
  final _api = ApiService();

  // ─── Dashboard ────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _api.get('/admin/dashboard');
    return Map<String, dynamic>.from(res.data['data']);
  }

  Future<List<Map<String, dynamic>>> getRevenueChart({
    String period = 'daily',
    int days = 30,
  }) async {
    final res = await _api.get('/admin/dashboard/revenue-chart',
        queryParams: {'period': period, 'days': days});
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 10}) async {
    final res = await _api.get('/admin/dashboard/recent-orders',
        queryParams: {'limit': limit});
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<List<Map<String, dynamic>>> getTopVendors({int limit = 5}) async {
    final res = await _api.get('/admin/dashboard/top-vendors',
        queryParams: {'limit': limit});
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    final res = await _api.get('/admin/dashboard/top-products',
        queryParams: {'limit': limit});
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  // ─── Vendors ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getVendors({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _api.get('/admin/vendors', queryParams: params);
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getVendorDetail(String vendorId) async {
    final res = await _api.get('/admin/vendors/$vendorId');
    return Map<String, dynamic>.from(res.data['data']);
  }

  Future<void> updateVendor(String vendorId, Map<String, dynamic> data) async {
    await _api.put('/admin/vendors/$vendorId', data: data);
  }

  Future<Map<String, dynamic>> createVendor(Map<String, dynamic> data) async {
    final res = await _api.post('/admin/vendors', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> deleteVendor(String vendorId, {bool hardDelete = false}) async {
    await _api.delete('/admin/vendors/$vendorId',
        queryParams: {'hard_delete': hardDelete});
  }

  // ─── Orders ───────────────────────────────────────────────
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? paymentStatus,
    String? vendorId,
    String? search,
    String? dateFrom,
    String? dateTo,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (status != null) params['status'] = status;
    if (paymentStatus != null) params['payment_status'] = paymentStatus;
    if (vendorId != null) params['vendor_id'] = vendorId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    final res = await _api.get('/admin/orders', queryParams: params);
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    final res = await _api.get('/admin/orders/$orderId');
    return Map<String, dynamic>.from(res.data['data']);
  }

  Future<void> updateOrderStatus(
      String orderId, String status, String? note) async {
    final params = <String, dynamic>{'status': status};
    if (note != null) params['note'] = note;
    await _api.put('/admin/orders/$orderId/status', data: params);
  }

  // ─── Customers ────────────────────────────────────────────
  Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (isActive != null) params['is_active'] = isActive;
    final res = await _api.get('/admin/customers', queryParams: params);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> toggleCustomerActive(String userId) async {
    await _api.put('/admin/customers/$userId/toggle-active');
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    final res = await _api.post('/admin/customers', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updateCustomer(String userId, Map<String, dynamic> data) async {
    await _api.put('/admin/customers/$userId', data: data);
  }

  Future<void> deleteCustomer(String userId, {bool anonymize = false}) async {
    await _api
        .delete('/admin/customers/$userId', queryParams: {'anonymize': anonymize});
  }

  // ─── Products ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? categoryId,
    String? vendorId,
    String? search,
    bool lowStock = false,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'low_stock': lowStock,
    };
    if (status != null) params['status'] = status;
    if (categoryId != null) params['category_id'] = categoryId;
    if (vendorId != null) params['vendor_id'] = vendorId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _api.get('/admin/products', queryParams: params);
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await _api.get('/admin/categories');
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final res = await _api.post('/admin/categories', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updateCategory(
      String categoryId, Map<String, dynamic> data) async {
    await _api.put('/admin/categories/$categoryId', data: data);
  }

  Future<void> deleteCategory(String categoryId,
      {String? moveProductsTo}) async {
    final params = <String, dynamic>{};
    if (moveProductsTo != null) params['move_products_to'] = moveProductsTo;
    await _api.delete('/admin/categories/$categoryId', queryParams: params);
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _api.post('/admin/products', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _api.put('/admin/products/$productId', data: data);
  }

  Future<void> deleteProduct(String productId) async {
    await _api.delete('/admin/products/$productId');
  }

  // ─── Transactions ─────────────────────────────────────────
  Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int pageSize = 20,
    String? paymentMethod,
    String? status,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (paymentMethod != null) params['payment_method'] = paymentMethod;
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;
    final res = await _api.get('/admin/transactions', queryParams: params);
    return Map<String, dynamic>.from(res.data);
  }

  // ─── Payouts ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getPayouts({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? vendorId,
  }) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null) params['status'] = status;
    if (vendorId != null) params['vendor_id'] = vendorId;
    final res = await _api.get('/admin/payouts', queryParams: params);
    return Map<String, dynamic>.from(res.data);
  }

  // ─── Coupons ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getCoupons({
    int page = 1,
    int pageSize = 20,
    bool? isActive,
  }) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (isActive != null) params['is_active'] = isActive;
    final res = await _api.get('/admin/coupons', queryParams: params);
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> data) async {
    final res = await _api.post('/admin/coupons', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> toggleCoupon(String couponId) async {
    await _api.put('/admin/coupons/$couponId/toggle');
  }

  Future<void> deleteCoupon(String couponId) async {
    await _api.delete('/admin/coupons/$couponId');
  }

  // ─── Reviews ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getReviews({
    int page = 1,
    int pageSize = 20,
    bool? isApproved,
  }) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (isApproved != null) params['is_approved'] = isApproved;
    final res = await _api.get('/admin/reviews', queryParams: params);
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> toggleReviewApproval(String reviewId) async {
    await _api.put('/admin/reviews/$reviewId/toggle-approve');
  }
}
