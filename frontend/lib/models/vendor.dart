class Vendor {
  final String id;
  final String userId;
  final String storeName;
  final String? storeDescription;
  final String? storeLogoUrl;
  final String? storeBannerUrl;
  final String address;
  final String city;
  final String state;
  final double deliveryRadiusKm;
  final String status;
  final bool isActive;
  final double rating;
  final int totalOrders;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.userId,
    required this.storeName,
    this.storeDescription,
    this.storeLogoUrl,
    this.storeBannerUrl,
    required this.address,
    required this.city,
    required this.state,
    this.deliveryRadiusKm = 10.0,
    required this.status,
    this.isActive = true,
    this.rating = 0.0,
    this.totalOrders = 0,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      userId: json['user_id'],
      storeName: json['store_name'],
      storeDescription: json['store_description'],
      storeLogoUrl: json['store_logo_url'],
      storeBannerUrl: json['store_banner_url'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      deliveryRadiusKm:
          (json['delivery_radius_km'] as num?)?.toDouble() ?? 10.0,
      status: json['status'] ?? 'pending',
      isActive: json['is_active'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
