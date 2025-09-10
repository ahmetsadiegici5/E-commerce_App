import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/cart.dart';
import '../services/firebase_payment_service.dart';
import '../models/iyzipay/iyzipay_address.dart';
import '../widgets/test_card_info.dart';
import './address_form_screen.dart';
import './checkout_form_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  UserAddress? _selectedAddress;
  bool _isLoading = false;
  
  // Test için adres listesi - normalde bu liste Firestore'dan getirilir
  List<UserAddress> testAddresses = [
      UserAddress(
        id: '1',
        title: 'Ev',
        fullAddress: 'Atatürk Mah. Cumhuriyet Cad. No:123 Daire:5',
        city: 'İstanbul',
        country: 'Turkey',
        zipCode: '34000',
        latitude: 41.0082,
        longitude: 28.9784,
      ),
      UserAddress(
        id: '2',
        title: 'İş',
        fullAddress: 'Levent Mah. İş Cad. No:45 Kat:3',
        city: 'İstanbul',
        country: 'Turkey',
        zipCode: '34394',
        latitude: 41.0784,
        longitude: 29.0082,
      ),
  ];

  // Yeni adres eklemek için form gösterme
  void _showAddressForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddressFormScreen(
          onSave: (newAddress) {
            setState(() {
              testAddresses.add(newAddress);
              _selectedAddress = newAddress; // Yeni adresi seçili yap
            });
          },
        ),
      ),
    );
  }
  
  // Var olan adresi düzenlemek için form gösterme
  void _editAddress(BuildContext context, UserAddress address) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddressFormScreen(
          address: address,
          onSave: (updatedAddress) {
            setState(() {
              // Mevcut adresi güncelle
              final index = testAddresses.indexWhere((a) => a.id == updatedAddress.id);
              if (index >= 0) {
                testAddresses[index] = updatedAddress;
                _selectedAddress = updatedAddress;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sipariş Özeti',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Toplam Ürün:'),
                                Text('${cart.itemCount} ürün'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Toplam Tutar:'),
                                Text(
                                  '${cart.totalAmount.toStringAsFixed(2)} TL',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Test kart bilgileri - İyzico resmi test kartları
                    const TestCardInfo(),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Adres Seçimi',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Yeni Adres'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showAddressForm(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserAddress>(
                      decoration: const InputDecoration(
                        labelText: 'Teslimat Adresi',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedAddress,
                      hint: const Text('Adres seçin'),
                      items: testAddresses
                          .map((address) => DropdownMenuItem(
                                value: address,
                                child: Text('${address.title} - ${address.fullAddress.length > 30 ? "${address.fullAddress.substring(0, 30)}..." : address.fullAddress} (${address.city})'),
                              ))
                          .toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Lütfen bir adres seçin';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedAddress = value;
                        });
                      },
                    ),
                    if (_selectedAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Adresi Düzenle'),
                          onPressed: () => _editAddress(context, _selectedAddress!),
                        ),
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => _processCheckoutFormPayment(cart),
                        child: const Text('İYZİCO İLE ÖDEME YAP'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }


  
  // Checkout Form ile ödeme işlemi
  void _processCheckoutFormPayment(Cart cart) async {
    if (!_formKey.currentState!.validate() || _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun ve bir adres seçin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final paymentService = FirebasePaymentService();
      
      // Checkout form için token al
      final checkoutFormContent = await paymentService.getCheckoutFormToken(
        userId: 'test_user', // Gerçek uygulamada kullanıcı ID'si buraya gelecek
        items: cart.items,
        totalAmount: cart.totalAmount,
        billingAddress: _createIyzipayAddress(_selectedAddress!),
        shippingAddress: _createIyzipayAddress(_selectedAddress!),
      );

      if (!mounted) return;

      // Checkout form ekranını aç
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => CheckoutFormScreen(
            checkoutFormUrl: checkoutFormContent,
          ),
        ),
      );

      if (result == true) {
        // Başarılı ödeme
        cart.clear(); // Sepeti temizle
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme başarıyla tamamlandı')),
        );
      } else {
        // Başarısız ödeme
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme işlemi başarısız oldu')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // UserAddress'i İyzipay formatına dönüştür
  IyzipayAddress _createIyzipayAddress(UserAddress address) {
    return IyzipayAddress(
      id: address.id,
      title: address.title,
      fullAddress: address.fullAddress,
      city: address.city ?? 'İstanbul',
      country: address.country ?? 'Turkey',
      zipCode: address.zipCode ?? '34000',
      latitude: address.latitude,
      longitude: address.longitude,
    );
  }
}
