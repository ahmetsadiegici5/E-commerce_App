import 'cart.dart';
import 'user.dart' show UserAddress;

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final String status;
  final DateTime orderDate;
  final UserAddress shippingAddress;
  final String paymentMethod;
  final String trackingNumber;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.orderDate,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.trackingNumber,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: List<CartItem>.from(
          (map['items'] ?? []).map((x) => CartItem.fromMap(x))),
      total: map['total']?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      orderDate: DateTime.fromMillisecondsSinceEpoch(map['orderDate'] ?? 0),
      shippingAddress: UserAddress.fromMap(map['shippingAddress'] ?? {}),
      paymentMethod: map['paymentMethod'] ?? '',
      trackingNumber: map['trackingNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((x) => x.toMap()).toList(),
      'total': total,
      'status': status,
      'orderDate': orderDate.millisecondsSinceEpoch,
      'shippingAddress': shippingAddress.toMap(),
      'paymentMethod': paymentMethod,
      'trackingNumber': trackingNumber,
    };
  }
}
