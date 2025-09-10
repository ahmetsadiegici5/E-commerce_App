import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stok kontrolü
  Future<bool> checkStock(String productId, int requestedQuantity) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (!doc.exists) return false;

    final currentStock = doc.data()!['stock'] as int;
    return currentStock >= requestedQuantity;
  }

  // Stok güncelleme
  Future<void> updateStock(String productId, int quantity) async {
    final docRef = _firestore.collection('products').doc(productId);

    return _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw Exception('Ürün bulunamadı');
      }

      final currentStock = doc.data()!['stock'] as int;
      final newStock = currentStock - quantity;

      if (newStock < 0) {
        throw Exception('Yetersiz stok');
      }

      transaction.update(docRef, {'stock': newStock});
    });
  }

  // Düşük stok kontrolü
  Future<List<Map<String, dynamic>>> checkLowStock({int threshold = 10}) async {
    final querySnapshot = await _firestore
        .collection('products')
        .where('stock', isLessThanOrEqualTo: threshold)
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'productId': doc.id,
              'name': doc.data()['name'],
              'stock': doc.data()['stock'],
            })
        .toList();
  }

  // Toplu stok güncelleme
  Future<void> bulkUpdateStock(List<Map<String, dynamic>> updates) async {
    final batch = _firestore.batch();

    for (var update in updates) {
      final docRef = _firestore.collection('products').doc(update['productId']);
      batch.update(docRef, {'stock': update['quantity']});
    }

    await batch.commit();
  }

  // Stok geçmişi kaydetme
  Future<void> logStockChange({
    required String productId,
    required int oldQuantity,
    required int newQuantity,
    required String reason,
    String? orderId,
  }) async {
    await _firestore.collection('stock_logs').add({
      'productId': productId,
      'oldQuantity': oldQuantity,
      'newQuantity': newQuantity,
      'reason': reason,
      'orderId': orderId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
