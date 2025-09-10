import 'package:flutter/material.dart';
import '../models/user.dart';

class AddressFormScreen extends StatefulWidget {
  final UserAddress? address;
  final Function(UserAddress) onSave;

  const AddressFormScreen({
    super.key, 
    this.address,
    required this.onSave,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _id;
  late String _title;
  late String _fullAddress;
  late String _city;
  late String _country;
  late String _zipCode;
  late double _latitude;
  late double _longitude;

  @override
  void initState() {
    super.initState();
    // Eğer düzenleme moduysa varolan adresi doldur
    if (widget.address != null) {
      _id = widget.address!.id;
      _title = widget.address!.title;
      _fullAddress = widget.address!.fullAddress;
      _city = widget.address!.city ?? '';
      _country = widget.address!.country ?? 'Turkey';
      _zipCode = widget.address!.zipCode ?? '';
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
    } else {
      // Yeni adres için varsayılan değerler
      _id = DateTime.now().millisecondsSinceEpoch.toString();
      _title = '';
      _fullAddress = '';
      _city = '';
      _country = 'Turkey';
      _zipCode = '';
      _latitude = 0.0;
      _longitude = 0.0;
    }
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final address = UserAddress(
        id: _id,
        title: _title,
        fullAddress: _fullAddress,
        city: _city,
        country: _country,
        zipCode: _zipCode,
        latitude: _latitude,
        longitude: _longitude,
      );
      
      widget.onSave(address);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Yeni Adres Ekle' : 'Adresi Düzenle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(
                    labelText: 'Adres Başlığı',
                    helperText: 'Örn: Ev, İş, Yazlık',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir adres başlığı girin';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _title = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _fullAddress,
                  decoration: const InputDecoration(
                    labelText: 'Açık Adres',
                    helperText: 'Mahalle, Cadde, Sokak, No, Daire vb.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen açık adres girin';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _fullAddress = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _city,
                  decoration: const InputDecoration(
                    labelText: 'Şehir',
                    helperText: 'Örn: İstanbul, Ankara, İzmir',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şehir girin';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _city = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _country,
                  decoration: const InputDecoration(
                    labelText: 'Ülke',
                    helperText: 'Örn: Turkey',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen ülke girin';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _country = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _zipCode,
                  decoration: const InputDecoration(
                    labelText: 'Posta Kodu',
                    helperText: 'Örn: 34000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen posta kodu girin';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _zipCode = value;
                  },
                ),
                const SizedBox(height: 16),
                // Konum alanları (opsiyonel olarak harita entegrasyonu eklenebilir)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _latitude.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Enlem',
                          helperText: 'Opsiyonel',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _latitude = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _longitude.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Boylam',
                          helperText: 'Opsiyonel',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _longitude = double.tryParse(value) ?? 0.0;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saveAddress,
                    child: const Text('ADRESİ KAYDET'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
