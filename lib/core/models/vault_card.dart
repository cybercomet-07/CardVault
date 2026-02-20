/// Represents a business card document in Firestore.
/// Firestore: cards/{cardId} with userId, companyName, personName, designation,
/// phone, email, website, address, notes, imageUrl, createdAt.
class VaultCard {
  VaultCard({
    required this.id,
    required this.userId,
    this.companyName,
    this.personName,
    this.designation,
    this.phoneNumber,
    this.email,
    this.website,
    this.address,
    this.notes,
    this.imageURL,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String userId;
  final String? companyName;
  final String? personName;
  final String? designation;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? address;
  final String? notes;
  final String? imageURL;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyName': companyName ?? '',
      'personName': personName ?? '',
      'designation': designation ?? '',
      'phoneNumber': phoneNumber ?? '',
      'email': email ?? '',
      'website': website ?? '',
      'address': address ?? '',
      'notes': notes ?? '',
      'imageUrl': imageURL ?? '',
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory VaultCard.fromMap(String id, Map<String, dynamic> map) {
    final imageUrl = map['imageUrl'] as String? ?? map['imageURL'] as String?;
    return VaultCard(
      id: id,
      userId: map['userId'] as String? ?? '',
      companyName: map['companyName'] as String?,
      personName: map['personName'] as String?,
      designation: map['designation'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      imageURL: imageUrl,
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
    String? designation,
    String? phoneNumber,
    String? email,
    String? website,
    String? address,
    String? notes,
    String? imageURL,
    DateTime? createdAt,
  }) {
    return VaultCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      personName: personName ?? this.personName,
      designation: designation ?? this.designation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      imageURL: imageURL ?? this.imageURL,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
