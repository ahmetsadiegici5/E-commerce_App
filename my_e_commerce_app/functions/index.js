const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors')({ 
    origin: '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-IYZI-RND']
});
const Iyzipay = require('iyzipay');
// dotenv paketini import ediyoruz ve hemen yapılandırıyoruz
require('dotenv').config();

admin.initializeApp();

// İyzico nesnesini başlatmak için güvenli fonksiyon
function initializeIyzico() {
    try {
        // process.env'den doğrudan çevresel değişkenlere erişim
        const iyziConfig = {
            apiKey: process.env.IYZICO_API_KEY,
            secretKey: process.env.IYZICO_SECRET_KEY,
            uri: 'https://sandbox-api.iyzipay.com'
        };
        
        if (!iyziConfig.apiKey || !iyziConfig.secretKey) {
            console.error('İyzico API key veya secret key environment içinde eksik.');
            return null;
        }
        
        console.log('İyzico SDK başarıyla yapılandırıldı.');
        return new Iyzipay(iyziConfig);
    } catch (e) {
        console.error('Kritik yapılandırma hatası:', e);
        return null;
    }
}

const iyzipay = initializeIyzico();

const app = express();
app.use(cors);
app.use(express.json());

// Yapılandırma kontrolü için bir ara katman (middleware)
const checkIyzicoConfig = (req, res, next) => {
    if (!iyzipay) {
        console.error('İyzico yapılandırması yüklenemediği için istek işlenemiyor.');
        return res.status(500).send({
            status: 'error',
            message: 'Sunucu tarafında ödeme altyapısı yapılandırması eksik.'
        });
    }
    next();
};

app.get('/', (req, res) => {
    res.status(200).json({
        status: 'success',
        message: 'İyzico Ödeme API aktif',
        endpoints: [
            '/create-payment',
            '/initialize-3ds',
            '/complete-3ds'
        ]
    });
});

app.post('/create-payment', checkIyzicoConfig, (req, res) => {
    try {
        console.log('[DEBUG] Ödeme isteği başlangıç noktası');
        console.log('[INFO] Ödeme isteği alındı:', JSON.stringify(req.body));
        
        // Her istekte yeni bir Iyzipay instance oluşturuyoruz
        const freshIyzipay = initializeIyzico();
        if (!freshIyzipay) {
            console.error('[FATAL] İyzipay instance oluşturulamadı');
            return res.status(500).send({
                status: 'error',
                errorCode: 'IYZICO_INIT_ERROR',
                message: 'Ödeme servisi başlatılamadı',
            });
        }
        
        // İstek doğru formatta mı kontrol et
        if (!req.body.price || !req.body.paidPrice || !req.body.paymentCard) {
            console.error('[ERROR] Eksik parametreler:', JSON.stringify({
                hasPrice: !!req.body.price,
                hasPaidPrice: !!req.body.paidPrice,
                hasPaymentCard: !!req.body.paymentCard
            }));
            return res.status(400).send({
                status: 'error', 
                errorCode: 'MISSING_PARAMS',
                message: 'Eksik veya hatalı ödeme parametreleri'
            });
        }
        
        // Adres bilgilerini kontrol et
        if (!req.body.shippingAddress || !req.body.billingAddress) {
            console.error('[ERROR] Adres bilgileri eksik');
            return res.status(400).send({
                status: 'error',
                errorCode: 'ADDRESS_MISSING',
                message: 'Teslimat ve fatura adresi zorunludur'
            });
        }
        
        // Adres bilgilerinde şehir kontrolü
        const shippingAddress = req.body.shippingAddress;
        const billingAddress = req.body.billingAddress;
        
        if (!shippingAddress.city) {
            console.error('[ERROR] Shipping address city alanı eksik');
            return res.status(400).send({
                status: 'error',
                errorCode: 'SHIPPING_CITY_MISSING',
                message: 'Shipping address city gönderilmesi zorunludur'
            });
        }
        
        if (!billingAddress.city) {
            console.error('[ERROR] Billing address city alanı eksik');
            return res.status(400).send({
                status: 'error',
                errorCode: 'BILLING_CITY_MISSING',
                message: 'Billing address city gönderilmesi zorunludur'
            });
        }
        
        // installments parametresi Flutter'dan 'installment' olarak gelebilir (tekil/çoğul farkı)
        // Kesinlikle sayıya çevirerek kullanmaya dikkat edelim
        let installments = 1; // Varsayılan değer
        
        if (req.body.installment !== undefined && req.body.installment !== null) {
            // installment varsa, sayı olarak al
            installments = parseInt(req.body.installment);
        } else if (req.body.installments !== undefined && req.body.installments !== null) {
            // installments varsa, sayı olarak al
            installments = parseInt(req.body.installments);
        }
        
        // Hata durumunda varsayılana dön
        if (isNaN(installments) || installments <= 0) {
            console.log(`[WARNING] Geçersiz installment değeri, varsayılan 1 kullanılıyor`);
            installments = 1;
        }
        
        console.log(`[DEBUG] Installments değeri: ${installments}, Tip: ${typeof installments}`);
        
        const request = {
            locale: Iyzipay.LOCALE.TR,
            conversationId: req.body.conversationId || `conv-${Date.now()}`,
            price: req.body.price,
            paidPrice: req.body.paidPrice,
            currency: Iyzipay.CURRENCY.TRY,
            installment: parseInt(installments), // Sayı olarak dönüştürüldü
            basketId: req.body.basketId,
            paymentCard: req.body.paymentCard,
            buyer: req.body.buyer,
            shippingAddress: req.body.shippingAddress,
            billingAddress: req.body.billingAddress,
            basketItems: req.body.basketItems
        };
        
        console.log('[INFO] İyzipay istek hazırlandı:', JSON.stringify(request));
        console.log('[DEBUG] Kritik alanların kontrolü:');
        console.log('- conversationId:', request.conversationId);
        console.log('- price:', request.price);
        console.log('- paidPrice:', request.paidPrice);
        console.log('- installment:', request.installment);
        console.log('- paymentCard.cardNumber (ilk 6):', request.paymentCard?.cardNumber?.substring(0, 6) + '******');
        console.log('- shippingAddress.city:', request.shippingAddress?.city);
        console.log('- billingAddress.city:', request.billingAddress?.city);
        
        freshIyzipay.payment.create(request, function (err, result) {
            if (err) {
                console.error('[ERROR] İyzico Ödeme Hatası:', JSON.stringify(err));
                return res.status(err.status || 400).send({
                    status: 'error',
                    errorCode: err.errorCode,
                    errorMessage: err.errorMessage || 'İyzipay API hatası',
                    errorDetails: JSON.stringify(err)
                });
            }
            
            console.log('[SUCCESS] İyzico Ödeme Başarılı:', JSON.stringify(result));
            res.status(200).send(result);
        });
    } catch (error) {
        console.error('[FATAL] Ödeme isteği işlenirken beklenmedik hata:', error.message);
        console.error('[FATAL] Hata stacktrace:', error.stack);
        
        // Tüm istek detaylarını hata loguna ekle
        try {
            console.error('[DEBUG] İstek içeriği:', JSON.stringify({
                headers: req.headers,
                body: req.body,
                query: req.query
            }));
        } catch (e) {
            console.error('[DEBUG] İstek içeriği loglanamadı:', e.message);
        }
        
        res.status(500).send({
            status: 'error',
            errorCode: 'UNHANDLED_EXCEPTION',
            message: 'İstek işlenirken beklenmedik bir sunucu hatası oluştu.',
            errorDetails: error.message
        });
    }
});

app.post('/initialize-3ds', checkIyzicoConfig, (req, res) => {
    try {
        console.log('3D Secure başlatma isteği alındı:', JSON.stringify(req.body));
        
        const request = {
            locale: Iyzipay.LOCALE.TR,
            conversationId: req.body.conversationId || `conv-${Date.now()}`,
            price: req.body.price,
            paidPrice: req.body.paidPrice,
            currency: Iyzipay.CURRENCY.TRY,
            installments: req.body.installments || 1,
            paymentCard: req.body.paymentCard,
            buyer: req.body.buyer,
            shippingAddress: req.body.shippingAddress,
            billingAddress: req.body.billingAddress,
            basketItems: req.body.basketItems,
            callbackUrl: req.body.callbackUrl
        };
        
        console.log('İyzipay 3DS istek gönderiliyor:', JSON.stringify(request));
        
        iyzipay.payment.threeDsInitialize(request, (err, result) => {
            if (err) {
                console.error('[ERROR] İyzico 3D Secure Başlatma Hatası:', JSON.stringify(err));
                return res.status(err.status || 400).send(err);
            }
            console.log('[SUCCESS] 3D Secure Başlatma Başarılı:', JSON.stringify(result));
            res.status(200).send(result);
        });
    } catch (error) {
        console.error('[FATAL] 3D Secure başlatma isteği işlenirken beklenmedik hata:', error.message);
        res.status(500).send({
            status: 'error',
            message: 'İstek işlenirken beklenmedik bir sunucu hatası oluştu.',
            errorDetails: error.message
        });
    }
});

// Checkout Form oluşturma endpoint'i
app.post('/create-checkout-form', checkIyzicoConfig, (req, res) => {
    try {
        console.log('====== CHECKOUT FORM İSTEĞİ BAŞLANGICI ======');
        console.log('Checkout Form isteği alındı:', JSON.stringify(req.body));
        
        const checkoutFormRequest = {
            locale: req.body.locale || Iyzipay.LOCALE.TR,
            conversationId: req.body.conversationId,
            price: req.body.price,
            paidPrice: req.body.paidPrice,
            currency: req.body.currency || Iyzipay.CURRENCY.TRY,
            basketId: req.body.basketId,
            paymentGroup: req.body.paymentGroup || Iyzipay.PAYMENT_GROUP.PRODUCT,
            callbackUrl: req.body.callbackUrl || 'https://your-app-domain.com/payment-result',
            enabledInstallments: [1, 2, 3, 6, 9, 12],
            buyer: req.body.buyer,
            shippingAddress: req.body.shippingAddress,
            billingAddress: req.body.billingAddress,
            basketItems: req.body.basketItems
        };

        console.log('====== IYZICO API İSTEĞİ ======');
        console.log('İyzipay Checkout Form isteği gönderiliyor:', JSON.stringify(checkoutFormRequest));
        console.log('İyzico API Key:', process.env.IYZICO_API_KEY ? 'MEVCUT' : 'EKSİK');
        console.log('İyzico Secret Key:', process.env.IYZICO_SECRET_KEY ? 'MEVCUT' : 'EKSİK');

        iyzipay.checkoutFormInitialize.create(checkoutFormRequest, (err, result) => {
            console.log('====== IYZICO API YANITI ======');
            
            if (err) {
                console.error('[ERROR] İyzico Checkout Form Hatası:', JSON.stringify(err));
                console.error('[ERROR] Hata detayları:', {
                    status: err.status,
                    errorCode: err.errorCode,
                    errorMessage: err.errorMessage,
                    errorGroup: err.errorGroup
                });
                
                // Geliştirme amaçlı sahte yanıt döndürelim ama gerçek hata bilgisiyle
                return res.status(200).send({
                    status: 'success',
                    checkoutFormContent: `<div style="padding: 20px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; color: #856404;">
                        <h3>⚠️ İyzico API Hatası Tespit Edildi</h3>
                        <p><strong>Hata Kodu:</strong> ${err.errorCode || 'Bilinmiyor'}</p>
                        <p><strong>Hata Mesajı:</strong> ${err.errorMessage || 'Detay yok'}</p>
                        <p><strong>Hata Grubu:</strong> ${err.errorGroup || 'Belirtilmemiş'}</p>
                        <p><strong>HTTP Status:</strong> ${err.status || 'Belirtilmemiş'}</p>
                        <hr>
                        <p>Bu bir test mesajıdır. Gerçek İyzico formu için API konfigürasyonunu kontrol edin.</p>
                        <button onclick="window.close()" style="background: #dc3545; color: white; border: none; padding: 10px 20px; border-radius: 3px; cursor: pointer;">Kapat</button>
                    </div>`,
                    error: {
                        code: err.errorCode,
                        message: err.errorMessage,
                        group: err.errorGroup,
                        status: err.status
                    }
                });
            }
            
            console.log('[SUCCESS] İyzico Checkout Form API Yanıtı:', JSON.stringify(result));
            
            if (result && result.status === 'success') {
                console.log('[✅] GERÇEK IYZICO FORMU ALINDI');
                console.log('Checkout Form Content uzunluğu:', result.checkoutFormContent ? result.checkoutFormContent.length : 0);
                
                res.status(200).send({
                    status: 'success',
                    checkoutFormContent: result.checkoutFormContent,
                    token: result.token,
                    paymentPageUrl: result.paymentPageUrl
                });
            } else {
                console.log('[❌] İyzico API başarısız yanıt döndü');
                console.log('Result:', JSON.stringify(result));
                
                // API başarısız olduğunda test mesajı döndür
                res.status(200).send({
                    status: 'success',
                    checkoutFormContent: `<div style="padding: 20px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 5px; color: #721c24;">
                        <h3>❌ İyzico API Başarısız Yanıt</h3>
                        <p><strong>API Status:</strong> ${result?.status || 'Bilinmiyor'}</p>
                        <p><strong>Hata Mesajı:</strong> ${result?.errorMessage || 'Detay yok'}</p>
                        <p><strong>Hata Kodu:</strong> ${result?.errorCode || 'Belirtilmemiş'}</p>
                        <hr>
                        <p>Bu bir test mesajıdır. İyzico API'sinden başarısız yanıt alındı.</p>
                        <button onclick="window.close()" style="background: #dc3545; color: white; border: none; padding: 10px 20px; border-radius: 3px; cursor: pointer;">Kapat</button>
                    </div>`,
                    error: {
                        message: result?.errorMessage,
                        code: result?.errorCode
                    }
                });
            }
        });
    } catch (error) {
        console.error('[FATAL] Checkout Form isteği işlenirken beklenmedik hata:', error.message);
        console.error('[FATAL] Stack trace:', error.stack);
        
        res.status(200).send({
            status: 'success',
            checkoutFormContent: `<div style="padding: 20px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 5px; color: #721c24;">
                <h3>💥 Sistem Hatası</h3>
                <p><strong>Hata:</strong> ${error.message}</p>
                <hr>
                <p>Bu bir test mesajıdır. Server tarafında beklenmedik hata oluştu.</p>
                <button onclick="window.close()" style="background: #dc3545; color: white; border: none; padding: 10px 20px; border-radius: 3px; cursor: pointer;">Kapat</button>
            </div>`,
            error: {
                message: error.message,
                type: 'SERVER_ERROR'
            }
        });
    }
});

app.post('/complete-3ds', checkIyzicoConfig, (req, res) => {
    try {
        console.log('3D Secure tamamlama isteği alındı:', JSON.stringify(req.body));
        
        const request = {
            locale: Iyzipay.LOCALE.TR,
            conversationId: req.body.conversationId,
            paymentId: req.body.paymentId,
            conversationData: req.body.conversationData
        };
        
        console.log('İyzipay 3DS tamamlama isteği gönderiliyor:', JSON.stringify(request));
        
        iyzipay.payment.threeDsCreate(request, (err, result) => {
            if (err) {
                console.error('[ERROR] İyzico 3D Secure Tamamlama Hatası:', JSON.stringify(err));
                return res.status(err.status || 400).send(err);
            }
            console.log('[SUCCESS] 3D Secure Tamamlama Başarılı:', JSON.stringify(result));
            res.status(200).send(result);
        });
    } catch (error) {
        console.error('[FATAL] 3D Secure tamamlama isteği işlenirken beklenmedik hata:', error.message);
        res.status(500).send({
            status: 'error',
            message: 'İstek işlenirken beklenmedik bir sunucu hatası oluştu.',
            errorDetails: error.message
        });
    }
});

exports.paymentApi = functions.https.onRequest(app);