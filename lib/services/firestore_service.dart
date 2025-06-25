import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save or update user profile
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? organization,
    String? contactNumber,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      if (organization != null) 'organization': organization,
      if (contactNumber != null) 'contactNumber': contactNumber,
      'updatedAt': FieldValue.serverTimestamp(),
      // Optional: preserve existing createdAt if re-saving
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Merges instead of overwriting
  }

  /// Get user role only (for routing after login)
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return (doc.data() as Map<String, dynamic>)['role'];
    }
    return null;
  }

  /// Get full user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }
}