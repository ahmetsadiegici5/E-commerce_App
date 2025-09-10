class CheckoutResponse {
  final String checkoutFormContent;
  final String? token;
  final String? paymentPageUrl;
  final bool isSuccess;
  final String? errorMessage;

  CheckoutResponse({
    required this.checkoutFormContent,
    this.token,
    this.paymentPageUrl,
    required this.isSuccess,
    this.errorMessage,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      checkoutFormContent: json['checkoutFormContent'] ?? '',
      token: json['token'],
      paymentPageUrl: json['paymentPageUrl'],  // Bu satır doğru
      isSuccess: json['status'] == 'success',
      errorMessage: json['errorMessage'],
    );
  }

  bool get hasDirectUrl => paymentPageUrl != null && paymentPageUrl!.isNotEmpty;
  
  String? get directCheckoutUrl {
    // paymentPageUrl öncelikli kullan (İyzico'dan gelen gerçek URL)
    if (paymentPageUrl != null && paymentPageUrl!.isNotEmpty) {
      return paymentPageUrl;
    }
    // Token varsa fallback URL oluştur  
    else if (token != null && token!.isNotEmpty) {
      return 'https://sandbox-cpp.iyzipay.com?token=$token&lang=tr';
    }
    return null;
  }
}
