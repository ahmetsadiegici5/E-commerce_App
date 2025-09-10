import 'dart:math' show cos, sqrt, asin;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_location.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Yakındaki benzin istasyonlarını getir
  Stream<List<ServiceLocation>> getNearbyGasStations(double lat, double lng, double radius) {
    return _firestore
        .collection('locations')
        .where('type', isEqualTo: 'gas_station')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceLocation.fromMap(doc.data()))
          .where((location) {
        // Basit mesafe hesaplaması (gerçek uygulamada daha karmaşık olabilir)
        double distance = _calculateDistance(lat, lng, location.location.latitude,
            location.location.longitude);
        return distance <= radius;
      }).toList();
    });
  }

  // Yakındaki tamircileri getir
  Stream<List<ServiceLocation>> getNearbyMechanics(double lat, double lng, double radius) {
    return _firestore
        .collection('locations')
        .where('type', isEqualTo: 'mechanic')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceLocation.fromMap(doc.data()))
          .where((location) {
        double distance = _calculateDistance(lat, lng, location.location.latitude,
            location.location.longitude);
        return distance <= radius;
      }).toList();
    });
  }

  // İki nokta arasındaki mesafeyi hesapla (km cinsinden)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Yeni servis lokasyonu ekle
  Future<void> addServiceLocation(ServiceLocation location) {
    return _firestore.collection('locations').add(location.toMap());
  }

  // Servis lokasyonunu güncelle
  Future<void> updateServiceLocation(ServiceLocation location) {
    return _firestore
        .collection('locations')
        .doc(location.id)
        .update(location.toMap());
  }
}
