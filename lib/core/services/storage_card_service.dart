import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageCardService {
  StorageCardService() : _storage = FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Upload card image; returns the download URL.
  /// Path: cards/{userId}/{cardId}.jpg
  Future<String> uploadCardImage({
    required String userId,
    required String cardId,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref().child('cards').child(userId).child('$cardId.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
