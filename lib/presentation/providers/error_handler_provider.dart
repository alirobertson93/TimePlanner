import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/error_handler.dart';

/// Provider for the centralized error handler.
/// 
/// Usage in providers:
/// ```dart
/// final errorHandler = ref.read(errorHandlerProvider);
/// try {
///   // ... operation
/// } catch (e, stackTrace) {
///   final message = errorHandler.handleError(
///     e,
///     stackTrace: stackTrace,
///     operationContext: 'saving event',
///   );
///   state = state.copyWith(error: message);
/// }
/// ```
/// 
/// Usage in widgets:
/// ```dart
/// final errorHandler = ref.read(errorHandlerProvider);
/// try {
///   // ... operation
/// } catch (e) {
///   errorHandler.showErrorSnackBar(
///     context, 
///     e,
///     operationContext: 'saving event',
///   );
/// }
/// ```
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});
