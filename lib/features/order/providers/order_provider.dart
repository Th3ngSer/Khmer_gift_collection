import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/order.dart';
import '../../../data/models/cart_item.dart';

// ---------------------------------------------------------------------------
// Order History Provider
// ---------------------------------------------------------------------------

final orderHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final rows = await Supabase.instance.client
      .from('orders')
      .select('*, order_items(*)')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return (rows as List).map((row) {
    final rawItems = row['order_items'] as List? ?? [];
    final items = rawItems.map((i) {
      return CartItem(
        id: i['id'].toString(),
        productId: i['product_id'].toString(),
        name: i['name'] ?? '',
        price: (i['unit_price'] ?? 0).toDouble(),
        quantity: i['quantity'] ?? 1,
        imageUrl: i['image_url'] ?? '',
      );
    }).toList();

    return OrderModel(
      id: row['id'].toString(),
      totalAmount: (row['total_amount'] ?? 0).toDouble(),
      products: items,
      dateTime: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : DateTime.now(),
      status: row['status'] ?? 'pending',
      shippingAddress: row['shipping_address'] ?? '',
    );
  }).toList();
});

// ---------------------------------------------------------------------------
// Place Order Use-Case
// ---------------------------------------------------------------------------

class PlaceOrderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Inserts the order + order_items into Supabase.
  /// Returns the new order ID on success.
  Future<String> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String shippingAddress,
    String? couponCode,
    double discountAmount = 0.0,
  }) async {
    state = const AsyncLoading();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('You must be logged in to place an order.');

      // 1. Insert the parent order record
      final orderRow = await Supabase.instance.client
          .from('orders')
          .insert({
            'user_id': user.id,
            'total_amount': totalAmount,
            'shipping_address': shippingAddress,
            'status': 'pending',
            'coupon_code': couponCode,
            'discount_amount': discountAmount,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final orderId = orderRow['id'].toString();

      // 2. Insert all order_items linked to this order
      final orderItems = items.map((item) => {
            'order_id': orderId,
            'product_id': item.productId,
            'name': item.name,
            'unit_price': item.price,
            'quantity': item.quantity,
            'image_url': item.imageUrl,
          }).toList();

      await Supabase.instance.client.from('order_items').insert(orderItems);

      state = const AsyncData(null);

      // Invalidate the order history so the My Orders screen refreshes
      ref.invalidateSelf();

      return orderId;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final placeOrderProvider =
    AsyncNotifierProvider<PlaceOrderNotifier, void>(PlaceOrderNotifier.new);