/// Base exception for app-level errors.
class AppException implements Exception {
  const AppException(this.message, [this.cause]);
  final String message;
  final dynamic cause;
  @override
  String toString() => 'AppException: $message';
}
