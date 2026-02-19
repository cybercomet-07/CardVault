import '../domain/entities/user_entity.dart';

/// Firebase Auth wrapper; used by [AuthRemoteDataSource] implementations.
abstract class AuthService {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> registerWithEmail(String email, String password);
  Future<void> signOut();
}
