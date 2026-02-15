import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../models/product.dart';

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(Cart());

  void addItem(Product product, [int quantity = 1]) {
    state.addItem(product, quantity: quantity);
    state = state.copyWith();
  }

  void removeItem(String productId) {
    // Find vendor for this product
    for (final vendorId in state.vendorCarts.keys) {
      final hasProduct = state.vendorCarts[vendorId]!.any((i) => i.product.id == productId);
      if (hasProduct) {
        state.removeItem(vendorId, productId);
        break;
      }
    }
    state = state.copyWith();
  }

  void updateQuantity(String productId, int quantity) {
    for (final vendorId in state.vendorCarts.keys) {
      final hasProduct = state.vendorCarts[vendorId]!.any((i) => i.product.id == productId);
      if (hasProduct) {
        state.updateQuantity(vendorId, productId, quantity);
        break;
      }
    }
    state = state.copyWith();
  }

  void clearCart() {
    state.clear();
    state = Cart();
  }

  void clearVendorCart(String vendorId) {
    state.clearVendor(vendorId);
    state = state.copyWith();
  }
}

// Cart item count for badge
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});
