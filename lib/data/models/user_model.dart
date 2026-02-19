import '../../domain/entities/user_entity.dart';

/// Data model for user (e.g. from Firebase Auth).
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.email,
    super.displayName,
  });

  factory UserModel.fromEntity(UserEntity e) =>
      UserModel(id: e.id, email: e.email, displayName: e.displayName);
}
