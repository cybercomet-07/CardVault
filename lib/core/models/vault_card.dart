/// Represents a visiting card document in Firestore.
class VaultCard {
  VaultCard({
    required this.id,
    required this.userId,
    this.companyName,
    this.personName,
    this.phoneNumber,
    this.address,
    this.imageURL,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String userId;
  final String? companyName;
  final String? personName;
  final String? phoneNumber;
  final String? address;
  final String? imageURL;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyName': companyName ?? '',
      'personName': personName ?? '',
      'phoneNumber': phoneNumber ?? '',
      'address': address ?? '',
      'imageURL': imageURL ?? '',
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory VaultCard.fromMap(String id, Map<String, dynamic> map) {
    return VaultCard(
      id: id,
      userId: map['userId'] as String? ?? '',
      companyName: map['companyName'] as String?,
      personName: map['personName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      address: map['address'] as String?,
      imageURL: map['imageURL'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['createdAt'] as num).toInt())
          : null,
    );
  }

  VaultCard copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? personName,
    String? phoneNumber,
    String? address,
    String? imageURL,
    DateTime? createdAt,
  }) {
    return VaultCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      personName: personName ?? this.personName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      imageURL: imageURL ?? this.imageURL,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
