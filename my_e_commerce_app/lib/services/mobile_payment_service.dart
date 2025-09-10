import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../models/checkout_response.dart';
import 'firebase_payment_service.dart';
import '../screens/payment_result_screen.dart';
import 'payment_result_service.dart';

class MobilePaymentService {
  // Yeni akış: paymentPageUrl varsa WebView aç, yoksa HTML içeriğini yükle.
  static Future<void> handleMobilePayment(BuildContext context, CheckoutResponse checkoutResponse) async {
    try {
      Logger.debug('Mobil checkout akışı başlıyor');
      Logger.debug('Token: ${checkoutResponse.token}');
      Logger.debug('PaymentPageUrl field: ${checkoutResponse.paymentPageUrl}');
      Logger.debug('CheckoutFormContent uzunluğu: ${checkoutResponse.checkoutFormContent.length}');
      Logger.debug('Has direct URL: ${checkoutResponse.hasDirectUrl}');
      Logger.debug('Direct checkout URL: ${checkoutResponse.directCheckoutUrl}');
      
      if (checkoutResponse.hasDirectUrl) {
        final url = checkoutResponse.directCheckoutUrl!;
        Logger.debug('✅ Direct URL bulundu: $url');
        Logger.debug('WebView açılıyor.');
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PaymentWebViewPage(
          initialUrl: url,
          token: checkoutResponse.token,
        )));
        return;
      }
      
      Logger.debug('Direct URL yok. HTML içeriği kontrol edilecek.');
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PaymentWebViewPage(
        htmlContent: checkoutResponse.checkoutFormContent,
        token: checkoutResponse.token,
      )));
    } catch (e) {
      Logger.error('Mobil ödeme hata: $e');
      rethrow;
    }
  }

  static Future<void> handlePaymentResult(Uri uri) async {
    // İyzico'dan gelen ödeme sonucunu işle
    final status = uri.queryParameters['status'];
    final paymentId = uri.queryParameters['paymentId'];
    
    Logger.debug('Ödeme sonucu alındı:');
    Logger.debug('Status: $status');
    Logger.debug('Payment ID: $paymentId');
    
    // TODO: Ödeme sonucuna göre işlem yap
  }
}

class _PaymentWebViewPage extends StatefulWidget {
  final String? initialUrl;
  final String? htmlContent;
  final String? token;
  const _PaymentWebViewPage({this.initialUrl, this.htmlContent, this.token});
  @override
  State<_PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<_PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url){
            Logger.debug('WebView page started: $url');
          },
          onPageFinished: (url){
            Logger.debug('WebView page finished: $url');
            setState(()=>_loading=false);
            // Callback url yakalama - domaininizi ayarlayın
            if (url.contains('payment-result')) {
              if (widget.token!=null) {
                FirebasePaymentService().retrieveCheckoutForm(widget.token!).then((r){
                  Logger.debug('Retrieve raw sonucu: $r');
                  if (!mounted) return;
                  final normalized = PaymentResultService.normalizeRetrieveResponse(r);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => PaymentResultScreen(result: normalized))
                  );
                });
              } else {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => PaymentResultScreen(result: {'status':'unknown','errorMessage':'Token bulunamadı'}))
                );
              }
            }
          },
        ),
      );

    if (widget.initialUrl!=null) {
      _controller.loadRequest(Uri.parse(widget.initialUrl!));
    } else if (widget.htmlContent!=null) {
      _controller.loadHtmlString(widget.htmlContent!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
