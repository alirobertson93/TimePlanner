/// Base class for failures in the application
abstract class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Failure related to database operations
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Failure related to validation
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure related to not found resources
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Failure with unknown cause
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred']);
}
