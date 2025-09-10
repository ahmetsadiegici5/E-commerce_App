import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/payment_card.dart';
import '../models/iyzipay/iyzipay_models.dart';
import '../models/iyzipay/iyzipay_address.dart';
import '../utils/logger.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  // Güvenli API bilgileri ve ödeme ayarları
  final String _baseUrl = 'https://sandbox-api.iyzipay.com';
  
  // API Key ve Secret Key - İyzipay panelinden alınan doğru değerlerle güncellendi
  final String _apiKey = 'sandbox-REMOVED'; // İyzipay panelinden alınan API Key
  final String _secretKey = 'sandbox-REMOVED'; // İyzipay panelinden alınan Secret Key

  // Iyzipay HMAC-SHA1 imzalama yöntemi (İyzipay dokümanındaki resmi yönteme göre)
  String _generateAuthToken(String randomString, String body) {
    // İyzipay dokümantasyonuna göre imza oluşturma sırası: apiKey + randomString + secretKey + body
    String hashStr = '$_apiKey$randomString$_secretKey';
    
    // Body varsa ekle
    if (body.isNotEmpty) {
      hashStr = hashStr + body;
    }

    // HMAC-SHA1 imzası oluştur
    final hmacSha1 = Hmac(sha1, utf8.encode(_secretKey)).convert(utf8.encode(hashStr));
    
    // Base64 kodlama
    final sign = base64.encode(hmacSha1.bytes);
    
    Logger.debug('========= HMAC İmza Detayları =========');
    Logger.debug('- Random String: $randomString');
    Logger.debug('- API Key: ${_apiKey.substring(0, 10)}...');
    Logger.debug('- Secret Key: ${_secretKey.substring(0, 5)}...');
    Logger.debug('- İmza: $sign');
    Logger.debug('- Request Body Uzunluğu: ${body.length}');
    Logger.debug('- Payload Hash: $hashStr');
    Logger.debug('=========================================');
    
    return sign;
  }

  // Headers hazırlama
  Map<String, String> _prepareHeaders({required String randomString, String body = ''}) {
    final signature = _generateAuthToken(randomString, body);
    
        // İyzipay'in beklediği formatta Authorization header'ı oluştur
    // Format: 'IYZWS apiKey:randomString:signature'
    final authHeader = 'IYZWS $_apiKey:$randomString:$signature';
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': authHeader,
      'x-iyzi-rnd': randomString, // İyzipay'in resmi dokümantasyonuna göre header'a randomString eklenmelidir
    };
    
    Logger.debug('Oluşturulan Authorization header: IYZWS apiKey:*****:$signature');
    Logger.debug('x-iyzi-rnd: $randomString');    Logger.debug('Headers hazırlandı:');
    Logger.debug('- Content-Type: application/json');
    Logger.debug('- Accept: application/json');
    Logger.debug('- Authorization formatı: IYZWS apiKey:randomString:signature');
    Logger.debug('- x-iyzi-rnd: $randomString');
    
    return headers;
  }
  
  // Rastgele string oluşturma metodu
  String generateRandomString([int length = 8]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length, 
        (_) => chars.codeUnitAt(random.nextInt(chars.length))
      )
    );
  }

  // API bağlantı testi - basitleştirilmiş ve güvenilir test
  Future<bool> testConnection() async {
    try {
      // İyzipay test endpoint'ini kullanalım - kimlik doğrulama olmadan da çalışır
      final testUrl = '$_baseUrl/payment/test';
      Logger.debug('API bağlantı testi yapılıyor: $testUrl');
      
      // Basit bir GET isteği gönder (kimlik doğrulama gerektirmiyor)
      final response = await http.get(
        Uri.parse(testUrl),
      ).timeout(const Duration(seconds: 15));
      
      Logger.debug('Bağlantı Test Yanıt Kodu: ${response.statusCode}');
      Logger.debug('Bağlantı Test Yanıt: ${response.body}');
      
      // Yanıtı kontrol et - başarılı ise "success" içermeli
      final isSuccess = response.statusCode == 200 && 
                       response.body.contains('success');
      
      if (isSuccess) {
        Logger.debug('İyzipay API bağlantısı başarılı!');
      } else {
        Logger.error('İyzipay API yanıt verdi ancak başarısız: ${response.body}');
      }
      
      return isSuccess;
    } catch (e) {
      Logger.error('Bağlantı hatası: $e');
      // İnternet bağlantısını ping testi ile kontrol edelim
      try {
        Logger.debug('İnternet bağlantısı alternatif kontrol yapılıyor: ping testi');
        final pingResponse = await http.get(
          Uri.parse('https://www.google.com'),
        ).timeout(const Duration(seconds: 5));
        
        if (pingResponse.statusCode >= 200 && pingResponse.statusCode < 300) {
          Logger.debug('İnternet bağlantısı var, ancak İyzipay API\'ye erişilemiyor');
        }
      } catch (pingError) {
        Logger.error('İnternet bağlantısı testi de başarısız: $pingError');
      }
      return false;
    }
  }


  // Iyzipay için adres formatını düzenleme
  Map<String, dynamic> _formatAddress(IyzipayAddress address) {
    // İyzipay'in beklediği formata uygun adres nesnesi
    // Null değer olmadığından emin ol, varsayılan değerler kullan
    final String city = address.city.isEmpty ? 'Istanbul' : address.city;
    final String country = address.country.isEmpty ? 'Turkey' : address.country;
    final String zipCode = address.zipCode.isEmpty ? '34000' : address.zipCode;
    
    return {
      'address': address.fullAddress,      // address alanı gerekli
      'zipCode': zipCode,                  // zipCode yerine 'zip' de olabilir
      'contactName': 'John Doe',           // contactName gerekli
      'city': city,                        // city zorunlu
      'country': country,                  // country zorunlu
    };
  }

  Future<PaymentResult> processPayment({
    required String userId,
    required List<dynamic> items, // Farklı CartItem türlerini kabul etmek için dynamic kullanılıyor
    required double totalAmount,
    required PaymentCard card,
    required IyzipayAddress billingAddress,
    required IyzipayAddress shippingAddress,
  }) async {
    try {
      // Random string oluştur - İyzipay API'si için zorunlu
      // Eşsiz bir randomString oluşturalım (kısa ve temiz formatla)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomString = generateRandomString();
      Logger.debug('randomString oluşturuldu: $randomString');
      
      // İyzipay için özel conversationId oluşturalım
      final conversationId = "conv_$timestamp";
      Logger.debug('conversationId oluşturuldu: $conversationId');

      // API anahtarlarını kontrol et
      Logger.debug('API Key: $_apiKey');
      Logger.debug('Secret Key: ${_secretKey.substring(0, 8)}...'); // Güvenlik için tamamı gösterilmiyor
      
      // Ödeme işlemini gerçekleştir
      try {
        // Doğrudan manuel json oluşturuyoruz - tüm alanları açıkça belirtiyoruz
        // Böylece CreatePaymentRequest sınıfında tip dönüşümlerinden kaynaklanan hataları önlüyoruz
        
        // İstek gövdesi için bir JSON objesi oluşturuyoruz
        final Map<String, dynamic> requestJson = {
          'locale': Locale.tr.value(),
          'conversationId': conversationId,
          'price': totalAmount.toString(),
          'paidPrice': totalAmount.toString(),
          'currency': Currency.tryy.value(),
          'installment': 1, // Tamsayı olarak sabit değer
          'basketId': 'B$timestamp',
          'paymentChannel': kIsWeb ? PaymentChannel.web.value() : PaymentChannel.mobile.value(),
          'paymentGroup': PaymentGroup.product.value(),
          'paymentCard': {
            'cardHolderName': card.cardHolderName,
            'cardNumber': card.cardNumber.replaceAll(' ', ''),
            'expireMonth': card.expireMonth,
            'expireYear': card.expireYear.length > 2 ? card.expireYear.substring(card.expireYear.length - 2) : card.expireYear,
            'cvc': card.cvc,
            'registerCard': card.registerCard,
          },
          'buyer': _createBuyer(userId),
          'shippingAddress': _formatAddress(shippingAddress),
          'billingAddress': _formatAddress(billingAddress),
          'basketItems': items.map((item) => {
            'id': item.id,
            'name': item.name,
            'category1': 'Genel',
            'itemType': BasketItemType.physical.value(),
            'price': (item.price * item.quantity).toString()
          }).toList(),
        };
        
        // Debug için yazdır
        Logger.debug('Ödeme isteği JSON: ${json.encode(requestJson)}');
        
        // İzipay API'ye gitmeden önce tüm kritik değerleri kontrol et
        Logger.debug('Kritik değerler:');
        Logger.debug('- price: ${requestJson['price']}');
        Logger.debug('- paidPrice: ${requestJson['paidPrice']}');
        Logger.debug('- installment: ${requestJson['installment']} (${requestJson['installment'].runtimeType})');
        Logger.debug('- basketId: ${requestJson['basketId']}');
        Logger.debug('- billingAddress.city: ${requestJson['billingAddress']['city']}');
        Logger.debug('- shippingAddress.city: ${requestJson['shippingAddress']['city']}');
        
        // Detaylı JSON dump yap
        _dumpRequestJson(requestJson);
        
        // İstek gövdesi için JSON kodlaması
        final requestBody = json.encode(requestJson);
        Logger.debug('Manuel oluşturulan JSON gövdesi: $requestBody');
        
        // İstek gövdesini kullanarak özel header'lar oluştur
        final requestHeaders = _prepareHeaders(randomString: randomString, body: requestBody);
        
        // İyzipay API'ye istek gönderirken baseUrl'i de ekleyelim
        requestHeaders['baseUrl'] = _baseUrl;
        // Böylece CreatePaymentRequest sınıfında tip dönüşümlerinden kaynaklanan hataları önlüyoruz
        
        // İstek gönderme
        final response = await http.post(
          Uri.parse('$_baseUrl/payment/auth'),
          headers: requestHeaders,
          body: requestBody,
        );
        
        Logger.debug('Ödeme API yanıtı: ${response.statusCode}, Yanıt: ${response.body}');
        
        // Yanıtı işleme
        var responseData = json.decode(response.body);
        Payment payment;
        
        if (response.statusCode == 200) {
          payment = Payment(
            status: responseData['status'] ?? 'error',
            errorMessage: responseData['errorMessage'],
            paymentId: responseData['paymentId'],
          );
        } else {
          throw Exception('Ödeme API hatası: ${response.statusCode} - ${response.body}');
        }

        if (payment.status == 'success') {
          if (!kIsWeb) {
            // Mobil platformda, ödeme URL'sini mobil ödeme servisine yönlendir
            // Not: Context gerekli olduğu için bu kısım checkout screen'den çağrılmalı
            Logger.debug('Mobil ödeme için paymentPageUrl: ${responseData['paymentPageUrl']}');
          }
          
          return PaymentResult(
            success: true,
            transactionId: payment.paymentId,
            message: 'Ödeme başarıyla tamamlandı',
            paymentUrl: responseData['paymentPageUrl']
          );
        } else {
          return PaymentResult(
            success: false,
            message: payment.errorMessage ?? 'Ödeme işlemi başarısız'
          );
        }
      } catch (paymentError) {
        Logger.error('Ödeme API Hatası: $paymentError');
        return PaymentResult(
          success: false,
          message: 'Ödeme API hatası: ${paymentError.toString()}'
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

  // Test amaçlı JSON dump metodu
  void _dumpRequestJson(Map<String, dynamic> requestJson) {
    try {
      final String jsonDump = json.encode(requestJson);
      Logger.debug('************************');
      Logger.debug('JSON REQUEST DUMP:');
      Logger.debug(jsonDump);
      Logger.debug('************************');
      
      // Type kontrolleri yaparak özellikle kritik alanların tipini kontrol et
      Logger.debug('TİP KONTROLLERİ:');
      Logger.debug('installment tipi: ${requestJson['installment'].runtimeType}');
      Logger.debug('price tipi: ${requestJson['price'].runtimeType}');
      Logger.debug('paidPrice tipi: ${requestJson['paidPrice'].runtimeType}');
      Logger.debug('************************');
    } catch (e) {
      Logger.error('JSON dump hatası: $e');
    }
  }
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;
  final String? paymentUrl;

  PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
    this.paymentUrl,
  });
}
