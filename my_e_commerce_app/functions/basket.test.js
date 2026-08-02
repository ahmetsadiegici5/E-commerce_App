const test = require('node:test');
const assert = require('node:assert');
const { buildBasket, BasketError } = require('./basket');

const products = new Map([
  ['p1', { name: 'Kalem', price: 12.5 }],
  ['p2', { name: 'Defter', price: 0.1, category: 'Kırtasiye' }],
]);

test('tutarı Firestore fiyatlarından hesaplar', () => {
  const { price, basketItems } = buildBasket(
    [{ productId: 'p1', quantity: 2 }, { productId: 'p2', quantity: 3 }],
    products,
  );
  assert.strictEqual(price, '25.30');
  assert.deepStrictEqual(basketItems.map((i) => i.price), ['25.00', '0.30']);
  assert.strictEqual(basketItems[1].category1, 'Kırtasiye');
});

test('istemciden gelen fiyatı yok sayar', () => {
  const { price } = buildBasket([{ productId: 'p1', quantity: 1, price: 0.01 }], products);
  assert.strictEqual(price, '12.50');
});

test('bilinmeyen ürün veya geçersiz adet reddedilir', () => {
  assert.throws(() => buildBasket([{ productId: 'yok', quantity: 1 }], products), BasketError);
  assert.throws(() => buildBasket([{ productId: 'p1', quantity: 0 }], products), BasketError);
  assert.throws(() => buildBasket([{ productId: 'p1', quantity: 1.5 }], products), BasketError);
  assert.throws(() => buildBasket([], products), BasketError);
});
