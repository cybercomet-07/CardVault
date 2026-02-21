import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:card_vault/core/models/user_profile.dart';

class UserProfileService {
  UserProfileService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'users';

  Future<void> upsertProfile(UserProfile profile) async {
    await _firestore
        .collection(_collection)
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> getProfile(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }
}
