import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceLocation {
  final String id;
  final String name;
  final String type; // 'gas_station', 'mechanic', etc.
  final String address;
  final LatLng location;
  final String phoneNumber;
  final double rating;
  final List<String> services;
  final String imageURL;
  final Map<String, dynamic> workingHours;
  final bool isOpen;

  ServiceLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.location,
    required this.phoneNumber,
    required this.rating,
    required this.services,
    required this.imageURL,
    required this.workingHours,
    required this.isOpen,
  });

  factory ServiceLocation.fromMap(Map<String, dynamic> map) {
    return ServiceLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      address: map['address'] ?? '',
      location: LatLng(
        map['location']?['latitude'] ?? 0.0,
        map['location']?['longitude'] ?? 0.0,
      ),
      phoneNumber: map['phoneNumber'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      services: List<String>.from(map['services'] ?? []),
      imageURL: map['imageURL'] ?? '',
      workingHours: Map<String, dynamic>.from(map['workingHours'] ?? {}),
      isOpen: map['isOpen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'phoneNumber': phoneNumber,
      'rating': rating,
      'services': services,
      'imageURL': imageURL,
      'workingHours': workingHours,
      'isOpen': isOpen,
    };
  }
}
