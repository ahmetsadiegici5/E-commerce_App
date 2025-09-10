import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/cart.dart';
import 'screens/cart_screen.dart';
import 'screens/firebase_payment_test_screen.dart';
import 'screens/test_payment_debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase zaten initialize edilmiş olabilir
    debugPrint('Firebase already initialized: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => Cart(),
      child: MaterialApp(
        title: 'E-Ticaret Uygulaması',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          // Firebase ödeme testi butonu
          IconButton(
            icon: const Icon(Icons.cloud),
            tooltip: 'Firebase Ödeme Testi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FirebasePaymentTestScreen(),
                ),
              );
            },
          ),
          // Debug ödeme testi butonu
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Ödeme Debug Testi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TestPaymentDebugScreen(),
                ),
              );
            },
          ),
          Consumer<Cart>(
            builder: (_, cart, child) => Badge(
              label: Text(cart.itemCount.toString()),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir şeyler ters gitti.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Veritabanında ürün bulunamadı.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              
              // URL'i temizle - çift tırnak varsa kaldır
              String imageUrl = data['imageURL'] ?? '';
              if (imageUrl.startsWith('"') && imageUrl.endsWith('"')) {
                imageUrl = imageUrl.substring(1, imageUrl.length - 1);
              }
              
              return ListTile(
                leading: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(data['name']),
                subtitle: Text('Fiyat: ${data['price']} TL'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () {
                    Provider.of<Cart>(context, listen: false).addItem(
                      productId: document.id,
                      name: data['name'],
                      price: data['price'].toDouble(),
                      imageURL: imageUrl, // Temizlenmiş URL'i kullan
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${data['name']} sepete eklendi'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'GERİ AL',
                          onPressed: () {
                            Provider.of<Cart>(context, listen: false)
                                .removeItem(document.id);
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}