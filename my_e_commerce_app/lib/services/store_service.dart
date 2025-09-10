import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart.dart';
import '../models/order.dart' as shop_order;
import '../models/product.dart';
import '../models/user.dart' show UserAddress;
import './firebase_payment_service.dart'; // Firebase Functions'a geçiş yaptık
import './inventory_service.dart';
import '../models/iyzipay/iyzipay_address.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InventoryService _inventoryService = InventoryService();

  // Ürünleri getir
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data()))
            .toList());
  }

  // Kategoriye göre ürünleri getir
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data()))
            .toList());
  }

  // Sepeti getir
  Future<Cart?> getCart(String userId) async {
    final doc = await _firestore.collection('carts').doc(userId).get();
    if (doc.exists) {
      return Cart.fromMap(doc.data()!);
    }
    return null;
  }

  // Sepete ürün ekle
  Future<void> addToCart(String userId, CartItem item) async {
    // Önce stok kontrolü yap
    final hasStock = await _inventoryService.checkStock(item.productId, item.quantity);
    if (!hasStock) {
      throw Exception('Yetersiz stok');
    }

    final cartRef = _firestore.collection('carts').doc(userId);
    final cart = await cartRef.get();

    if (cart.exists) {
      final existingCart = Cart.fromMap(cart.data()!);
      final items = existingCart.itemsList;
      
      final existingItemIndex = items.indexWhere((i) => i.productId == item.productId);
      if (existingItemIndex != -1) {
        // Mevcut ürünün miktarını artırırken stok kontrolü
        final newQuantity = items[existingItemIndex].quantity + item.quantity;
        final hasEnoughStock = await _inventoryService.checkStock(item.productId, newQuantity);
        if (!hasEnoughStock) {
          throw Exception('Yetersiz stok');
        }

        items[existingItemIndex] = CartItem(
          id: items[existingItemIndex].id,
          productId: items[existingItemIndex].productId,
          name: items[existingItemIndex].name,
          price: items[existingItemIndex].price,
          quantity: newQuantity,
          imageURL: items[existingItemIndex].imageURL,
        );
      } else {
        items.add(item);
      }

      final total = items.fold(0.0, (total, item) => total + (item.price * item.quantity));
      
      await cartRef.update({
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
      });
    } else {
      await cartRef.set({
        'userId': userId,
        'items': [item.toMap()],
        'total': item.price * item.quantity,
      });
    }
  }

  // Sepetten ürün çıkar
  Future<void> removeFromCart(String userId, String itemId) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    final cart = await cartRef.get();

    if (cart.exists) {
      final existingCart = Cart.fromMap(cart.data()!);
      final items = existingCart.itemsList;
      
      // Stok iade
      final removedItem = items.firstWhere((item) => item.id == itemId);
      await _inventoryService.updateStock(removedItem.productId, -removedItem.quantity);
      
      items.removeWhere((item) => item.id == itemId);

      final total = items.fold(0.0, (total, item) => total + (item.price * item.quantity));
      
      await cartRef.update({
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
      });
    }
  }

  // Sipariş oluştur
  Future<void> createOrder(shop_order.Order order) async {
    // Sipariş oluşturulurken stok güncelle
    for (var item in order.items) {
      await _inventoryService.updateStock(item.productId, item.quantity);
      
      await _inventoryService.logStockChange(
        productId: item.productId,
        oldQuantity: item.quantity,
        newQuantity: 0,
        reason: 'Sipariş',
        orderId: order.id,
      );
    }

    await _firestore.collection('orders').add(order.toMap());
  }

  // Ödeme işlemini gerçekleştir
  Future<PaymentResult> processPayment({
    required String userId,
    required Cart cart,
    required UserAddress billingAddress,
  }) async {
    // Tüm ürünler için stok kontrolü
    for (var item in cart.itemsList) {
      final hasStock = await _inventoryService.checkStock(item.productId, item.quantity);
      if (!hasStock) {
        throw Exception('Yetersiz stok: ${item.name}');
      }
    }

    final paymentService = FirebasePaymentService();
    
    // Adresin gerekli tüm alanlarını kontrol et ve varsayılan değerler ata
    UserAddress completeAddress = billingAddress;
    if (completeAddress.city == null || completeAddress.city!.isEmpty) {
      throw Exception('Geçerli bir şehir bilgisi gereklidir');
    }
    if (completeAddress.country == null || completeAddress.country!.isEmpty) {
      throw Exception('Geçerli bir ülke bilgisi gereklidir');
    }
    
    try {
      final result = await paymentService.processPayment(
        userId: userId,
        items: cart.itemsList,
        totalAmount: cart.totalAmount,
        billingAddress: IyzipayAddress.fromUserAddress(completeAddress),
        shippingAddress: IyzipayAddress.fromUserAddress(completeAddress),
      );
      
      if (result.success) {
        final order = shop_order.Order(
          id: result.transactionId!,
          userId: userId,
          items: cart.itemsList,
          total: cart.totalAmount,
          status: 'processing',
          orderDate: DateTime.now(),
          shippingAddress: billingAddress,
          paymentMethod: 'credit_card',
          trackingNumber: '',
        );

        await createOrder(order);
        await clearCart(userId);
      }
      
      return result;
    } catch (error) {
      return PaymentResult(
        success: false,
        message: 'Ödeme işlemi sırasında bir hata oluştu: ${error.toString()}'
      );
    }
  }

  // Sepeti temizle
  Future<void> clearCart(String userId) async {
    await _firestore.collection('carts').doc(userId).delete();
  }

  // Siparişleri getir
  Stream<List<shop_order.Order>> getOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => shop_order.Order.fromMap(doc.data()))
            .toList());
  }

  // Düşük stoklu ürünleri kontrol et
  Future<List<Map<String, dynamic>>> checkLowStockProducts() async {
    return await _inventoryService.checkLowStock();
  }
}
