/// Domain entity: visiting card.
class CardEntity {
  const CardEntity({
    required this.id,
    this.name,
    this.company,
    this.phone,
    this.email,
    this.imageUrl,
    this.createdAt,
  });
  final String id;
  final String? name;
  final String? company;
  final String? phone;
  final String? email;
  final String? imageUrl;
  final DateTime? createdAt;
}
