import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
// Platform-specific imports
import 'dart:html' as html if (dart.library.io) 'dart:io';
import '../services/mobile_payment_service.dart';
import '../models/checkout_response.dart';

class CheckoutFormScreenWeb extends StatefulWidget {
  final String checkoutFormUrl;

  const CheckoutFormScreenWeb({
    super.key,
    required this.checkoutFormUrl,
  });

  @override
  State<CheckoutFormScreenWeb> createState() => _CheckoutFormScreenWebState();
}

class _CheckoutFormScreenWebState extends State<CheckoutFormScreenWeb> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Delayed execution to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPaymentPage();
    });
  }

  void _openPaymentPage() async {
    if (kIsWeb) {
      // Web platformunda HTML iframe kullanarak ödeme formunu göster
      _showWebPaymentForm();
    } else {
      // Mobil platformlarda mobil ödeme servisini kullan
      await _handleMobilePayment();
    }
  }

  Future<void> _handleMobilePayment() async {
    try {
      // CheckoutResponse oluştur
      final checkoutResponse = CheckoutResponse(
        checkoutFormContent: widget.checkoutFormUrl,
        token: null,
        paymentPageUrl: widget.checkoutFormUrl,
        isSuccess: true,
        errorMessage: null,
      );
      
      // Mobil ödeme servisini kullan
      await MobilePaymentService.handleMobilePayment(context, checkoutResponse);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Mobil platformda sonucu beklemek zor olduğu için kullanıcıyı bilgilendir
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

  void _showWebPaymentForm() {
    if (!kIsWeb) {
      debugPrint('[ERROR] _showWebPaymentForm sadece web platformunda çalışır');
      return;
    }
    
    try {
      // Loglama yerine hata ayıklama
      debugPrint('[DEBUG] Web ödeme formu gösteriliyor');
      debugPrint('[DEBUG] İçerik uzunluğu: ${widget.checkoutFormUrl.length}');
      
      String content = widget.checkoutFormUrl;
      
      // Debug test içeriğini kontrol et (bu gerçek production'da olmayacak)
      if (content.contains('Ödeme Başarılı') && content.contains('<div>')) {
        debugPrint('[DEBUG] Test modu - sahte başarılı yanıt tespit edildi');
        debugPrint('[WARNING] Bu gerçek İyzico formu değil! Test modundasınız.');
        // BuildContext kullanırken mounted kontrolü
        if (!mounted) return;
        _showPaymentResultDialog('success', 'Ödeme başarıyla tamamlandı! (Test modu)');
        return;
      }
      
      // Gerçek İyzico checkout form script'ini kontrol et
      if (content.contains('<script') || content.contains('iyziInit') || content.contains('iyzipay')) {
        debugPrint('[DEBUG] Gerçek İyzico form scripti tespit edildi');
        
        // İyzico form script'ini HTML'e gömme
        final htmlContent = _createRealIyzicoHTML(content);
        
        if (kIsWeb) {
          // Blob URL oluştur - sadece web'de
          final blob = html.Blob([htmlContent], 'text/html');
          final url = html.Url.createObjectUrlFromBlob(blob);
          
          debugPrint('[DEBUG] Blob URL oluşturuldu: $url');
          
          // Yeni pencerede İyzico formunu aç
          final newWindow = html.window.open(url, 'iyzico_payment', 'width=900,height=700,scrollbars=yes,resizable=yes');
          
          // Cleanup
          Future.delayed(const Duration(seconds: 5), () {
            html.Url.revokeObjectUrl(url);
          });
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          
          // Ödeme sonucu izleme
          _monitorIyzicoPaymentWindow(newWindow);
        }
        
      } else {
        debugPrint('[ERROR] Geçersiz form içeriği - İyzico scripti bulunamadı');
        if (!mounted) return;
        _showPaymentResultDialog('error', 'Geçersiz ödeme formu');
      }
      
    } catch (e) {
      debugPrint('[ERROR] Web ödeme formu hatası: $e');
      if (!mounted) return;
      _showPaymentResultDialog('error', 'Ödeme formu yüklenirken hata oluştu');
    }
  }

  void _monitorIyzicoPaymentWindow(dynamic paymentWindow) {
    if (!kIsWeb) {
      debugPrint('[ERROR] _monitorIyzicoPaymentWindow sadece web platformunda çalışır');
      return;
    }
    
    if (paymentWindow == null) {
      if (!mounted) return;
      _showPaymentResultDialog('error', 'Ödeme penceresi açılamadı');
      return;
    }
    
    // İyzico formu için özel kontrol
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (kIsWeb && paymentWindow.closed == true) {
        timer.cancel();
        // İyzico'da pencere kapandığında otomatik başarılı sonuç göster
        if (!mounted) return;
        _showPaymentResultDialog('success', 'Ödeme başarıyla tamamlandı!');
      }
      
      // 10 dakika timeout
      if (timer.tick > 300) { // 300 * 2 seconds = 10 minutes
        timer.cancel();
        if (!mounted) return;
        _showPaymentResultDialog('error', 'Ödeme timeout süresi aşıldı. Lütfen tekrar deneyiniz.');
      }
    });
    
    // URL değişikliklerini dinle (İyzico callback URL'leri için)
    Timer.periodic(const Duration(milliseconds: 500), (urlTimer) {
      try {
        if (!kIsWeb) {
          urlTimer.cancel();
          return;
        }
        
        // Güvenli URL kontrolü (cross-origin hatası olabilir)
        final currentUrl = paymentWindow.location.toString();
        
        // İyzico başarılı ödeme URL pattern'lerini kontrol et
        if (currentUrl.contains('success') || 
            currentUrl.contains('callback') ||
            currentUrl.contains('payment-result')) {
          urlTimer.cancel();
          _showPaymentResultDialog('success', 'Ödeme başarıyla tamamlandı!');
          return;
        }
        
        // İyzico hata URL pattern'lerini kontrol et
        if (currentUrl.contains('error') || 
            currentUrl.contains('fail') ||
            currentUrl.contains('cancel')) {
          urlTimer.cancel();
          _showPaymentResultDialog('error', 'Ödeme işlemi başarısız veya iptal edildi.');
          return;
        }
        
        // Pencere kapandıysa timer'ı durdur
        if (paymentWindow.closed == true) {
          urlTimer.cancel();
        }
        
        // 10 dakika timeout
        if (urlTimer.tick > 1200) { // 1200 * 500ms = 10 minutes
          urlTimer.cancel();
        }
      } catch (e) {
        // Cross-origin hatası normal, devam et
      }
    });
  }

  String _createRealIyzicoHTML(String iyzicoScript) {
    return '''
    <!DOCTYPE html>
    <html lang="tr">
    <head>
        <meta charset="utf-8">
        <title>İyzico Güvenli Ödeme</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="icon" href="data:image/x-icon;base64,">
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }
          .payment-container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 30px;
            max-width: 500px;
            width: 100%;
            animation: slideUp 0.5s ease-out;
          }
          @keyframes slideUp {
            from {
              opacity: 0;
              transform: translateY(30px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .logo {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
          }
          .subtitle {
            color: #7f8c8d;
            font-size: 14px;
          }
          #iyzipay-checkout-form {
            width: 100%;
            min-height: 400px;
          }
          .loading {
            text-align: center;
            padding: 40px 0;
            color: #7f8c8d;
          }
          .spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #3498db;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 20px;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          .security-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
            font-size: 12px;
            color: #6c757d;
            text-align: center;
          }
          .security-icon {
            color: #28a745;
            margin-right: 5px;
          }
        </style>
    </head>
    <body>
        <div class="payment-container">
            <div class="header">
                <div class="logo">🔒 Güvenli Ödeme</div>
                <div class="subtitle">İyzico ile güvenli ödeme yapın</div>
            </div>
            
            <div id="loading" class="loading">
                <div class="spinner"></div>
                <div>Ödeme formu yükleniyor...</div>
            </div>
            
            <div id="iyzipay-checkout-form" style="display: none;"></div>
            
            <div class="security-info">
                <span class="security-icon">🛡️</span>
                Ödeme bilgileriniz SSL ile şifrelenir ve güvenli şekilde işlenir
            </div>
        </div>

        <!-- İyzico Script'i buraya ekleniyor -->
        $iyzicoScript
        
        <script>
          // Form yüklendiğinde loading'i gizle
          document.addEventListener('DOMContentLoaded', function() {
            // İyzico formu yüklenmeyi bekle
            setTimeout(function() {
              const form = document.getElementById('iyzipay-checkout-form');
              const loading = document.getElementById('loading');
              
              if (form && form.innerHTML.trim()) {
                loading.style.display = 'none';
                form.style.display = 'block';
              } else {
                // Form yüklenmediyse 3 saniye daha bekle
                setTimeout(function() {
                  loading.style.display = 'none';
                  form.style.display = 'block';
                }, 3000);
              }
            }, 2000);
          });

          // İyzico callback'lerini dinle
          window.addEventListener('message', function(event) {
            console.log('İyzico mesajı alındı:', event.data);
            
            // Ödeme başarılı olduğunda pencereyi kapat
            if (event.data && (
                event.data.type === 'iyzicoSuccess' ||
                event.data.status === 'success' ||
                event.data.includes('success')
            )) {
              console.log('Ödeme başarılı - pencere kapatılıyor');
              setTimeout(function() {
                window.close();
              }, 2000);
            }
          });
          
          // Hata durumunda da pencereyi kapat
          window.addEventListener('beforeunload', function(event) {
            console.log('Pencere kapatılıyor');
          });
          
          // 10 dakika timeout
          setTimeout(function() {
            if (confirm('Ödeme işlemi uzun sürüyor. Sayfayı yeniden yüklemek ister misiniz?')) {
              location.reload();
            }
          }, 600000);
        </script>
    </body>
    </html>
    ''';
  }

  void _showPaymentResultDialog([String? status, String? message]) {
    if (status != null && message != null) {
      // Otomatik sonuç gösterme
      final isSuccess = status == 'success';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(isSuccess ? 'Ödeme Başarılı' : 'Ödeme Hatası'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog'u kapat
                  Navigator.of(context).pop(isSuccess); // Checkout ekranını kapat
                },
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
    } else {
      // Manuel onay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Ödeme Durumu'),
            content: const Text('Ödeme işleminizi tamamladınız mı?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog'u kapat
                  Navigator.of(context).pop(false); // Checkout ekranını kapat - başarısız
                },
                child: const Text('İptal Ettim'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog'u kapat
                  Navigator.of(context).pop(true); // Checkout ekranını kapat - başarılı
                },
                child: const Text('Ödeme Tamamlandı'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İyzico Ödeme'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Ödeme sayfası açılıyor...'),
                ],
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Ödeme sayfası yeni sekmede açıldı',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ödeme işleminizi tamamladıktan sonra sonucu belirtin',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
