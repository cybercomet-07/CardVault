/// Remote storage for card images (e.g. Firebase Storage).
abstract class StorageRemoteDataSource {
  Future<String> uploadCardImage(String userId, String path, List<int> bytes);
  Future<void> deleteCardImage(String userId, String path);
}
