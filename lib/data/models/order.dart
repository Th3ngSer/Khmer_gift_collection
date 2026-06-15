import 'cart_item.dart';

class OrderModel {
  final String id;
  final double totalAmount;
  final List<CartItem> products;
  final DateTime dateTime;
  final String status; // 'Pending', 'Processing', 'Delivered'
  final String shippingAddress;

  OrderModel({
    required this.id,
    required this.totalAmount,
    required this.products,
    required this.dateTime,
    required this.shippingAddress,
    this.status = 'Pending',
  });
}