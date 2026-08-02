// Sepet tutarını istemciden gelen fiyatlarla değil, Firestore'daki ürün fiyatlarıyla hesaplar.

class BasketError extends Error {}

const MAX_QUANTITY = 99;

/**
 * @param {Array<{productId: string, quantity: number}>} items istemciden gelen sepet
 * @param {Map<string, {name: string, price: number, category?: string}>} products Firestore'daki ürünler
 * @returns {{ price: string, basketItems: object[] }}
 */
function buildBasket(items, products) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new BasketError('Sepet boş.');
  }

  let totalKurus = 0;
  const basketItems = items.map((item) => {
    const quantity = Number(item.quantity);
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > MAX_QUANTITY) {
      throw new BasketError(`Geçersiz adet: ${item.productId}`);
    }

    const product = products.get(item.productId);
    if (!product || typeof product.price !== 'number' || product.price <= 0) {
      throw new BasketError(`Ürün bulunamadı: ${item.productId}`);
    }

    // Kuruş üzerinden hesaplayarak ondalık hatalarını önle
    const lineKurus = Math.round(product.price * 100) * quantity;
    totalKurus += lineKurus;

    return {
      id: item.productId,
      name: product.name,
      category1: product.category || 'Genel',
      itemType: 'PHYSICAL',
      price: toPrice(lineKurus),
    };
  });

  return { price: toPrice(totalKurus), basketItems };
}

function toPrice(kurus) {
  return (kurus / 100).toFixed(2);
}

module.exports = { buildBasket, BasketError };
