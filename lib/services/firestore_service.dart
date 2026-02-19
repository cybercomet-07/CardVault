/// Firestore CRUD wrapper for cards; used by card datasource.
abstract class FirestoreService {
  Future<List<Map<String, dynamic>>> getCards(String userId);
  Future<Map<String, dynamic>?> getCardById(String userId, String cardId);
  Future<Map<String, dynamic>> saveCard(String userId, Map<String, dynamic> data);
  Future<void> deleteCard(String userId, String cardId);
  Future<List<Map<String, dynamic>>> searchCards(String userId, String query);
}
