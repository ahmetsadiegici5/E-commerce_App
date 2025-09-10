import 'dart:convert';
import 'package:http/http.dart' as http;
import '../payment_card.dart';
import './iyzipay_address.dart';
import '../../utils/logger.dart';

enum Locale {
  tr,
  en;

  String value() {
    return toString().split('.').last.toLowerCase();
  }
}

enum Currency {
  tryy, // "try" kelimesi Dart'ta anahtar kelime olduğu için "tryy" olarak değiştirdim
  usd,
  eur,
  gbp,
  irr;

  String value() {
    // API'ye gönderilirken orijinal değerleri koruyacak şekilde özel işlem
    switch (this) {
      case Currency.tryy:
        return 'TRY';
      default:
        return toString().split('.').last.toUpperCase();
    }
  }
}

enum PaymentChannel {
  mobile,
  web,
  mobileWeb,
  mobileIos,
  mobileAndroid,
  mobileWindows,
  mobileTablet,
  mobilePhone;

  String value() {
    // API'ye gönderilirken orijinal değerleri koruyacak şekilde özel işlem
    switch (this) {
      case PaymentChannel.mobileWeb:
        return 'MOBILE_WEB';
      case PaymentChannel.mobileIos:
        return 'MOBILE_IOS';
      case PaymentChannel.mobileAndroid:
        return 'MOBILE_ANDROID';
      case PaymentChannel.mobileWindows:
        return 'MOBILE_WINDOWS';
      case PaymentChannel.mobileTablet:
        return 'MOBILE_TABLET';
      case PaymentChannel.mobilePhone:
        return 'MOBILE_PHONE';
      default:
        return toString().split('.').last.toUpperCase();
    }
  }
}

enum PaymentGroup {
  product,
  listing,
  subscription;

  String value() {
    return toString().split('.').last.toUpperCase();
  }
}

enum BasketItemType {
  physical,
  virtual;

  String value() {
    return toString().split('.').last.toUpperCase();
  }
}

class CreatePaymentRequest {
  final String locale;
  final String conversationId;
  final String price;
  final String paidPrice;
  final String currency;
  final int installment;
  final String basketId;
  final String paymentChannel;
  final String paymentGroup;
  final PaymentCard paymentCard;
  final Buyer buyer;
  final IyzipayAddress shippingAddress;
  final IyzipayAddress billingAddress;
  final List<BasketItem> basketItems;

  CreatePaymentRequest({
    required this.locale,
    required this.conversationId,
    required this.price,
    required this.paidPrice,
    required this.currency,
    required this.installment,
    required this.basketId,
    required this.paymentChannel,
    required this.paymentGroup,
    required this.paymentCard,
    required this.buyer,
    required this.shippingAddress,
    required this.billingAddress,
    required this.basketItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'locale': locale,
      'conversationId': conversationId,
      'price': price,
      'paidPrice': paidPrice,
      'currency': currency,
      'installment': installment,
      'basketId': basketId,
      'paymentChannel': paymentChannel,
      'paymentGroup': paymentGroup,
      'paymentCard': paymentCard.toJson(),
      'buyer': buyer.toJson(),
      'shippingAddress': shippingAddress.toMap(),
      'billingAddress': billingAddress.toMap(),
      'basketItems': basketItems.map((item) => item.toJson()).toList(),
    };
  }
}

class Buyer {
  final String id;
  final String name;
  final String surname;
  final String identityNumber;
  final String email;
  final String registrationAddress;
  final String city;
  final String country;
  final String ip;

  Buyer({
    required this.id,
    required this.name,
    required this.surname,
    required this.identityNumber,
    required this.email,
    required this.registrationAddress,
    required this.city,
    required this.country,
    required this.ip,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'identityNumber': identityNumber,
      'email': email,
      'registrationAddress': registrationAddress,
      'city': city,
      'country': country,
      'ip': ip,
    };
  }
}

class BasketItem {
  final String id;
  final String name;
  final String category1;
  final String itemType;
  final String price;

  BasketItem({
    required this.id,
    required this.name,
    required this.category1,
    required this.itemType,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category1': category1,
      'itemType': itemType,
      'price': price,
    };
  }
}

class Payment {
  final String status;
  final String? paymentId;
  final String? errorMessage;

  Payment({
    required this.status,
    this.paymentId,
    this.errorMessage,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      status: json['status'],
      paymentId: json['paymentId'],
      errorMessage: json['errorMessage'],
    );
  }

  static Future<Payment> create(CreatePaymentRequest request, Map<String, String> headers) async {
    final baseUrl = headers['baseUrl'] ?? 'https://sandbox-api.iyzipay.com';
    final url = '$baseUrl/payment/auth';
    
    // Web ortamında CORS hatasını önlemek için Access-Control-Allow-Origin header'ı ekleyelim
    final Map<String, String> iyzipayHeaders = {
      'Accept': headers['Accept'] ?? 'application/json',
      'Content-Type': headers['Content-Type'] ?? 'application/json',
      'Authorization': headers['Authorization'] ?? '',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization'
    };
    
    // Request içerisindeki adres bilgilerini kontrol edelim
    var requestMap = request.toJson();
    
    // ShippingAddress'i kontrol et
    if (requestMap['shippingAddress'] is Map) {
      if (requestMap['shippingAddress']['city'] == null || 
          requestMap['shippingAddress']['city'].toString().isEmpty) {
        throw Exception("Shipping address city boş olamaz.");
      }
    }
    
    // BillingAddress'i kontrol et
    if (requestMap['billingAddress'] is Map) {
      if (requestMap['billingAddress']['city'] == null || 
          requestMap['billingAddress']['city'].toString().isEmpty) {
        throw Exception("Billing address city boş olamaz.");
      }
    }
    
    final requestBody = json.encode(requestMap);
    
    // Debug bilgisi ekle
    Logger.debug('Ödeme İsteği URL: $url');
    Logger.debug('Ödeme İsteği Gövdesi: $requestBody');
    
    try {
      // Headers bilgisini güvenli bir şekilde logla
      final Map<String, String> sanitizedHeaders = Map<String, String>.from(iyzipayHeaders);
      if (sanitizedHeaders.containsKey('Authorization')) {
        sanitizedHeaders['Authorization'] = '********';
      }
      Logger.debug('İyzipay isteği gönderiliyor - URL: $url, Headers: $sanitizedHeaders');
      Logger.debug('İyzipay istek gövdesi: $requestBody');
      
      // randomString değerini özellikle kontrol et
      final requestData = json.decode(requestBody);
      if (requestData['randomString'] == null || requestData['randomString'].toString().isEmpty) {
        throw Exception('HATA: randomString değeri eksik! İstek gönderilmeden hata alındı.');
      } else {
        Logger.debug('randomString doğrulaması başarılı: ${requestData['randomString']}');
      }
      
      // CORS sorunu olabilir, direkt browser konsolunda test için options isteği gönderelim
      if (Uri.base.toString().startsWith('http://localhost') || 
          Uri.base.toString().startsWith('http://127.0.0.1')) {
        Logger.debug('Yerel geliştirme ortamında çalışıyor, CORS kontrolü yapılıyor...');
      }
      
      // Zaman aşımını arttır (30 saniye)
      final response = await http.post(
        Uri.parse(url),
        headers: iyzipayHeaders,
        body: requestBody,
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Bağlantı zaman aşımına uğradı (30 saniye). İnternet bağlantınızı kontrol edin.');
      });
      
      Logger.debug('Ödeme Yanıt Durum Kodu: ${response.statusCode}');
      Logger.debug('Ödeme Yanıt Gövdesi: ${response.body}');

      if (response.statusCode == 200) {
        return Payment.fromJson(json.decode(response.body));
      } else {
        throw Exception('Ödeme işlemi başarısız (HTTP ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      Logger.error('Ödeme işlemi hatası: $e');
      
      // Hatanın türüne göre farklı mesajlar gösterelim
      if (e.toString().contains('Failed to fetch')) {
        throw Exception('Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin ve tekrar deneyin. (CORS hatası olabilir)');
      } else if (e.toString().contains('SocketException') || 
                 e.toString().contains('Connection refused')) {
        throw Exception('Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin ve tekrar deneyin.');
      } else if (e.toString().contains('HandshakeException')) {
        throw Exception('Güvenli bağlantı kurulamadı. SSL/TLS hatası olabilir.');
      } else if (e.toString().contains('HttpException')) {
        throw Exception('HTTP isteği başarısız oldu. Sunucu yanıt vermiyor veya geçersiz URL.');
      }
      rethrow;
    }
  }
}
