import '../entities/user_entity.dart';

/// Contract for authentication operations.
abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> registerWithEmail(String email, String password);
  Future<void> signOut();
}
