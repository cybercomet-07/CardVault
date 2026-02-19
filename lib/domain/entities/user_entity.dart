/// Domain entity: authenticated user.
class UserEntity {
  const UserEntity({
    required this.id,
    this.email,
    this.displayName,
  });
  final String id;
  final String? email;
  final String? displayName;
}
