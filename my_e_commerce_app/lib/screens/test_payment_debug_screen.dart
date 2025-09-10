import 'package:flutter/material.dart';
import '../models/iyzipay/iyzipay_address.dart';
import '../services/firebase_payment_service.dart';
import '../models/cart.dart';
import '../utils/logger.dart';

class TestPaymentDebugScreen extends StatefulWidget {
  const TestPaymentDebugScreen({super.key});

  @override
  State<TestPaymentDebugScreen> createState() => _TestPaymentDebugScreenState();
}

class _TestPaymentDebugScreenState extends State<TestPaymentDebugScreen> {
  final FirebasePaymentService _paymentService = FirebasePaymentService();
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isSuccess = false;

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _resultMessage = 'İşlem başlatılıyor...';
      _isSuccess = false;
    });

    try {
      // Firebase Functions üzerinden ödeme başlatacağız
      Logger.debug('Firebase Functions üzerinden ödeme işlemi başlatılıyor...');
      // API bağlantı testi yapılmasına gerek yok, doğrudan işleme geçiyoruz
      
      // Test adresleri
      final testAddress = IyzipayAddress(
        id: 'test-address-id',
        title: 'Test Adresi',
        fullAddress: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        city: 'Istanbul',
        country: 'Turkey',
        zipCode: '34742',
        latitude: 40.9923307,
        longitude: 29.1244229,
      );

      // Test ürünler
      final testItems = [
        CartItem(
          id: 'test-item-1',
          productId: 'P1',
          name: 'Test Ürün 1',
          price: 50.0,
          quantity: 1,
          imageURL: 'https://example.com/test1.jpg',
        ),
        CartItem(
          id: 'test-item-2',
          productId: 'P2',
          name: 'Test Ürün 2',
          price: 75.0,
          quantity: 2,
          imageURL: 'https://example.com/test2.jpg',
        ),
      ];
      
      // Toplam tutarı hesapla
      // Toplam tutarı hesapla
      final totalAmount = testItems.fold<double>(
        0.0, 
        (sum, item) => sum + (item.price * item.quantity)
      );

      Logger.debug('Test ödeme işlemi başlatılıyor...');
      Logger.debug('Toplam Tutar: $totalAmount TL');
      
      // Ödeme işlemini gerçekleştir
      final result = await _paymentService.processPayment(
        userId: 'test-user-id',
        items: testItems,
        totalAmount: totalAmount,
        billingAddress: testAddress,
        shippingAddress: testAddress,
      );

      // Sonucu göster
      setState(() {
        _isLoading = false;
        _resultMessage = result.message;
        _isSuccess = result.success;
      });
      
      if (result.success) {
        Logger.debug('Test ödeme başarılı! İşlem ID: ${result.transactionId}');
      } else {
        Logger.error('Test ödeme başarısız! Hata: ${result.message}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = 'Test sırasında bir hata oluştu: $e';
        _isSuccess = false;
      });
      Logger.error('Test ödeme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Debug Testi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bu ekran, ödeme sisteminin çalışmasını test etmek için tasarlanmıştır. '
              'Test kartı ve örnek verilerle iyzipay API\'sine gerçek bir istek gönderilecektir.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _runTest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('TEST ÖDEME BAŞLAT'),
            ),
            const SizedBox(height: 32),
            if (_resultMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _isSuccess ? 'İŞLEM BAŞARILI' : 'İŞLEM BAŞARISIZ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isSuccess ? Colors.green : Colors.red,
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
    );
  }
}

// CartItem sınıfını models/cart.dart'tan kullanıyoruz
