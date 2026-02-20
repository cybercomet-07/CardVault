import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:card_vault/core/models/vault_card.dart';

const String _collection = 'cards';

class FirestoreCardService {
  FirestoreCardService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Stream of cards for the given user (newest first).
  Stream<List<VaultCard>> streamCards(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => VaultCard.fromMap(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Add a new card; returns the new document id.
  Future<String> addCard(VaultCard card) async {
    final ref = await _firestore.collection(_collection).add(card.toMap());
    return ref.id;
  }

  /// Update an existing card.
  Future<void> updateCard(VaultCard card) async {
    if (card.id.isEmpty) return;
    await _firestore
        .collection(_collection)
        .doc(card.id)
        .update(card.toMap());
  }

  /// Delete a card.
  Future<void> deleteCard(String cardId) async {
    await _firestore.collection(_collection).doc(cardId).delete();
  }

  /// Get a single card by id.
  Future<VaultCard?> getCard(String cardId) async {
    final doc = await _firestore.collection(_collection).doc(cardId).get();
    if (doc.exists && doc.data() != null) {
      return VaultCard.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}
