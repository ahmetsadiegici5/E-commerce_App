import 'package:flutter/material.dart';
import '../services/mobile_payment_service.dart';
import '../models/checkout_response.dart';

class CheckoutFormScreenMobile extends StatefulWidget {
  final CheckoutResponse checkoutResponse;

  const CheckoutFormScreenMobile({
    super.key,
    required this.checkoutResponse,
  });

  @override
  State<CheckoutFormScreenMobile> createState() => _CheckoutFormScreenMobileState();
}

class _CheckoutFormScreenMobileState extends State<CheckoutFormScreenMobile> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleMobilePayment();
    });
  }

  Future<void> _handleMobilePayment() async {
    try {
      debugPrint('[DEBUG] Mobil ödeme başlatılıyor: CheckoutResponse alındı');
      debugPrint('[DEBUG] Token: ${widget.checkoutResponse.token}');
      debugPrint('[DEBUG] PaymentPageUrl: ${widget.checkoutResponse.paymentPageUrl}');
      
      // Mobil ödeme servisini doğrudan CheckoutResponse ile kullan
      await MobilePaymentService.handleMobilePayment(context, widget.checkoutResponse);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Kullanıcıyı bilgilendir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme sayfası açıldı. Ödeme tamamlandıktan sonra uygulamaya geri dönün.'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Biraz bekleyip geri dön
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop(false); // Sonucu bilemediğimiz için false
          }
        });
      }
    } catch (e) {
      debugPrint('[ERROR] Mobil ödeme hatası: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme sayfası açılamadı: $e')),
        );
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Ödeme sayfası açılıyor...'),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Ödeme işlemi başlatıldı'),
                  Text('Lütfen ödeme sayfasında işleminizi tamamlayın'),
                ],
              ),
      ),
    );
  }
}
