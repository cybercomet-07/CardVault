import '../../domain/entities/card_entity.dart';

/// Data model for card (e.g. Firestore document).
class CardModel extends CardEntity {
  const CardModel({
    required super.id,
    super.name,
    super.company,
    super.phone,
    super.email,
    super.imageUrl,
    super.createdAt,
  });

  Map<String, dynamic> toMap() => {};
  factory CardModel.fromMap(Map<String, dynamic> map) => const CardModel(id: '');

  factory CardModel.fromEntity(CardEntity e) => CardModel(
        id: e.id,
        name: e.name,
        company: e.company,
        phone: e.phone,
        email: e.email,
        imageUrl: e.imageUrl,
        createdAt: e.createdAt,
      );
}
