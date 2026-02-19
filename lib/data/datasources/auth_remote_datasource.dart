import '../../domain/entities/user_entity.dart';

/// Remote auth data source (e.g. Firebase Auth).
abstract class AuthRemoteDataSource {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> registerWithEmail(String email, String password);
  Future<void> signOut();
}
