import 'product.dart';

class CartItem {
  final Product product;
  final ProductVariant? variant;
  int quantity;

  CartItem({
    required this.product,
    this.variant,
    this.quantity = 1,
  });

  double get unitPrice => variant?.price ?? product.price;
  double get totalPrice => unitPrice * quantity;
  String get displayUnit => variant?.unitType ?? product.unitType;

  Map<String, dynamic> toOrderJson() => {
        'product_id': product.id,
        'variant_id': variant?.id,
        'quantity': quantity,
      };
}

class Cart {
  final Map<String, List<CartItem>> vendorCarts;

  Cart({Map<String, List<CartItem>>? vendorCarts})
      : vendorCarts = vendorCarts ?? {};

  bool get isEmpty => vendorCarts.values.every((items) => items.isEmpty);

  List<CartItem> get items => vendorCarts.values.expand((items) => items).toList();

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalAmount => subtotal;

  void addItem(Product product, {ProductVariant? variant, int quantity = 1}) {
    final vendorId = product.vendorId;
    vendorCarts.putIfAbsent(vendorId, () => []);

    final existingIndex = vendorCarts[vendorId]!.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.variant?.id == variant?.id,
    );

    if (existingIndex >= 0) {
      vendorCarts[vendorId]![existingIndex].quantity += quantity;
    } else {
      vendorCarts[vendorId]!.add(
        CartItem(product: product, variant: variant, quantity: quantity),
      );
    }
  }

  void removeItem(String vendorId, String productId, {String? variantId}) {
    if (vendorCarts.containsKey(vendorId)) {
      vendorCarts[vendorId]!.removeWhere(
        (item) =>
            item.product.id == productId &&
            item.variant?.id == variantId,
      );
      if (vendorCarts[vendorId]!.isEmpty) {
        vendorCarts.remove(vendorId);
      }
    }
  }

  void updateQuantity(
    String vendorId,
    String productId,
    int quantity, {
    String? variantId,
  }) {
    if (vendorCarts.containsKey(vendorId)) {
      final index = vendorCarts[vendorId]!.indexWhere(
        (item) =>
            item.product.id == productId &&
            item.variant?.id == variantId,
      );
      if (index >= 0) {
        if (quantity <= 0) {
          removeItem(vendorId, productId, variantId: variantId);
        } else {
          vendorCarts[vendorId]![index].quantity = quantity;
        }
      }
    }
  }

  void clear() => vendorCarts.clear();
  void clearVendor(String vendorId) => vendorCarts.remove(vendorId);

  Cart copyWith() => Cart(vendorCarts: Map.from(vendorCarts));
}
