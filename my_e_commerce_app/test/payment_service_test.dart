import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_e_commerce_app/models/cart.dart';
import 'package:my_e_commerce_app/models/iyzipay/iyzipay_address.dart';
import 'package:my_e_commerce_app/models/product.dart';
import 'package:my_e_commerce_app/services/firebase_payment_service.dart';

void main() {
  final address = IyzipayAddress(
    id: '1',
    title: 'Ev',
    fullAddress: 'Atatürk Mah. No:1',
    latitude: 0,
    longitude: 0,
    city: 'İstanbul',
  );

  final items = [
    CartItem(id: 'c1', productId: 'p1', name: 'Kalem', price: 10, quantity: 2, imageURL: ''),
  ];

  test('ödeme isteğine fiyat değil sadece ürün id ve adet eklenir', () {
    final request = FirebasePaymentService.buildCheckoutRequest(items: items, address: address);

    expect(request['items'], [
      {'productId': 'p1', 'quantity': 2}
    ]);
    expect(request.toString(), isNot(contains('price')));
    expect((request['address'] as Map)['city'], 'İstanbul');
  });

  test('başarılı yanıt CheckoutResponse olarak döner', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/create-checkout-form');
      return http.Response(
        json.encode({'status': 'success', 'token': 't1', 'paymentPageUrl': 'https://pay'}),
        200,
      );
    });

    final response = await FirebasePaymentService(client: client)
        .createCheckoutForm(items: items, address: address);

    expect(response.isSuccess, isTrue);
    expect(response.directCheckoutUrl, 'https://pay');
  });

  test('sunucu hatası kullanıcıya mesaj olarak döner', () async {
    final client = MockClient((_) async => http.Response.bytes(
          utf8.encode(json.encode({'status': 'error', 'errorMessage': 'Ürün bulunamadı: p1'})),
          400,
        ));

    final response = await FirebasePaymentService(client: client)
        .createCheckoutForm(items: items, address: address);

    expect(response.isSuccess, isFalse);
    expect(response.errorMessage, 'Ürün bulunamadı: p1');
  });

  test('Product.fromMap tırnaklı URL ve int fiyatı düzeltir', () {
    final product = Product.fromMap({'name': 'Kalem', 'price': 10, 'imageURL': '"https://img"'}, id: 'p1');

    expect(product.id, 'p1');
    expect(product.price, 10.0);
    expect(product.imageURL, 'https://img');
  });
}
