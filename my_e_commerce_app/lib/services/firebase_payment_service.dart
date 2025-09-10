import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart.dart';
import '../models/payment_card.dart';
import '../models/iyzipay/iyzipay_models.dart';
import '../models/iyzipay/iyzipay_address.dart';
import '../models/checkout_response.dart';
import '../utils/logger.dart';

class FirebasePaymentService {
  // Firebase Cloud Functions endpoint
  final String _baseUrl = 'https://paymentapi-4tbpbi4ulq-uc.a.run.app';
  
  // Checkout form sonucunu doğrulama (CF-Retrieve)
  Future<Map<String, dynamic>> retrieveCheckoutForm(String token, {String? conversationId}) async {
    try {
      Logger.debug('Checkout form retrieve başlatılıyor. Token: $token');
      final request = {
        'token': token,
        if (conversationId != null) 'conversationId': conversationId,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/retrieve-checkout-form'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request),
      );
      Logger.debug('Retrieve HTTP Status: ${response.statusCode}');
      Logger.debug('Retrieve Body: ${response.body}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'status': 'error',
        'errorMessage': 'HTTP ${response.statusCode}',
        'raw': response.body
      };
    } catch (e) {
      Logger.error('Checkout form retrieve hatası: $e');
      return {
        'status': 'error',
        'errorMessage': e.toString()
      };
    }
  }
  
  // Checkout Form için token alma
  Future<CheckoutResponse> getCheckoutFormToken({
    required String userId,
    required List<CartItem> items,
    required double totalAmount,
    required IyzipayAddress billingAddress,
    required IyzipayAddress shippingAddress,
  }) async {
    try {
      Logger.debug('====== CHECKOUT FORM İSTEĞİ BAŞLANGICI ======');
      Logger.debug('Checkout Form token alınıyor');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final conversationId = "conv_$timestamp";
      
      final request = {
        'locale': Locale.tr.value(),
        'conversationId': conversationId,
        'price': totalAmount.toString(),
        'paidPrice': totalAmount.toString(),
        'currency': Currency.tryy.value(),
        'basketId': 'B$timestamp',
        'paymentGroup': PaymentGroup.product.value(),
        'buyer': _createBuyer(userId),
        'shippingAddress': _formatAddress(shippingAddress),
        'billingAddress': _formatAddress(billingAddress),
        'basketItems': _createBasketItems(items),
  // ÖNEMLİ: Cloud Functions backend ile eşleşen HTTPS callback URL
  'callbackUrl': 'https://myproject-a52ae.web.app/payment-result',
      };

      Logger.debug('Firebase Functions endpoint: $_baseUrl/create-checkout-form');
      Logger.debug('Gönderilen checkout form isteği: ${json.encode(request)}');
      Logger.debug('====== CHECKOUT FORM İSTEĞİ SONU ======');

      final response = await http.post(
        Uri.parse('$_baseUrl/create-checkout-form'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request),
      );

      Logger.debug('====== CHECKOUT FORM YANITI BAŞLANGICI ======');
      Logger.debug('HTTP Status Code: ${response.statusCode}');
      Logger.debug('Response Headers: ${response.headers}');
      Logger.debug('Response Body: ${response.body}');
      Logger.debug('====== CHECKOUT FORM YANITI SONU ======');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        Logger.debug('====== ANALİZ BAŞLANGICI ======');
        Logger.debug('Response status: ${responseData['status']}');
        Logger.debug('Error message: ${responseData['errorMessage']}');
        Logger.debug('Error code: ${responseData['errorCode']}');
        Logger.debug('Token: ${responseData['token']}');
        Logger.debug('PaymentPageUrl: ${responseData['paymentPageUrl']}');
        
        if (responseData['checkoutFormContent'] != null) {
          final content = responseData['checkoutFormContent'] as String;
          Logger.debug('Checkout form content length: ${content.length}');
          Logger.debug('Content preview (first 200 chars): ${content.length > 200 ? content.substring(0, 200) : content}');
          
          // İçeriğin gerçek İyzico formu olup olmadığını kontrol et
          if (content.contains('script') || content.contains('iyziInit') || content.contains('iyzipay')) {
            Logger.debug('[✅] GERÇEİZICO FORM TESPİT EDİLDİ - İçerik gerçek İyzico script içeriyor');
          } else if (content.contains('Ödeme Başarılı') || content.contains('Payment ID')) {
            Logger.debug('[❌] SAHTE TEST VERİSİ TESPİT EDİLDİ - İçerik test mesajı içeriyor');
          } else {
            Logger.debug('[⚠️] BİLİNMEYEN İÇERİK - İçerik analiz edilemiyor');
          }
        }
        Logger.debug('====== ANALİZ SONU ======');
        
        if (responseData['status'] == 'success') {
          return CheckoutResponse.fromJson(responseData);
        } else {
          return CheckoutResponse(
            checkoutFormContent: '',
            isSuccess: false,
            errorMessage: responseData['errorMessage'] ?? 'Checkout form oluşturulamadı',
          );
        }
      } else {
        Logger.error('HTTP hatası: ${response.statusCode} - ${response.body}');
        return CheckoutResponse(
          checkoutFormContent: '',
          isSuccess: false,
          errorMessage: 'HTTP hatası: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      Logger.error('Checkout form token alma hatası: $e');
      return CheckoutResponse(
        checkoutFormContent: '',
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Standart ödeme işlemi
  Future<PaymentResult> processPayment({
    required String userId,
    required List<CartItem> items,
    required double totalAmount,
    required IyzipayAddress billingAddress,
    required IyzipayAddress shippingAddress,
  }) async {
    try {
      Logger.debug('Firebase Cloud Functions üzerinden ödeme işlemi başlatılıyor');
      
      // İyzipay için özel conversationId oluşturalım
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final conversationId = "conv_$timestamp";
      
      // Ödeme isteği oluştur - özellikle installment değerinin doğru formatta olduğundan emin olalım
      final request = {
        'locale': Locale.tr.value(),
        'conversationId': conversationId,
        'price': totalAmount.toString(),
        'paidPrice': totalAmount.toString(),
        'currency': Currency.tryy.value(),
        'installment': 1,  // Kesinlikle integer olarak gönderiyoruz
        // Artık sadece "installment" değeri gönderiyoruz, nodejs tarafı bunu kontrol edecek
        'basketId': 'B$timestamp',
        'paymentChannel': PaymentChannel.web.value(),
        'paymentGroup': PaymentGroup.product.value(),
        'buyer': _createBuyer(userId),
        // İyzipay için uygun formatta adres bilgilerini gönder
        'shippingAddress': _formatAddress(shippingAddress),
        'billingAddress': _formatAddress(billingAddress),
        'basketItems': _createBasketItems(items),
      };

      // İstek gövdesini oluştur
      final String requestBody = json.encode(request);
      
      // Gönderilen JSON gövdesini detaylı logla
      Logger.debug('====== ÖDEME İSTEĞİ BAŞLANGICI ======');
      Logger.debug('Ödeme isteği URL: $_baseUrl/create-payment');
      Logger.debug('Ödeme isteği gövdesi: $requestBody');
      
      // Önemli alan değerlerini tek tek kontrol et
      Logger.debug('--- Önemli alan kontrolü ---');
      Logger.debug('locale: ${Locale.tr.value()}');
      Logger.debug('conversationId: $conversationId');
      Logger.debug('price: ${totalAmount.toString()}');
      Logger.debug('paidPrice: ${totalAmount.toString()}');
      Logger.debug('currency: ${Currency.tryy.value()}');
      Logger.debug('installment: 1');
      Logger.debug('====== ÖDEME İSTEĞİ SONU ======');
      
      // Firebase Functions endpoint'ine istek gönder
      final response = await http.post(
        Uri.parse('$_baseUrl/create-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );
      
      Logger.debug('====== ÖDEME YANITI BAŞLANGICI ======');
      Logger.debug('Firebase Functions Yanıt Kodu: ${response.statusCode}');
      Logger.debug('Firebase Functions Yanıt: ${response.body}');
      Logger.debug('====== ÖDEME YANITI SONU ======');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        Logger.debug('====== API YANIT ANALİZİ ======');
        Logger.debug('API yanıt durum: ${responseData['status']}');
        if (responseData['errorMessage'] != null) {
          Logger.debug('API hata mesajı: ${responseData['errorMessage']}');
        }
        if (responseData['errorCode'] != null) {
          Logger.debug('API hata kodu: ${responseData['errorCode']}');
        }
        if (responseData['errorDetails'] != null) {
          Logger.debug('API hata detayları: ${responseData['errorDetails']}');
        }
        
        if (responseData['status'] == 'success') {
          Logger.debug('Ödeme başarılı, paymentId: ${responseData['paymentId']}');
          return PaymentResult(
            success: true,
            transactionId: responseData['paymentId'],
            message: 'Ödeme başarıyla tamamlandı'
          );
        } else {
          Logger.error('Ödeme işlemi başarısız. Hata: ${responseData['errorMessage'] ?? 'Bilinmeyen hata'}');
          return PaymentResult(
            success: false,
            message: responseData['errorMessage'] ?? 'Ödeme işlemi başarısız'
          );
        }
      } else {
        Logger.error('Firebase Functions API Hatası: ${response.statusCode}');
        Logger.error('Yanıt detayı: ${response.body}');
        
        try {
          // Eğer body JSON ise detaylı hata bilgisi çıkarmaya çalış
          final errorData = json.decode(response.body);
          Logger.error('Hata detayı: ${errorData['errorDetails'] ?? 'Detay yok'}');
        } catch (e) {
          // JSON parse hatası, düz metin olarak içeriği göster
          Logger.error('Ham yanıt içeriği: ${response.body}');
        }
        
        return PaymentResult(
          success: false,
          message: 'Ödeme API hatası: HTTP ${response.statusCode}'
        );
      }
    } catch (e) {
      Logger.error('Ödeme Servisi Genel Hatası: $e');
      return PaymentResult(
        success: false,
        message: 'Bir hata oluştu: ${e.toString()}'
      );
    }
  }
  
  // 3D Secure ödeme başlatma
  Future<Map<String, dynamic>> initialize3DSecurePayment({
    required String userId,
    required List<CartItem> items,
    required double totalAmount,
    required PaymentCard card,
    required IyzipayAddress billingAddress,
    required IyzipayAddress shippingAddress,
    required String callbackUrl,
  }) async {
    try {
      Logger.debug('Firebase Cloud Functions üzerinden 3D Secure ödeme başlatılıyor');
      
      // İyzipay için özel conversationId oluşturalım
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final conversationId = "conv_$timestamp";
      
      // Ödeme isteği oluştur
      final request = {
        'locale': Locale.tr.value(),
        'conversationId': conversationId,
        'price': totalAmount.toString(),
        'paidPrice': totalAmount.toString(),
        'currency': Currency.tryy.value(),
        'installment': 1,
        'basketId': 'B$timestamp',
        'paymentChannel': PaymentChannel.web.value(),
        'paymentGroup': PaymentGroup.product.value(),
        'paymentCard': card.toJson(),
        'buyer': _createBuyer(userId),
        // İyzipay için uygun formatta adres bilgilerini gönder
        'shippingAddress': _formatAddress(shippingAddress),
        'billingAddress': _formatAddress(billingAddress),
        'basketItems': _createBasketItems(items),
        'callbackUrl': callbackUrl,
      };

      // İstek gövdesini oluştur
      final String requestBody = json.encode(request);
      Logger.debug('3D Secure isteği gövdesi: $requestBody');
      
      // Firebase Functions endpoint'ine istek gönder
      final response = await http.post(
        Uri.parse('$_baseUrl/initialize-3ds'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );
      
      Logger.debug('Firebase Functions 3DS Yanıt Kodu: ${response.statusCode}');
      Logger.debug('Firebase Functions 3DS Yanıt: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        Logger.error('Firebase Functions 3DS API Hatası: ${response.statusCode}');
        return {
          'status': 'error',
          'errorMessage': 'HTTP ${response.statusCode} hatası'
        };
      }
    } catch (e) {
      Logger.error('3D Secure Başlatma Hatası: $e');
      return {
        'status': 'error',
        'errorMessage': e.toString()
      };
    }
  }
  
  // 3D Secure ödeme tamamlama
  Future<PaymentResult> complete3DSecurePayment({
    required String paymentId,
    required String conversationId,
  }) async {
    try {
      Logger.debug('Firebase Cloud Functions üzerinden 3D Secure ödeme tamamlanıyor');
      
      // Ödeme isteği oluştur
      final request = {
        'locale': Locale.tr.value(),
        'conversationId': conversationId,
        'paymentId': paymentId,
      };

      // İstek gövdesini oluştur
      final String requestBody = json.encode(request);
      Logger.debug('3D Secure tamamlama isteği gövdesi: $requestBody');
      
      // Firebase Functions endpoint'ine istek gönder
      final response = await http.post(
        Uri.parse('$_baseUrl/complete-3ds'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );
      
      Logger.debug('Firebase Functions 3DS Tamamlama Yanıt Kodu: ${response.statusCode}');
      Logger.debug('Firebase Functions 3DS Tamamlama Yanıt: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'success') {
          return PaymentResult(
            success: true,
            transactionId: responseData['paymentId'],
            message: '3D Secure ödeme başarıyla tamamlandı'
          );
        } else {
          return PaymentResult(
            success: false,
            message: responseData['errorMessage'] ?? '3D Secure ödeme işlemi başarısız'
          );
        }
      } else {
        Logger.error('Firebase Functions 3DS Tamamlama API Hatası: ${response.statusCode}');
        return PaymentResult(
          success: false,
          message: '3D Secure tamamlama API hatası: HTTP ${response.statusCode}'
        );
      }
    } catch (e) {
      Logger.error('3D Secure Tamamlama Hatası: $e');
      return PaymentResult(
        success: false,
        message: 'Bir hata oluştu: ${e.toString()}'
      );
    }
  }

  // Buyer JSON'u oluştur
  Map<String, dynamic> _createBuyer(String userId) {
    return {
      'id': userId,
      'name': "John",
      'surname': "Doe",
      'identityNumber': "74300864791",
      'email': "email@email.com",
      'registrationAddress': "Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1",
      'city': "Istanbul",
      'country': "Turkey",
      'ip': "85.34.78.112"
    };
  }
  
  // Iyzipay için adres formatını düzenleme
  Map<String, dynamic> _formatAddress(IyzipayAddress address) {
    // İyzipay'in beklediği formata uygun adres nesnesi
    return {
      'address': address.fullAddress,      // address alanı gerekli
      'zipCode': address.zipCode,          // zipCode yerine 'zip' de olabilir
      'contactName': 'John Doe',           // contactName gerekli
      'city': address.city,                // city zorunlu
      'country': address.country,          // country zorunlu
    };
  }

  // Sepet öğelerini JSON'a çevir
  List<Map<String, dynamic>> _createBasketItems(List<CartItem> items) {
    return items.map((item) => {
      'id': item.id,
      'name': item.name,
      'category1': "Genel",
      'itemType': BasketItemType.physical.value(),
      'price': (item.price * item.quantity).toString()
    }).toList();
  }
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;

  PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
  });
}
