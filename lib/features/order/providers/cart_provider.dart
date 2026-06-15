import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart_item.dart'; 

class CartNotifier extends Notifier<Map<String, CartItem>> {
  @override
  Map<String, CartItem> build() {
    return <String, CartItem>{}; 
  }

  void addItem(String productId, double price, String name, String imageUrl) {
    final newState = Map<String, CartItem>.from(state);
    
    if (newState.containsKey(productId)) {
      // Update existing item
      newState[productId] = newState[productId]!.copyWith(
        quantity: newState[productId]!.quantity + 1,
      );
    } else {
      // Add new item
      newState[productId] = CartItem(
        id: DateTime.now().toString(),
        productId: productId,
        name: name,
        price: price,
        quantity: 1,
        imageUrl: imageUrl,
      );
    }
    
    state = newState;
  }

  void removeItem(String productId) {
    final newState = Map<String, CartItem>.from(state);
    newState.remove(productId);
    state = newState;
  }

  void decrementItem(String productId) {
    if (!state.containsKey(productId)) return;
    
    final newState = Map<String, CartItem>.from(state);
    final current = newState[productId]!;
    
    if (current.quantity <= 1) {
      newState.remove(productId);
    } else {
      newState[productId] = current.copyWith(quantity: current.quantity - 1);
    }
    
    state = newState;
  }
  void clearCart() {
    state = <String, CartItem>{};
  }

  double get totalAmount {
    return state.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }
}

// This is your global provider
final cartProvider = NotifierProvider<CartNotifier, Map<String, CartItem>>(() {
  return CartNotifier();
});