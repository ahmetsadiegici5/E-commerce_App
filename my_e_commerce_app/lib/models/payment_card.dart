class PaymentCard {
  final String cardHolderName;
  final String cardNumber;
  final String expireMonth;
  final String expireYear;
  final String cvc;
  final String registerCard;

  PaymentCard({
    required this.cardHolderName,
    required this.cardNumber,
    required this.expireMonth,
    required this.expireYear,
    required this.cvc,
    this.registerCard = '0',
  });

  Map<String, dynamic> toMap() {
    return toJson();
  }

  Map<String, dynamic> toJson() {
    // expireYear değeri iki haneli olmalı (iyzipay gereksinimine göre)
    // ve null değer olmamalı
    String formattedExpireYear = expireYear;
    if (expireYear.length > 2) {
      // 4 haneli yıl bilgisini 2 haneye çevirelim (örn. 2024 -> 24)
      formattedExpireYear = expireYear.substring(expireYear.length - 2);
    }

    return {
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'expireMonth': expireMonth,
      'expireYear': formattedExpireYear,
      'cvc': cvc,
      'registerCard': registerCard,
    };
  }

  factory PaymentCard.fromMap(Map<String, dynamic> map) {
    return PaymentCard(
      cardHolderName: map['cardHolderName'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
      expireMonth: map['expireMonth'] ?? '',
      expireYear: map['expireYear'] ?? '',
      cvc: map['cvc'] ?? '',
      registerCard: map['registerCard'] ?? '0',
    );
  }
}
