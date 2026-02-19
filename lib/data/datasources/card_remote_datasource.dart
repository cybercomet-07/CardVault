import '../../data/models/card_model.dart';

/// Remote card data source (e.g. Firestore).
abstract class CardRemoteDataSource {
  Future<List<CardModel>> getCards(String userId);
  Future<CardModel?> getCardById(String userId, String cardId);
  Future<CardModel> saveCard(String userId, CardModel card);
  Future<void> deleteCard(String userId, String cardId);
  Future<List<CardModel>> searchCards(String userId, String query);
}
