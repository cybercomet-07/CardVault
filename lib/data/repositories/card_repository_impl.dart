import '../../domain/entities/card_entity.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/card_remote_datasource.dart';
import '../models/card_model.dart';

/// Implementation of [CardRepository] using [CardRemoteDataSource].
class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(this._dataSource);
  final CardRemoteDataSource _dataSource;

  @override
  Future<List<CardEntity>> getCards(String userId) =>
      _dataSource.getCards(userId);

  @override
  Future<CardEntity?> getCardById(String userId, String cardId) =>
      _dataSource.getCardById(userId, cardId);

  @override
  Future<CardEntity> saveCard(String userId, CardEntity card) =>
      _dataSource.saveCard(userId, CardModel.fromEntity(card));

  @override
  Future<void> deleteCard(String userId, String cardId) =>
      _dataSource.deleteCard(userId, cardId);

  @override
  Future<List<CardEntity>> searchCards(String userId, String query) =>
      _dataSource.searchCards(userId, query);
}
