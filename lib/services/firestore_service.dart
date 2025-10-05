import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new document with auto-generated id to [collectionPath]
  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) async {
    final ref = await _db.collection(collectionPath).add(data);
    return ref;
  }

  // Set (create or overwrite) a document at [docPath]
  Future<void> setDocument(String docPath, Map<String, dynamic> data, {bool merge = false}) async {
    final ref = _db.doc(docPath);
    await ref.set(data, SetOptions(merge: merge));
  }

  // Update an existing document at [docPath]
  Future<void> updateDocument(String docPath, Map<String, dynamic> data) async {
    final ref = _db.doc(docPath);
    await ref.update(data);
  }

  // Delete a document at [docPath]
  Future<void> deleteDocument(String docPath) async {
    final ref = _db.doc(docPath);
    await ref.delete();
  }

  // Convenience: write sample user data under `users/{uid}`
  Future<void> writeSampleUser(String uid, Map<String, dynamic> userData) async {
    await setDocument('users/$uid', {
      'email': userData['email'] ?? '',
      'name': userData['name'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      ...userData,
    }, merge: true);
  }
}
