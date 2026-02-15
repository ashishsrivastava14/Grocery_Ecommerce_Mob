class ProductCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final String? imageUrl;
  final String? parentId;
  final int sortOrder;
  final bool isActive;

  ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.imageUrl,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      iconUrl: json['icon_url'],
      imageUrl: json['image_url'],
      parentId: json['parent_id'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class ProductImage {
  final String id;
  final String imageUrl;
  final String? altText;
  final int sortOrder;
  final bool isPrimary;

  ProductImage({
    required this.id,
    required this.imageUrl,
    this.altText,
    this.sortOrder = 0,
    this.isPrimary = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      imageUrl: json['image_url'],
      altText: json['alt_text'],
      sortOrder: json['sort_order'] ?? 0,
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class ProductVariant {
  final String id;
  final String name;
  final String? sku;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String unitType;
  final double unitValue;
  final bool isActive;
  final Map<String, dynamic>? attributes;

  ProductVariant({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    this.compareAtPrice,
    this.stockQuantity = 0,
    required this.unitType,
    this.unitValue = 1.0,
    this.isActive = true,
    this.attributes,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      price: (json['price'] as num).toDouble(),
      compareAtPrice: json['compare_at_price']?.toDouble(),
      stockQuantity: json['stock_quantity'] ?? 0,
      unitType: json['unit_type'] ?? 'kg',
      unitValue: (json['unit_value'] as num?)?.toDouble() ?? 1.0,
      isActive: json['is_active'] ?? true,
      attributes: json['attributes'],
    );
  }
}

class Product {
  final String id;
  final String vendorId;
  final String categoryId;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final double price;
  final double? compareAtPrice;
  final String? sku;
  final int stockQuantity;
  final String unitType;
  final double unitValue;
  final String status;
  final bool isFeatured;
  final bool isOrganic;
  final double avgRating;
  final int totalReviews;
  final int totalSold;
  final Map<String, dynamic>? tags;
  final Map<String, dynamic>? nutritionalInfo;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    required this.price,
    this.compareAtPrice,
    this.sku,
    this.stockQuantity = 0,
    required this.unitType,
    this.unitValue = 1.0,
    required this.status,
    this.isFeatured = false,
    this.isOrganic = false,
    this.avgRating = 0.0,
    this.totalReviews = 0,
    this.totalSold = 0,
    this.tags,
    this.nutritionalInfo,
    this.images = const [],
    this.variants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get primaryImageUrl {
    final primary = images.where((img) => img.isPrimary).firstOrNull;
    return primary?.imageUrl ?? (images.isNotEmpty ? images.first.imageUrl : '');
  }

  bool get isOnSale =>
      compareAtPrice != null && compareAtPrice! > price;

  double get discountPercentage {
    if (!isOnSale) return 0;
    return ((compareAtPrice! - price) / compareAtPrice! * 100);
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      vendorId: json['vendor_id'],
      categoryId: json['category_id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      shortDescription: json['short_description'],
      price: (json['price'] as num).toDouble(),
      compareAtPrice: json['compare_at_price']?.toDouble(),
      sku: json['sku'],
      stockQuantity: json['stock_quantity'] ?? 0,
      unitType: json['unit_type'] ?? 'kg',
      unitValue: (json['unit_value'] as num?)?.toDouble() ?? 1.0,
      status: json['status'] ?? 'active',
      isFeatured: json['is_featured'] ?? false,
      isOrganic: json['is_organic'] ?? false,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      totalSold: json['total_sold'] ?? 0,
      tags: json['tags'],
      nutritionalInfo: json['nutritional_info'],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
