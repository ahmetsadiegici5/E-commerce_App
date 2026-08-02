# E-Ticaret Uygulaması

Flutter ile geliştirilmiş, İyzico ödeme entegrasyonuna sahip bir e-ticaret uygulaması. Ürünler Firestore'dan listelenir, sepete eklenir ve ödeme İyzico'nun ödeme formu üzerinden alınır.

## Özellikler

- Firestore'dan canlı ürün listesi
- Sepet yönetimi (ekleme, adet azaltma, geri alma)
- Adres seçimi ve yeni adres ekleme
- İyzico Checkout Form ile ödeme (taksit seçenekleri, 3D Secure)
- Ödeme sonucunun uygulama içinde gösterilmesi

## Ödeme akışı

İyzico anahtarları uygulamada değil, Firebase Cloud Functions üzerinde çalışan bir Express API'de tutulur.

1. Uygulama sepetteki ürünlerin sadece id ve adet bilgisini API'ye gönderir.
2. API ürün fiyatlarını Firestore'dan okuyarak toplam tutarı kendisi hesaplar. Böylece istemci tarafında fiyat değiştirilemez.
3. İyzico'dan alınan ödeme sayfası uygulama içinde WebView ile açılır.
4. Ödeme tamamlanınca sonuç token ile API üzerinden sorgulanır ve kullanıcıya gösterilir.

Kart bilgileri uygulamaya veya sunucuya hiç gelmez; doğrudan İyzico'nun sayfasında girilir.

## Kullanılan teknolojiler

- **Mobil / Web:** Flutter, Dart, Provider
- **Backend:** Firebase Cloud Functions, Node.js, Express
- **Veritabanı:** Cloud Firestore
- **Ödeme:** İyzico
- **Test:** flutter_test, Node test runner, GitHub Actions

## Proje yapısı

```
my_e_commerce_app/
├── lib/
│   ├── models/      # Ürün, sepet, adres modelleri
│   ├── screens/     # Sepet, ödeme, adres ve sonuç ekranları
│   ├── services/    # Ödeme API istemcisi
│   └── widgets/
├── functions/       # Ödeme API'si (Express + İyzico)
└── test/
```

## Kurulum

Gereksinimler: Flutter 3.x, Node.js 20, Firebase CLI ve bir İyzico sandbox hesabı.

```bash
cd my_e_commerce_app
flutter pub get

cd functions
npm install
cp .env.example .env   # İyzico sandbox anahtarları ve callback adresi
firebase deploy --only functions
cd ..

flutter run -d chrome --dart-define=PAYMENT_API_URL=<functions adresi>
```

Testler:

```bash
flutter test
cd functions && npm test
```

Sandbox ortamında `5528790000000008` numaralı test kartı (12/30, CVV 123) ile ödeme denenebilir.
