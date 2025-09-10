import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageURL;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageURL,
  });

  double get totalPrice => price * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageURL': imageURL,
    };
  }
}

class Cart with ChangeNotifier {
  List<CartItem> _items = [];

  Cart();

  List<CartItem> get items => List.unmodifiable(_items);

  List<CartItem> get itemsList => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (total, cartItem) => total + (cartItem.price * cartItem.quantity));
  }

  void addItem({
    required String productId,
    required String name,
    required double price,
    required String imageURL,
  }) {
    final existingItemIndex = _items.indexWhere((item) => item.productId == productId);
    
    if (existingItemIndex != -1) {
      final existingItem = _items[existingItemIndex];
      _items[existingItemIndex] = CartItem(
        id: existingItem.id,
        productId: existingItem.productId,
        name: existingItem.name,
        price: existingItem.price,
        quantity: existingItem.quantity + 1,
        imageURL: existingItem.imageURL,
      );
    } else {
      _items.add(CartItem(
        id: DateTime.now().toString(),
        productId: productId,
        name: name,
        price: price,
        quantity: 1,
        imageURL: imageURL,
      ));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    final itemIndex = _items.indexWhere((item) => item.productId == productId);
    if (itemIndex == -1) return;

    final item = _items[itemIndex];
    if (item.quantity > 1) {
      _items[itemIndex] = CartItem(
        id: item.id,
        productId: item.productId,
        name: item.name,
        price: item.price,
        quantity: item.quantity - 1,
        imageURL: item.imageURL,
      );
    } else {
      _items.removeAt(itemIndex);
    }
    notifyListeners();
  }

  void clear() {
    _items = [];
    notifyListeners();
  }

  factory Cart.fromMap(Map<String, dynamic> map) {
    Cart cart = Cart();
    
    List<dynamic> items = map['items'] ?? [];
    cart._items = items.map((item) => CartItem.fromMap(item)).toList();

    return cart;
  }

  Map<String, dynamic> toMap() {
    return {
      'items': _items.map((item) => item.toMap()).toList(),
      'total': totalAmount,
    };
  }
}
