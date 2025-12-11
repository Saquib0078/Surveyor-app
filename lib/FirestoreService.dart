import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream<DocumentSnapshot> streamFormData(String userId) {
  //   return _db.collection('forms').doc(userId).snapshots();
  // }


  // Future<DocumentSnapshot<Map<String, dynamic>>> getFormData(String userId) {
  //   return _db.collection('users').doc(userId).get();
  // }

  String generateFormId() {
    return _db.collection('forms').doc().id;
  }

  // Save form data
  Future<void> saveFormData(String userId, String formId, Map<String, Map<String, dynamic>> formData) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('forms')
        .doc(formId)
        .set(formData);
  }

  // Get form data
  Future<DocumentSnapshot<Map<String, dynamic>>> getFormData(String userId, String formId) async {
    return await _db
        .collection('users')
        .doc(userId)
        .collection('forms')
        .doc(formId)
        .get();
  }

  // Stream form data
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamFormData(String userId, String formId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('forms')
        .doc(formId)
        .snapshots();
  }

  // Get all forms for a user
  Future<QuerySnapshot<Map<String, dynamic>>> getAllForms(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('forms')
        .get();
  }

  Future<void> updateFormImages(String userId, String formId, List<String> imageUrls) async {
    await _db.collection('users').doc(userId).collection('forms')
        .doc(formId)
        .update({
      'selfInspectionImages': imageUrls,
    });
  }

  Future<void> saveClaimStatus(String userId, String formId, Map<String, dynamic> statusData) async {
    await _db.collection('users').doc(userId).collection('claims').doc(formId).set({
      'status': statusData,
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getClaimStatus(String userId, String formId) async {
    return await _db.collection('users').doc(userId).collection('claims').doc(formId).get();
  }
}
