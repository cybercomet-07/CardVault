import '../entities/card_entity.dart';

/// Contract for card CRUD and search.
abstract class CardRepository {
  Future<List<CardEntity>> getCards(String userId);
  Future<CardEntity?> getCardById(String userId, String cardId);
  Future<CardEntity> saveCard(String userId, CardEntity card);
  Future<void> deleteCard(String userId, String cardId);
  Future<List<CardEntity>> searchCards(String userId, String query);
}
