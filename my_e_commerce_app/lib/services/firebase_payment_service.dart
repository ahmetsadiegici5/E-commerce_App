import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart.dart';
import '../models/iyzipay/iyzipay_address.dart';
import '../models/checkout_response.dart';
import '../utils/logger.dart';

/// Firebase Cloud Functions üzerindeki ödeme API'si ile konuşur.
/// Tutar sunucuda Firestore'daki ürün fiyatlarından hesaplanır, bu yüzden
/// sadece ürün id'leri ve adetleri gönderilir.
class FirebasePaymentService {
  static const String _baseUrl = String.fromEnvironment(
    'PAYMENT_API_URL',
    defaultValue: 'https://paymentapi-4tbpbi4ulq-uc.a.run.app',
  );

  final http.Client _client;

  FirebasePaymentService({http.Client? client}) : _client = client ?? http.Client();

  static Map<String, dynamic> buildCheckoutRequest({
    required List<CartItem> items,
    required IyzipayAddress address,
  }) {
    return {
      'items': items
          .map((item) => {'productId': item.productId, 'quantity': item.quantity})
          .toList(),
      'address': {
        'address': address.fullAddress,
        'city': address.city,
        'country': address.country,
        'zipCode': address.zipCode,
      },
    };
  }

  Future<CheckoutResponse> createCheckoutForm({
    required List<CartItem> items,
    required IyzipayAddress address,
  }) async {
    try {
      final response = await _post(
        '/create-checkout-form',
        buildCheckoutRequest(items: items, address: address),
      );
      final data = _decode(response);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return CheckoutResponse.fromJson(data);
      }
      return CheckoutResponse.failure(data['errorMessage'] ?? 'Ödeme başlatılamadı');
    } catch (e) {
      Logger.error('Checkout form oluşturulamadı: $e');
      return CheckoutResponse.failure('Ödeme servisine ulaşılamadı');
    }
  }

  Future<Map<String, dynamic>> retrieveCheckoutForm(String token) async {
    try {
      final response = await _post('/retrieve-checkout-form', {'token': token});
      return _decode(response);
    } catch (e) {
      Logger.error('Ödeme sonucu alınamadı: $e');
      return {'status': 'error', 'errorMessage': 'Ödeme sonucu alınamadı'};
    }
  }

  static Map<String, dynamic> _decode(http.Response response) =>
      json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }
}
