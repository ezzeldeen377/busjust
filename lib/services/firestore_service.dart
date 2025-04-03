import 'package:bus_just/models/admin.dart';
import 'package:bus_just/models/driver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/user.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  factory FirestoreService() {
    return instance;
  }

  FirestoreService._internal();

  // Create or update user data in Firestore
  Future<void> saveUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to save user data: ${e.toString()}');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Get filtered stream of collection you pass based on conditions you pass
  Stream<QuerySnapshot> getStreamedData(String collection,
      {String? condition, dynamic value}) {
    var query = _firestore.collection(collection);
    Query<Map<String, dynamic>> streamedData;

    if (condition != null) {
      streamedData = query.where(condition, isEqualTo: value);
      return streamedData.snapshots();
    } else {
      return query.snapshots();
    }
  }

  // Get filtered future of collection you pass based on conditions you pass
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getFutureData(
      String collection,
      {String? condition,
      dynamic value}) async {
    var query = _firestore.collection(collection);
    Query<Map<String, dynamic>> streamedData;

    if (condition != null) {
      streamedData = query.where(condition, isEqualTo: value);
      return (await streamedData.get()).docs;
    } else {
      return (await query.get()).docs;
    }
  }

  // Get filtered future of collection you pass based on conditions you pass
  Future<QuerySnapshot<Map<String, dynamic>>>
      getFutureDataWithTwoCondition(String collection,
          {String? condition1,
          dynamic value1,
          String? condition2,
          dynamic value2}) async {
    var data =await _firestore
        .collection(collection)
        .where(condition1!, isEqualTo:value1)
        .where(condition2!, isEqualTo: value2)
        .get();
        return data;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getSpecficData(
      String collection, String docId) async {
    final data = _firestore.collection(collection).doc(docId).get();
    return data;
  }

  // Example usage of getFutureData for trips
  DocumentReference<Map<String, dynamic>> createEmptyDocumnet(
      String collection) {
    return _firestore.collection(collection).doc();
  }

  // Create a new document with custom data
  Future<void> createDocumentWithData({
    required String collection,
    Map<String, dynamic>? data,
    String? documentId,
  }) async {
    try {
      final docRef = documentId != null
          ? _firestore.collection(collection).doc(documentId)
          : _firestore.collection(collection).doc();
      if (data != null) {
        await docRef.set(data);
      }
    } catch (e) {
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  // Update existing document with custom data
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  // Get driver data from Firestore
  Future<Driver?> getDriverData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['role'] == UserRole.driver.name) {
          return Driver.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get driver data: ${e.toString()}');
    }
  }

  // Get admin data from Firestore
  Future<Admin?> getAdminData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['role'] == UserRole.admin.name) {
          return Admin.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get admin data: ${e.toString()}');
    }
  }

  // Delete document from collection
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }
}
