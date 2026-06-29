import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cart_item.dart';

// ---------------------------------------------------------------------------
// Cart State
// ---------------------------------------------------------------------------

class CartState {
  final Map<String, CartItem> items; // keyed by productId
  final String? appliedCouponCode;
  final double discountPercentage;

  const CartState({
    this.items = const {},
    this.appliedCouponCode,
    this.discountPercentage = 0.0,
  });

  double get subtotal =>
      items.values.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  double get discountAmount => subtotal * (discountPercentage / 100);

  double get total => subtotal - discountAmount;

  int get totalItemCount =>
      items.values.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    Map<String, CartItem>? items,
    String? appliedCouponCode,
    double? discountPercentage,
    bool clearCoupon = false,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCouponCode:
          clearCoupon ? null : (appliedCouponCode ?? this.appliedCouponCode),
      discountPercentage:
          clearCoupon ? 0.0 : (discountPercentage ?? this.discountPercentage),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart Notifier
// ---------------------------------------------------------------------------

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem(CartItem item) {
    final existing = state.items[item.productId];
    final updatedItems = Map<String, CartItem>.from(state.items);

    if (existing != null) {
      updatedItems[item.productId] =
          existing.copyWith(quantity: existing.quantity + item.quantity);
    } else {
      updatedItems[item.productId] = item;
    }

    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String productId) {
    final updatedItems = Map<String, CartItem>.from(state.items)
      ..remove(productId);
    state = state.copyWith(items: updatedItems);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updatedItems = Map<String, CartItem>.from(state.items);
    final existing = updatedItems[productId];
    if (existing != null) {
      updatedItems[productId] = existing.copyWith(quantity: quantity);
    }
    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = const CartState();
  }

  /// Returns true if the coupon was valid, false otherwise.
  /// Pass in the list of active coupons fetched from Supabase.
  bool applyCoupon(String code, List<Map<String, dynamic>> activeCoupons) {
    final now = DateTime.now();
    final match = activeCoupons.cast<Map<String, dynamic>>().where((c) {
      final couponCode = (c['code'] ?? '').toString().toUpperCase();
      final validUntil = c['valid_until'] != null
          ? DateTime.tryParse(c['valid_until'].toString())
          : null;
      final validFrom = c['valid_from'] != null
          ? DateTime.tryParse(c['valid_from'].toString())
          : null;
      return couponCode == code.toUpperCase() &&
          (validFrom == null || now.isAfter(validFrom)) &&
          (validUntil == null || now.isBefore(validUntil));
    });

    if (match.isEmpty) return false;

    final coupon = match.first;
    final discount =
        (coupon['discount_percentage'] ?? 0.0).toDouble();

    state = state.copyWith(
      appliedCouponCode: coupon['code'].toString(),
      discountPercentage: discount,
    );
    return true;
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});