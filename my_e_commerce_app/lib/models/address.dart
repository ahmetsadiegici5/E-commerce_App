class Address {
  final String contactName;
  final String city;
  final String country;
  final String address;
  final String zipCode;

  Address({
    required this.contactName,
    required this.city,
    required this.country,
    required this.address,
    required this.zipCode,
  });

  Map<String, dynamic> toMap() {
    return toJson();
  }

  Map<String, dynamic> toJson() {
    return {
      'contactName': contactName,
      'city': city,
      'country': country,
      'address': address,
      'zipCode': zipCode,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      contactName: map['contactName'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      address: map['address'] ?? '',
      zipCode: map['zipCode'] ?? '',
    );
  }
}
