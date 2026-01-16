import 'package:uuid/uuid.dart';

/// Generates unique identifiers for entities
class IdGenerator {
  IdGenerator._();

  static const _uuid = Uuid();

  /// Generates a new UUID v4
  static String generate() {
    return _uuid.v4();
  }

  /// Generates a new UUID with a specific prefix
  static String generateWithPrefix(String prefix) {
    return '${prefix}_${_uuid.v4()}';
  }
}
