import '../user.dart' show UserAddress;

class IyzipayAddress {
  final String id;
  final String title;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String zipCode;

  IyzipayAddress({
    required this.id,
    required this.title,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.country = 'Turkey',
    this.zipCode = '34000',
  });

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
  
  Map<String, dynamic> toJson() {
    return toMap();
  }

  static IyzipayAddress fromUserAddress(UserAddress address) {
    return IyzipayAddress(
      id: address.id,
      title: address.title,
      fullAddress: address.fullAddress,
      city: address.city ?? 'Istanbul', // Eğer city yoksa varsayılan değer
      country: address.country ?? 'Turkey',
      zipCode: address.zipCode ?? '34000',
      latitude: address.latitude,
      longitude: address.longitude,
    );
  }
}
