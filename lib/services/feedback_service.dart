import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/feedback.dart';

class FeedbackService {
  static final FeedbackService instance = FeedbackService._();
  FeedbackService._();

  final _db = FirebaseFirestore.instance;

  Stream<List<FeedbackModel>> getFeedbackReports() {
    return _db
        .collection('feedback')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromMap(
                doc.data(),
                ))
            .toList());
  }

  Future<void> deleteFeedback(String id) async {
    await _db.collection('feedback').doc(id).delete();
  }

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _db.collection('feedback').doc(feedback.id).set(feedback.toMap());
  }
}