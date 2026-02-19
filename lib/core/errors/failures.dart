/// Failure type for use in repository/use-case layers.
class Failure {
  const Failure(this.message);
  final String message;
}
