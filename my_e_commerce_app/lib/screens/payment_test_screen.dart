import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/payment_card.dart';
import '../models/iyzipay/iyzipay_address.dart';
import '../models/cart.dart';
import '../services/payment_service.dart';
// Firebase servisi eklendi
import '../utils/logger.dart';
import './address_form_screen.dart';
import '../models/user.dart';

class PaymentTestScreen extends StatefulWidget {
  const PaymentTestScreen({super.key});

  @override
  State<PaymentTestScreen> createState() => _PaymentTestScreenState();
}

class _PaymentTestScreenState extends State<PaymentTestScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isSuccess = false;

  // Ödeme kartı bilgileri
  String _cardHolderName = 'John Doe';
  String _cardNumber = '5528790000000008'; // Iyzico test kart numarası
  String _expireMonth = '12';
  String _expireYear = '2030';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Testi'),
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
                  'Test Ödeme Ekranı',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 24),
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
                
                // Test butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : _testApiConnection,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('BAĞLANTIYI TEST ET'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : _testPayment,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('TEST ÖDEME YÜRÜT'),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sonuç mesajı
                if (_resultMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
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

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _resultMessage = 'API bağlantısı test ediliyor... (Iyzipay Sandbox API)';
    });

    try {
      // İlk önce internet bağlantısını kontrol edelim
      try {
        final internetCheckResponse = await http.get(
          Uri.parse('https://www.google.com'),
        ).timeout(const Duration(seconds: 5));
        
        if (internetCheckResponse.statusCode >= 200 && internetCheckResponse.statusCode < 300) {
          setState(() {
            _resultMessage = 'API bağlantısı test ediliyor... (İnternet bağlantısı var)';
          });
        }
      } catch (internetError) {
        setState(() {
          _isLoading = false;
          _resultMessage = 'İnternet bağlantısı bulunamadı! Lütfen internet bağlantınızı kontrol edin.';
          _isSuccess = false;
        });
        return; // İnternet yoksa API testi yapmaya gerek yok
      }

      // API bağlantısını test et
      final paymentService = PaymentService();
      final isConnected = await paymentService.testConnection();

      if (isConnected) {
        setState(() {
          _isLoading = false;
          _resultMessage = 'API bağlantısı başarılı! ✅ Iyzipay Sandbox API erişilebilir durumda.';
          _isSuccess = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _resultMessage = 'API bağlantısı başarısız ❌\nİnternet bağlantınız var ancak Iyzipay API\'ye erişilemiyor.\n'
            'Bu sorun CORS kısıtlaması, güvenlik duvarı veya yanlış API anahtarları nedeniyle olabilir.';
          _isSuccess = false;
        });
      }
    } catch (e) {
      Logger.error('Bağlantı hatası: $e');
      setState(() {
        _isLoading = false;
        _resultMessage = 'API bağlantısı hatası: ${e.toString().replaceAll('Exception: ', '')}\n'
          'Lütfen konsolu kontrol edin ve internet bağlantınızın aktif olduğundan emin olun.';
        _isSuccess = false;
      });
    }
  }

  Future<void> _testPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _resultMessage = '';
      });

      try {
        final paymentService = PaymentService();
        
        // Test için sabit örnek değerler
        final card = PaymentCard(
          cardHolderName: _cardHolderName,
          cardNumber: _cardNumber,
          expireMonth: _expireMonth,
          expireYear: _expireYear,
          cvc: _cvc,
        );
        
        // Sınıf değişkenlerini kullanalım
        final billingAddress = _billingAddress;
        final shippingAddress = _shippingAddress;

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

        // Adres bilgilerini ekrana yazdır - hata ayıklama için
        Logger.debug('=== Adres Bilgileri ===');
        Logger.debug('Billing Adres: ${billingAddress.fullAddress}');
        Logger.debug('Billing Şehir: ${billingAddress.city}');
        Logger.debug('Billing Ülke: ${billingAddress.country}');
        Logger.debug('Billing Posta Kodu: ${billingAddress.zipCode}');
        Logger.debug('Shipping Adres: ${shippingAddress.fullAddress}');
        Logger.debug('Shipping Şehir: ${shippingAddress.city}');
        Logger.debug('Shipping Ülke: ${shippingAddress.country}');
        Logger.debug('Shipping Posta Kodu: ${shippingAddress.zipCode}');
        
        final result = await paymentService.processPayment(
          userId: userId,
          items: items,
          totalAmount: totalAmount,
          card: card,
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
}
