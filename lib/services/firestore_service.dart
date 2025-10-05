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

  // Read a single user document once. Returns the document data or null if not found.
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // Stream user document changes (realtime updates).
  Stream<Map<String, dynamic>?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) => snap.exists ? snap.data() : null);
  }

  // Append a value to an array field on a document without overwriting other fields.
  // If the array doesn't exist it'll be created. Uses FieldValue.arrayUnion to avoid duplicates.
  Future<void> appendToArrayField(String docPath, String field, dynamic value) async {
    final ref = _db.doc(docPath);
    await ref.set({field: FieldValue.arrayUnion([value])}, SetOptions(merge: true));
  }

  // Add a document to a subcollection under an existing document path, e.g. users/{uid}/history
  Future<DocumentReference> addSubcollectionDocument(String docPath, String subcollection, Map<String, dynamic> data) async {
    final col = _db.doc(docPath).collection(subcollection);
    final ref = await col.add(data);
    return ref;
  }
}
