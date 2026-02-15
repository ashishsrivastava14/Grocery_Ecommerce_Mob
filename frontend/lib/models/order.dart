class OrderItem {
  final String id;
  final String productId;
  final String? variantId;
  final String productName;
  final String? productImageUrl;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final String unitType;
  final double unitValue;

  OrderItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    required this.unitType,
    this.unitValue = 1.0,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product_id'],
      variantId: json['variant_id'],
      productName: json['product_name'],
      productImageUrl: json['product_image_url'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'],
      totalPrice: (json['total_price'] as num).toDouble(),
      unitType: json['unit_type'] ?? 'kg',
      unitValue: (json['unit_value'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class OrderStatusHistory {
  final String id;
  final String status;
  final String? note;
  final DateTime createdAt;

  OrderStatusHistory({
    required this.id,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'],
      status: json['status'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String vendorId;
  final String? deliveryPartnerId;
  final Map<String, dynamic> deliveryAddress;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? couponCode;
  final String? customerNote;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.vendorId,
    this.deliveryPartnerId,
    required this.deliveryAddress,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.couponCode,
    this.customerNote,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.items,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      customerId: json['customer_id'],
      vendorId: json['vendor_id'],
      deliveryPartnerId: json['delivery_partner_id'],
      deliveryAddress: json['delivery_address'] ?? {},
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'] ?? 'cod',
      couponCode: json['coupon_code'],
      customerNote: json['customer_note'],
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'])
          : null,
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'])
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((e) => OrderStatusHistory.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
