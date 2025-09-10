import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Encoding için gerekli
import '../models/payment_card.dart';
import '../models/iyzipay/iyzipay_address.dart';
import '../models/cart.dart';
import '../services/firebase_payment_service.dart';
import '../utils/logger.dart';
import './address_form_screen.dart';
import '../models/user.dart';

class FirebasePaymentTestScreen extends StatefulWidget {
  const FirebasePaymentTestScreen({super.key});

  @override
  State<FirebasePaymentTestScreen> createState() => _FirebasePaymentTestScreenState();
}

class _FirebasePaymentTestScreenState extends State<FirebasePaymentTestScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isSuccess = false;
  bool _is3DSecure = false;
  Map<String, dynamic>? _threeDSData;

  // Ödeme kartı bilgileri - İyzipay sandbox için doğrulanmış test kartı
  String _cardHolderName = 'John Doe';
  String _cardNumber = '5528790000000008'; // İyzipay test kart numarası - Başarılı ödeme senaryosu
  String _expireMonth = '12';
  String _expireYear = '30'; // İyzipay 2 haneli yıl formatını bekliyor olabilir (2030 -> 30)
  String _cvc = '123';
  
  // Test adres bilgileri
  IyzipayAddress _billingAddress = IyzipayAddress(
    id: '1',
    title: 'Test Adresi',
    fullAddress: 'Atatürk Mah. Test Cad. No:1',
    city: 'Istanbul',
    country: 'Turkey',
    zipCode: '34000',
    latitude: 41.0082,
    longitude: 28.9784,
  );
  
  IyzipayAddress _shippingAddress = IyzipayAddress(
    id: '1',
    title: 'Test Adresi',
    fullAddress: 'Atatürk Mah. Test Cad. No:1',
    city: 'Istanbul',
    country: 'Turkey',
    zipCode: '34000',
    latitude: 41.0082,
    longitude: 28.9784,
  );
  
  // Adres düzenleme ekranları için metodlar
  void _editBillingAddress(BuildContext context) {
    _editAddress(context, _billingAddress, (updatedAddress) {
      setState(() {
        _billingAddress = updatedAddress;
      });
    });
  }
  
  void _editShippingAddress(BuildContext context) {
    _editAddress(context, _shippingAddress, (updatedAddress) {
      setState(() {
        _shippingAddress = updatedAddress;
      });
    });
  }
  
  void _editAddress(BuildContext context, IyzipayAddress address, Function(IyzipayAddress) onSave) {
    // IyzipayAddress'i UserAddress'e dönüştür
    final userAddress = UserAddress(
      id: address.id,
      title: address.title,
      fullAddress: address.fullAddress,
      city: address.city,
      country: address.country,
      zipCode: address.zipCode,
      latitude: address.latitude,
      longitude: address.longitude,
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddressFormScreen(
          address: userAddress,
          onSave: (updatedAddress) {
            // UserAddress'i IyzipayAddress'e dönüştür
            final iyzipayAddress = IyzipayAddress(
              id: updatedAddress.id,
              title: updatedAddress.title,
              fullAddress: updatedAddress.fullAddress,
              city: updatedAddress.city ?? 'Istanbul',
              country: updatedAddress.country ?? 'Turkey',
              zipCode: updatedAddress.zipCode ?? '34000',
              latitude: updatedAddress.latitude,
              longitude: updatedAddress.longitude,
            );
            onSave(iyzipayAddress);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3D Secure HTML içeriği geldiyse WebView göster
    if (_threeDSData != null && 
        _threeDSData!['status'] == 'success' && 
        _threeDSData!['threeDSHtmlContent'] != null) {
      
      // WebView Kontrolcüsü oluştur
      final WebViewController controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              // Callback URL'iniz buraya gelecek
              if (request.url.contains('/payment/callback')) {
                // 3D Secure işlemi tamamlandı, sonucu işle
                _complete3DSecurePayment(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(_threeDSData!['threeDSHtmlContent']);
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('3D Secure Ödeme'),
        ),
        body: WebViewWidget(controller: controller),
      );
    }

    // Normal ödeme ekranı
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Ödeme Testi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firebase Cloud Functions Ödeme Testi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                // Kart bilgileri
                TextFormField(
                  initialValue: _cardHolderName,
                  decoration: const InputDecoration(
                    labelText: 'Kart Üzerindeki İsim',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _cardHolderName = value,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  initialValue: _cardNumber,
                  decoration: const InputDecoration(
                    labelText: 'Kart Numarası',
                    border: OutlineInputBorder(),
                    helperText: 'Test için: 5528790000000008',
                  ),
                  onChanged: (value) => _cardNumber = value,
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _expireMonth,
                        decoration: const InputDecoration(
                          labelText: 'Ay (MM)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _expireMonth = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _expireYear,
                        decoration: const InputDecoration(
                          labelText: 'Yıl (YYYY)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _expireYear = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _cvc,
                        decoration: const InputDecoration(
                          labelText: 'CVC',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _cvc = value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Adres Düzenleme Bölümü
                const SizedBox(height: 24),
                const Text(
                  'Adres Bilgileri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_location),
                        label: const Text('Fatura Adresi'),
                        onPressed: () => _editBillingAddress(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.local_shipping),
                        label: const Text('Teslimat Adresi'),
                        onPressed: () => _editShippingAddress(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3D Secure seçeneği
                SwitchListTile(
                  title: const Text('3D Secure kullan'),
                  value: _is3DSecure,
                  onChanged: (value) {
                    setState(() {
                      _is3DSecure = value;
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Ödeme Test Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testPayment,
                    child: const Text('Ödeme İşlemini Test Et'),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Sonuç mesajı
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_resultMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSuccess ? 'Ödeme Başarılı' : 'Ödeme Başarısız',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isSuccess ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_resultMessage),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _testPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _resultMessage = '';
      });

      try {
        final paymentService = FirebasePaymentService();
        
        // Test için sabit örnek değerler
        final card = PaymentCard(
          cardHolderName: _cardHolderName,
          cardNumber: _cardNumber,
          expireMonth: _expireMonth,
          expireYear: _expireYear,
          cvc: _cvc,
        );
        
        // Sınıf değişkenlerini kullan
        final billingAddress = _billingAddress;
        final shippingAddress = _shippingAddress;
        
        // Adres bilgilerini loglayalım
        Logger.debug('=== Adres Bilgileri (Firebase) ===');
        Logger.debug('Billing Adres: ${billingAddress.fullAddress}');
        Logger.debug('Billing Şehir: ${billingAddress.city}');
        Logger.debug('Billing Ülke: ${billingAddress.country}');
        Logger.debug('Billing Posta Kodu: ${billingAddress.zipCode}');
        Logger.debug('Shipping Adres: ${shippingAddress.fullAddress}');
        Logger.debug('Shipping Şehir: ${shippingAddress.city}');
        Logger.debug('Shipping Ülke: ${shippingAddress.country}');
        Logger.debug('Shipping Posta Kodu: ${shippingAddress.zipCode}');

        // Test ürün listesi
        final items = [
          CartItem(
            id: '1',
            productId: 'P1',
            name: 'Test Ürün 1',
            price: 50.0,
            quantity: 2,
            imageURL: 'https://example.com/test1.jpg',
          ),
          CartItem(
            id: '2',
            productId: 'P2',
            name: 'Test Ürün 2',
            price: 75.0,
            quantity: 1,
            imageURL: 'https://example.com/test2.jpg',
          ),
        ];

        final userId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
        final totalAmount = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

        if (_is3DSecure) {
          // 3D Secure ödeme işlemi
          final callbackUrl = 'https://us-central1-myproject-a52ae.cloudfunctions.net/paymentApi/payment/callback';
          
          final threeDSResult = await paymentService.initialize3DSecurePayment(
            userId: userId,
            items: items,
            totalAmount: totalAmount,
            card: card,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress,
            callbackUrl: callbackUrl,
          );

          if (threeDSResult['status'] == 'success' && threeDSResult['threeDSHtmlContent'] != null) {
            // 3D Secure sayfasını göster
            setState(() {
              _isLoading = false;
              _threeDSData = threeDSResult;
            });
          } else {
            setState(() {
              _isLoading = false;
              _isSuccess = false;
              _resultMessage = '3D Secure başlatma başarısız: ${threeDSResult['errorMessage'] ?? 'Bilinmeyen hata'}';
            });
          }
        } else {
          // Normal ödeme işlemi
          final result = await paymentService.processPayment(
            userId: userId,
            items: items,
            totalAmount: totalAmount,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress,
          );

          setState(() {
            _isLoading = false;
            _isSuccess = result.success;
            _resultMessage = result.success
                ? 'İşlem başarılı! İşlem ID: ${result.transactionId}'
                : 'İşlem başarısız: ${result.message}';
          });
        }
      } catch (e) {
        Logger.error('Ödeme testi hatası: $e');
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _resultMessage = 'Hata: ${e.toString()}';
        });
      }
    }
  }

  // 3D Secure işlemi tamamlama
  void _complete3DSecurePayment(String callbackUrl) async {
    setState(() {
      _threeDSData = null; // WebView'dan çık
      _isLoading = true;
    });

    try {
      // URL'den parametreleri çıkar
      final uri = Uri.parse(callbackUrl);
      final paymentId = uri.queryParameters['paymentId'];
      final conversationId = uri.queryParameters['conversationId'];

      if (paymentId != null && conversationId != null) {
        final paymentService = FirebasePaymentService();
        final result = await paymentService.complete3DSecurePayment(
          paymentId: paymentId,
          conversationId: conversationId,
        );

        setState(() {
          _isLoading = false;
          _isSuccess = result.success;
          _resultMessage = result.success
              ? '3D Secure işlemi başarılı! İşlem ID: ${result.transactionId}'
              : '3D Secure işlemi başarısız: ${result.message}';
        });
      } else {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _resultMessage = '3D Secure tamamlanamadı: Eksik parametreler';
        });
      }
    } catch (e) {
      Logger.error('3D Secure tamamlama hatası: $e');
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = '3D Secure tamamlama hatası: ${e.toString()}';
      });
    }
  }
}
