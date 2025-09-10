# İyzico Ödeme Entegrasyonlu E-Ticaret Uygulaması

Bu Flutter projesi, İyzico ödeme altyapısı ile entegre edilmiş tam fonksiyonel bir e-ticaret uygulamasıdır.

## Özellikler

- Flutter Web üzerinde çalışan modern arayüz
- Firebase Functions ile backend entegrasyonu
- İyzico ödeme API entegrasyonu
- Adres yönetimi
- Alışveriş sepeti sistemi
- Otomatik ödeme sonucu algılama

## İyzico Test Kartları

Sandbox ortamında test işlemleri için aşağıdaki test kartları kullanılabilir:

| Kart Numarası         | Son Kullanma | CVV | 3D Secure | Açıklama                       |
|-----------------------|--------------|-----|-----------|--------------------------------|
| 5528790000000008      | 12/30        | 123 | Başarılı  | Genel başarılı ödeme           |
| 4603450000000000      | 12/30        | 123 | Başarılı  | Başarılı AMEX ödeme            |
| 4729150000000005      | 12/30        | 123 | Başarılı  | Başarılı VISA ödeme            |
| 4987490000000002      | 12/30        | 123 | Başarılı  | Başarılı VISA ödeme            |
| 5311570000000005      | 12/30        | 123 | Başarılı  | Başarılı MASTERCARD ödeme      |
| 5170410000000004      | 12/30        | 123 | Başarısız | İşlem onaylama hatası          |
| 4766620000000001      | 12/30        | 123 | Başarısız | İşlem onaylama hatası          |
| 4987490000000044      | 12/30        | 123 | Başarılı  | Yetersiz bakiye                |
| 5528790000000008      | 12/30        | 124 | Başarılı  | CVC hatalı                     |
| 5528790000000008      | 11/30        | 123 | Başarılı  | Son kullanma tarihi hatalı     |
| 4129090000000000      | 12/30        | 123 | Başarılı  | Kart sahibi bilgisi tanımsız   |
| 4159560000000008      | 12/30        | 123 | Başarılı  | Desteklenmeyen kart            |

## Sandbox Davranışı Hakkında Not

İyzico sandbox ortamında, test kartlarında hata durumları için belirtilmiş olsa bile işlemler genelde "başarılı" olarak görünür. Gerçek hata durumunu yakalamak için `status` yanında `errorCode` ve `errorMessage` alanlarını da kontrol etmeniz gerekir.

## Kurulum

1. Bu projeyi klonlayın
2. İçine Flutter paketlerini yükleyin: `flutter pub get`
3. Firebase Functions klasörüne geçin ve bağımlılıkları yükleyin: `cd functions && npm install`
4. İyzico API anahtarlarınızı Firebase Functions içindeki ilgili dosyalara ekleyin
5. Firebase Functions'ı dağıtın: `firebase deploy --only functions`
6. Uygulamayı çalıştırın: `flutter run -d chrome`

## Geliştirme

Bu proje Flutter 3.x ile geliştirilmiş olup, Firebase ve İyzico servislerini kullanmaktadır. Geliştirme yapmak için Firebase ve İyzico hesaplarına ihtiyacınız olacaktır.
