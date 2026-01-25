import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Severity levels for error logging
enum ErrorSeverity {
  /// Debug-level information, only logged in debug mode
  debug,
  /// Informational messages
  info,
  /// Warning messages for recoverable issues
  warning,
  /// Error messages for failures that need attention
  error,
  /// Critical errors that may affect app stability
  critical,
}

/// Configuration for error handling behavior
class ErrorHandlerConfig {
  const ErrorHandlerConfig({
    this.enableDebugLogging = true,
    this.enableProductionLogging = false,
    this.showUserErrorsInDebug = true,
  });

  /// Whether to log errors in debug mode
  final bool enableDebugLogging;

  /// Whether to log errors in production mode
  final bool enableProductionLogging;

  /// Whether to show full error details to users in debug mode
  final bool showUserErrorsInDebug;
}

/// Centralized error handling service for the application.
/// 
/// Provides consistent error logging and user-friendly error messages.
/// Can be injected via Riverpod for easy testing and customization.
class ErrorHandler {
  ErrorHandler({
    this.config = const ErrorHandlerConfig(),
  });

  /// Configuration for error handling behavior
  final ErrorHandlerConfig config;

  /// Logs an error with the specified severity level.
  /// 
  /// [error] - The error object or message
  /// [stackTrace] - Optional stack trace for debugging
  /// [context] - A description of where the error occurred
  /// [severity] - The severity level of the error
  void logError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    // Only log in debug mode if enabled
    if (kDebugMode && config.enableDebugLogging) {
      _writeLog(error, stackTrace: stackTrace, context: context, severity: severity);
    }
    
    // In production, only log if explicitly enabled
    if (kReleaseMode && config.enableProductionLogging) {
      // In production, you might want to send to a remote logging service
      // For now, we just use debugPrint which won't output in release mode
      _writeLog(error, stackTrace: stackTrace, context: context, severity: severity);
    }
  }

  /// Writes the log entry
  void _writeLog(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final severityLabel = severity.name.toUpperCase();
    final contextInfo = context != null ? '[$context] ' : '';
    
    // Use debugPrint for formatted output that respects line length
    debugPrint('[$severityLabel] ${contextInfo}Error: $error');
    
    if (stackTrace != null && severity.index >= ErrorSeverity.error.index) {
      debugPrint('Stack trace:\n$stackTrace');
    }
  }

  /// Creates a user-friendly error message from an error.
  /// 
  /// [error] - The error object or message
  /// [fallbackMessage] - Message to show if error type is unknown
  /// [context] - A description of the operation that failed
  String getUserMessage(
    Object error, {
    String? fallbackMessage,
    String? context,
  }) {
    // In debug mode, optionally show more details
    if (kDebugMode && config.showUserErrorsInDebug) {
      return _formatDebugMessage(error, context: context);
    }
    
    return _formatUserMessage(error, fallbackMessage: fallbackMessage, context: context);
  }

  /// Formats a detailed error message for debugging
  String _formatDebugMessage(Object error, {String? context}) {
    final contextPrefix = context != null ? '$context: ' : '';
    return '$contextPrefix$error';
  }

  /// Formats a user-friendly error message
  String _formatUserMessage(
    Object error, {
    String? fallbackMessage,
    String? context,
  }) {
    // Map common error types to user-friendly messages
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'The operation timed out. Please try again.';
    }
    
    if (errorString.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    }
    
    if (errorString.contains('not found')) {
      return context != null 
          ? 'The requested $context was not found.' 
          : 'The requested item was not found.';
    }
    
    if (errorString.contains('database') || errorString.contains('sqlite')) {
      return 'There was a problem saving your data. Please try again.';
    }
    
    // Use fallback or generic message
    if (fallbackMessage != null) {
      return fallbackMessage;
    }
    
    return context != null
        ? 'An error occurred while $context. Please try again.'
        : 'An unexpected error occurred. Please try again.';
  }

  /// Shows a SnackBar with an error message.
  /// 
  /// [context] - The BuildContext for showing the SnackBar
  /// [error] - The error object or message
  /// [operationContext] - A description of the operation that failed (e.g., "saving event")
  /// [fallbackMessage] - Message to show if error type is unknown
  /// [duration] - How long to show the SnackBar
  void showErrorSnackBar(
    BuildContext context,
    Object error, {
    String? operationContext,
    String? fallbackMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Also log the error
    logError(error, context: operationContext, severity: ErrorSeverity.error);
    
    final message = getUserMessage(
      error,
      fallbackMessage: fallbackMessage,
      context: operationContext,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Handles an error by logging it and returning a user-friendly message.
  /// 
  /// This is useful for providers that need to store error messages in state.
  /// 
  /// [error] - The error object or message
  /// [stackTrace] - Optional stack trace for debugging
  /// [operationContext] - A description of the operation that failed
  /// [fallbackMessage] - Message to show if error type is unknown
  String handleError(
    Object error, {
    StackTrace? stackTrace,
    String? operationContext,
    String? fallbackMessage,
  }) {
    logError(
      error,
      stackTrace: stackTrace,
      context: operationContext,
      severity: ErrorSeverity.error,
    );
    
    return getUserMessage(
      error,
      fallbackMessage: fallbackMessage,
      context: operationContext,
    );
  }

  /// Handles a warning by logging it without showing to the user.
  /// 
  /// Use this for recoverable issues that should be logged but don't need
  /// to interrupt the user experience.
  void handleWarning(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    logError(
      error,
      stackTrace: stackTrace,
      context: context,
      severity: ErrorSeverity.warning,
    );
  }

  /// Logs debug information (only in debug mode).
  void logDebug(String message, {String? context}) {
    logError(
      message,
      context: context,
      severity: ErrorSeverity.debug,
    );
  }
}
