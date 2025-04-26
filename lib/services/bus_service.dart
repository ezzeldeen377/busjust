import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/bus_malfunction.dart';

class BusService {
  static final BusService instance = BusService._();
  BusService._();

  final _db = FirebaseFirestore.instance;

  Future<void> reportMalfunction(BusMalfunction malfunction) async {
    await _db.collection('bus_malfunctions').doc(malfunction.id).set(
      malfunction.toMap(),
    );
  }

  Future<void> markMalfunctionAsFixed(String malfunctionId) async {
    await _db.collection('bus_malfunctions').doc(malfunctionId).update({
      'isFixed': true,
    });
  }

  Stream<List<BusMalfunction>> getMalfunctionReports() {
    return _db
        .collection('bus_malfunctions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusMalfunction.fromMap(doc.data()))
            .toList());
  }
}