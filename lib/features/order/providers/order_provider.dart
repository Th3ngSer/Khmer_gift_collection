import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/order.dart';
import '../../../data/models/cart_item.dart';

class OrderNotifier extends Notifier<List<OrderModel>> {
  @override
  List<OrderModel> build() {
    return []; 
  }

  Future<void> placeOrder(List<CartItem> cartProducts, double total, String address) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Insert order into Supabase
      final orderId = DateTime.now().toString();
      await supabase.from('orders').insert({
        'id': orderId,
        'customer_id': currentUser.id,
        'total_amount': total,
        'shipping_address': address,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insert order items (optional, if you have order_items table)
      // for (var item in cartProducts) {
      //   await supabase.from('order_items').insert({
      //     'order_id': orderId,
      //     'product_id': item.productId,
      //     'quantity': item.quantity,
      //     'unit_price': item.price,
      //     'total_price': item.price * item.quantity,
      //   });
      // }

      // Store locally as well
      final newOrder = OrderModel(
        id: orderId,
        totalAmount: total,
        products: cartProducts,
        dateTime: DateTime.now(),
        shippingAddress: address,
      );
      
      state = [newOrder, ...state];
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }
}

final orderProvider = NotifierProvider<OrderNotifier, List<OrderModel>>(() {
  return OrderNotifier();
});