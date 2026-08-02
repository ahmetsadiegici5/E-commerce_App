const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const Iyzipay = require('iyzipay');
const { buildBasket, BasketError } = require('./basket');

admin.initializeApp();
const db = admin.firestore();

const {
  IYZICO_API_KEY,
  IYZICO_SECRET_KEY,
  IYZICO_BASE_URL = 'https://sandbox-api.iyzipay.com',
  PAYMENT_CALLBACK_URL,
  ALLOWED_ORIGINS,
} = process.env;

const iyzipay = IYZICO_API_KEY && IYZICO_SECRET_KEY
  ? new Iyzipay({ apiKey: IYZICO_API_KEY, secretKey: IYZICO_SECRET_KEY, uri: IYZICO_BASE_URL })
  : null;

const app = express();
app.use(cors({ origin: ALLOWED_ORIGINS ? ALLOWED_ORIGINS.split(',') : true }));
app.use(express.json({ limit: '50kb' }));

app.use((req, res, next) => {
  if (req.method === 'POST' && !iyzipay) {
    console.error('İyzico anahtarları tanımlı değil (IYZICO_API_KEY / IYZICO_SECRET_KEY).');
    return res.status(503).json({ status: 'error', errorMessage: 'Ödeme servisi yapılandırılmamış.' });
  }
  next();
});

// İyzico SDK callback tabanlı çalıştığı için Promise'e çevriliyor
const call = (resource, method, request) => new Promise((resolve, reject) => {
  resource[method](request, (err, result) => (err ? reject(err) : resolve(result)));
});

async function loadProducts(productIds) {
  const refs = [...new Set(productIds)].map((id) => db.collection('products').doc(String(id)));
  const snapshots = refs.length ? await db.getAll(...refs) : [];
  return new Map(snapshots.filter((s) => s.exists).map((s) => [s.id, s.data()]));
}

function toIyzicoAddress(address = {}, contactName) {
  if (!address.address || !address.city) {
    throw new BasketError('Teslimat adresi ve şehir zorunludur.');
  }
  return {
    contactName,
    address: address.address,
    city: address.city,
    country: address.country || 'Turkey',
    zipCode: address.zipCode,
  };
}

app.get('/', (req, res) => {
  res.json({ status: 'ok', endpoints: ['/create-checkout-form', '/retrieve-checkout-form'] });
});

app.post('/create-checkout-form', async (req, res) => {
  try {
    const { items, address, buyer = {} } = req.body || {};
    const products = await loadProducts((items || []).map((i) => i.productId));
    const { price, basketItems } = buildBasket(items, products);

    const name = buyer.name || 'Misafir';
    const surname = buyer.surname || 'Kullanıcı';
    const iyziAddress = toIyzicoAddress(address, `${name} ${surname}`);
    const conversationId = `conv_${Date.now()}`;

    const result = await call(iyzipay.checkoutFormInitialize, 'create', {
      locale: Iyzipay.LOCALE.TR,
      conversationId,
      price,
      paidPrice: price,
      currency: Iyzipay.CURRENCY.TRY,
      basketId: conversationId,
      paymentGroup: Iyzipay.PAYMENT_GROUP.PRODUCT,
      callbackUrl: PAYMENT_CALLBACK_URL,
      enabledInstallments: [1, 2, 3, 6, 9, 12],
      buyer: {
        id: buyer.id || 'guest',
        name,
        surname,
        email: buyer.email || 'guest@example.com',
        // Sandbox için test kimlik numarası; canlı ortamda kullanıcıdan alınmalı
        identityNumber: '11111111111',
        registrationAddress: iyziAddress.address,
        city: iyziAddress.city,
        country: iyziAddress.country,
        ip: req.ip,
      },
      shippingAddress: iyziAddress,
      billingAddress: iyziAddress,
      basketItems,
    });

    if (result.status !== 'success') {
      console.warn('Checkout form oluşturulamadı:', result.errorCode, result.errorMessage);
      return res.status(502).json({
        status: 'error',
        errorCode: result.errorCode,
        errorMessage: result.errorMessage,
      });
    }

    res.json({
      status: 'success',
      token: result.token,
      paymentPageUrl: result.paymentPageUrl,
      checkoutFormContent: result.checkoutFormContent,
      price,
    });
  } catch (error) {
    if (error instanceof BasketError) {
      return res.status(400).json({ status: 'error', errorMessage: error.message });
    }
    console.error('create-checkout-form hatası:', error.message || error);
    res.status(500).json({ status: 'error', errorMessage: 'Ödeme başlatılamadı.' });
  }
});

app.post('/retrieve-checkout-form', async (req, res) => {
  const { token } = req.body || {};
  if (!token) {
    return res.status(400).json({ status: 'error', errorMessage: 'token zorunludur.' });
  }

  try {
    const result = await call(iyzipay.checkoutForm, 'retrieve', { locale: Iyzipay.LOCALE.TR, token });
    res.json({
      status: result.status,
      paymentStatus: result.paymentStatus,
      paymentId: result.paymentId,
      basketId: result.basketId,
      paidPrice: result.paidPrice,
      errorCode: result.errorCode,
      errorMessage: result.errorMessage,
    });
  } catch (error) {
    console.error('retrieve-checkout-form hatası:', error.message || error);
    res.status(500).json({ status: 'error', errorMessage: 'Ödeme sonucu alınamadı.' });
  }
});

exports.paymentApi = functions.https.onRequest(app);
