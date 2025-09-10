class UserModel {
  final String id;
  final String name;
  final String email;
  final List<UserAddress> addresses;
  final String phoneNumber;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.addresses,
    required this.phoneNumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      addresses: List<UserAddress>.from(
          (map['addresses'] ?? []).map((x) => UserAddress.fromMap(x))),
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'addresses': addresses.map((x) => x.toMap()).toList(),
      'phoneNumber': phoneNumber,
    };
  }
}

class UserAddress {
  final String id;
  final String title;
  final String fullAddress;
  final String? city;
  final String? country;
  final String? zipCode;
  final double latitude;
  final double longitude;

  UserAddress({
    required this.id,
    required this.title,
    required this.fullAddress,
    this.city,
    this.country,
    this.zipCode,
    required this.latitude,
    required this.longitude,
  });

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      fullAddress: map['fullAddress'] ?? '',
      city: map['city'],
      country: map['country'],
      zipCode: map['zipCode'],
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fullAddress': fullAddress,
      'city': city,
      'country': country,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
