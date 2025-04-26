import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/lost_item.dart';

class LostItemService {
  static final LostItemService instance = LostItemService._();
  LostItemService._();

  final _db = FirebaseFirestore.instance;

  Future<void> reportLostItem(LostItem item) async {
    await _db.collection('lost_items').doc(item.id).set(
      item.toMap(),
    );
  }

  Future<void> markAsFound(String itemId) async {
    await _db.collection('lost_items').doc(itemId).update({
      'isFound': true,
    });
  }

  Stream<List<LostItem>> getLostItemReports() {
    return _db
        .collection('lostItems')
        .orderBy('reportDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LostItem.fromMap(
                  doc.data(),
                ))
            .toList());
  }
}