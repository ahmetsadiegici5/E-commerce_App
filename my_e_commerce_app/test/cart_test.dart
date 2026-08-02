import 'package:flutter_test/flutter_test.dart';

import 'package:my_e_commerce_app/models/cart.dart';

void main() {
  group('Cart', () {
    late Cart cart;

    setUp(() => cart = Cart());

    test('aynı ürün tekrar eklenince miktarı artar', () {
      cart.addItem(productId: 'p1', name: 'Kalem', price: 10, imageURL: '');
      cart.addItem(productId: 'p1', name: 'Kalem', price: 10, imageURL: '');

      expect(cart.itemCount, 1);
      expect(cart.items.single.quantity, 2);
      expect(cart.totalAmount, 20);
    });

    test('farklı ürünler toplam tutara eklenir', () {
      cart.addItem(productId: 'p1', name: 'Kalem', price: 10, imageURL: '');
      cart.addItem(productId: 'p2', name: 'Defter', price: 25.5, imageURL: '');

      expect(cart.itemCount, 2);
      expect(cart.totalAmount, 35.5);
    });

    test('removeSingleItem miktarı azaltır, son adette ürünü siler', () {
      cart.addItem(productId: 'p1', name: 'Kalem', price: 10, imageURL: '');
      cart.addItem(productId: 'p1', name: 'Kalem', price: 10, imageURL: '');

      cart.removeSingleItem('p1');
      expect(cart.items.single.quantity, 1);

      cart.removeSingleItem('p1');
      expect(cart.itemCount, 0);
    });

    test('toMap / fromMap sepeti korur', () {
      cart.addItem(productId: 'p1', name: 'Kalem', price: 10, imageURL: 'u');
      final restored = Cart.fromMap(cart.toMap());

      expect(restored.itemCount, 1);
      expect(restored.items.single.name, 'Kalem');
      expect(restored.totalAmount, cart.totalAmount);
    });
  });
}
