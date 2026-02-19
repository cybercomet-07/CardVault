import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of [AuthRepository] using [AuthRemoteDataSource].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);
  final AuthRemoteDataSource _dataSource;

  @override
  Future<UserEntity?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Future<UserEntity> signInWithEmail(String email, String password) =>
      _dataSource.signInWithEmail(email, password);

  @override
  Future<UserEntity> registerWithEmail(String email, String password) =>
      _dataSource.registerWithEmail(email, password);

  @override
  Future<void> signOut() => _dataSource.signOut();
}
