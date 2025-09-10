import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/payment_card.dart';
import '../services/firebase_payment_service.dart';
import '../models/iyzipay/iyzipay_address.dart';
import '../widgets/test_card_info.dart';
import '../utils/logger.dart';
import '../models/cart.dart';

class TestPaymentScreen extends StatefulWidget {
  const TestPaymentScreen({super.key});

  @override
  State<TestPaymentScreen> createState() => _TestPaymentScreenState();
}

class _TestPaymentScreenState extends State<TestPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  // Firebase üzerinden ödeme servisini kullanıyoruz
  final FirebasePaymentService _paymentService = FirebasePaymentService();
  
  // Form alanları
  final _cardNumberController = TextEditingController(text: '5528790000000008');
  final _cardHolderNameController = TextEditingController(text: 'John Doe');
  final _expireMonthController = TextEditingController(text: '12');
  final _expireYearController = TextEditingController(text: '30'); // 2 haneli yıl formatı
  final _cvcController = TextEditingController(text: '123');
  
  // Adres bilgileri
  final _addressController = TextEditingController(text: 'Test Mahallesi, Test Caddesi No:1');
  final _cityController = TextEditingController(text: 'Istanbul');
  final _countryController = TextEditingController(text: 'Turkey');
  final _zipCodeController = TextEditingController(text: '34000');
  
  bool _isLoading = false;
  String _resultMessage = '';
  bool _success = false;
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expireMonthController.dispose();
    _expireYearController.dispose();
    _cvcController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _testPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _resultMessage = '';
      _success = false;
    });

    try {
      // Test kartını oluştur
      final paymentCard = PaymentCard(
        cardHolderName: _cardHolderNameController.text,
        cardNumber: _cardNumberController.text,
        expireMonth: _expireMonthController.text,
        expireYear: _expireYearController.text,
        cvc: _cvcController.text,
      );
      
      // Test adreslerini oluştur
      final address = IyzipayAddress(
        id: 'test-address-1',
        title: 'Test Adresi',
        fullAddress: _addressController.text,
        city: _cityController.text,
        country: _countryController.text,
        zipCode: _zipCodeController.text,
        latitude: 40.9923307,
        longitude: 29.1244229
      );
      
      // Test sepeti oluştur (1 ürün)
      final testItem = CartItem(
        id: 'test-item-1',
        productId: 'test-product-1',
        name: 'Test Ürün',
        price: 1.0, // 1 TL test ücreti
        quantity: 1,
        imageURL: 'https://via.placeholder.com/150',
      );
      
      Logger.debug('Test ödemesi başlatılıyor...');
      Logger.debug('Kart Bilgileri: ${paymentCard.toJson()}');
      Logger.debug('Adres Bilgileri: ${address.toMap()}');
      
      // Ödemeyi Firebase Functions üzerinden gerçekleştir
      Logger.debug('Firebase üzerinden ödeme işlemi başlatılıyor...');
      final result = await _paymentService.processPayment(
        userId: 'test-user',
        items: [testItem],
        totalAmount: 1.0, // 1 TL test tutarı
        billingAddress: address,
        shippingAddress: address,
      );
      
      Logger.debug('Test ödemesi sonucu: ${result.success}');
      Logger.debug('Mesaj: ${result.message}');
      Logger.debug('İşlem ID: ${result.transactionId ?? 'Yok'}');
      
      setState(() {
        _isLoading = false;
        _resultMessage = result.message;
        _success = result.success;
      });
    } catch (e) {
      Logger.error('Test ödemesi hatası: $e');
      setState(() {
        _isLoading = false;
        _resultMessage = 'İşlem hatası (Firebase kullanılıyor): $e';
        _success = false;
      });
      
      // Firebase Functions'a ulaşılamıyorsa ek bilgi göster
      try {
        final pingResponse = await http.get(Uri.parse('https://www.google.com'));
        if (pingResponse.statusCode >= 200 && pingResponse.statusCode < 300) {
          Logger.debug('İnternet bağlantısı var, ancak Firebase Functions\'a erişilemiyor olabilir');
        }
      } catch (pingError) {
        Logger.error('İnternet bağlantısı testi de başarısız: $pingError');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Testi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Test kart bilgileri kartı
              const TestCardInfo(),
              
              const SizedBox(height: 20),
              
              // Kart bilgileri
              const Text(
                'Kart Bilgileri',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Kart Numarası',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kart numarası gerekli';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardHolderNameController,
                decoration: const InputDecoration(
                  labelText: 'Kart Sahibi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kart sahibi adı gerekli';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expireMonthController,
                      decoration: const InputDecoration(
                        labelText: 'Ay (MM)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _expireYearController,
                      decoration: const InputDecoration(
                        labelText: 'Yıl (YY)',
                        border: OutlineInputBorder(),
                        hintText: 'Örn: 30 (2030 için)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvcController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Adres bilgileri
              const Text(
                'Adres Bilgileri',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Adres gerekli';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Şehir',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şehir gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Ülke',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ülke gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(
                  labelText: 'Posta Kodu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Posta kodu gerekli';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Ödeme butonları
              ElevatedButton(
                onPressed: _isLoading ? null : _testPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Test Ödemesi Yap (1 TL)'),
              ),
              
              const SizedBox(height: 24),
              
              // Sonuç mesajı
              if (_resultMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _success ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _success ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    _resultMessage,
                    style: TextStyle(
                      color: _success ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


