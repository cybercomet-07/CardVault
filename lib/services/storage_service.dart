/// Firebase Storage wrapper for card images.
abstract class StorageService {
  Future<String> upload(String userId, String path, List<int> bytes);
  Future<void> delete(String userId, String path);
}
