import 'package:flutter_test/flutter_test.dart';
import 'package:time_planner/core/errors/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
    });

    group('getUserMessage', () {
      test('returns network error message for network-related errors', () {
        final message = errorHandler.getUserMessage(
          Exception('SocketException: Network unreachable'),
        );
        
        expect(message, contains('internet connection'));
      });

      test('returns timeout message for timeout errors', () {
        final message = errorHandler.getUserMessage(
          Exception('TimeoutException'),
        );
        
        expect(message, contains('timed out'));
      });

      test('returns permission message for permission errors', () {
        final message = errorHandler.getUserMessage(
          Exception('Permission denied'),
        );
        
        expect(message, contains('Permission'));
      });

      test('returns not found message for not found errors', () {
        final message = errorHandler.getUserMessage(
          Exception('Item not found'),
        );
        
        expect(message, contains('not found'));
      });

      test('returns database message for database errors', () {
        final message = errorHandler.getUserMessage(
          Exception('SqliteException: database is locked'),
        );
        
        expect(message, contains('saving your data'));
      });

      test('uses fallback message when provided', () {
        final message = errorHandler.getUserMessage(
          Exception('Some unknown error'),
          fallbackMessage: 'Custom error message',
        );
        
        expect(message, equals('Custom error message'));
      });

      test('includes context in generic message', () {
        final message = errorHandler.getUserMessage(
          Exception('Unknown error'),
          context: 'loading events',
        );
        
        expect(message, contains('loading events'));
      });

      test('returns generic message for unknown errors without context', () {
        final message = errorHandler.getUserMessage(
          Exception('Random unknown error'),
        );
        
        expect(message, contains('unexpected error'));
      });
    });

    group('handleError', () {
      test('returns user-friendly message', () {
        final message = errorHandler.handleError(
          Exception('Database error'),
          operationContext: 'saving event',
        );
        
        // Should return a user-friendly message
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      test('handles null stackTrace gracefully', () {
        // Should not throw
        expect(
          () => errorHandler.handleError(
            Exception('Test error'),
            stackTrace: null,
          ),
          returnsNormally,
        );
      });
    });

    group('handleWarning', () {
      test('does not throw for valid warning', () {
        expect(
          () => errorHandler.handleWarning(
            'This is a warning',
            context: 'test context',
          ),
          returnsNormally,
        );
      });
    });

    group('logDebug', () {
      test('does not throw for debug messages', () {
        expect(
          () => errorHandler.logDebug(
            'Debug message',
            context: 'test',
          ),
          returnsNormally,
        );
      });
    });

    group('ErrorHandlerConfig', () {
      test('uses default config values', () {
        const config = ErrorHandlerConfig();
        
        expect(config.enableDebugLogging, isTrue);
        expect(config.enableProductionLogging, isFalse);
        expect(config.showUserErrorsInDebug, isTrue);
      });

      test('allows custom config', () {
        const config = ErrorHandlerConfig(
          enableDebugLogging: false,
          enableProductionLogging: true,
          showUserErrorsInDebug: false,
        );
        
        expect(config.enableDebugLogging, isFalse);
        expect(config.enableProductionLogging, isTrue);
        expect(config.showUserErrorsInDebug, isFalse);
      });

      test('error handler uses custom config', () {
        final handler = ErrorHandler(
          config: const ErrorHandlerConfig(showUserErrorsInDebug: false),
        );
        
        // In release mode with showUserErrorsInDebug: false,
        // it should show user-friendly messages
        final message = handler.getUserMessage(Exception('database error'));
        expect(message, contains('saving your data'));
      });
    });

    group('ErrorSeverity', () {
      test('has correct ordering', () {
        expect(ErrorSeverity.debug.index, lessThan(ErrorSeverity.info.index));
        expect(ErrorSeverity.info.index, lessThan(ErrorSeverity.warning.index));
        expect(ErrorSeverity.warning.index, lessThan(ErrorSeverity.error.index));
        expect(ErrorSeverity.error.index, lessThan(ErrorSeverity.critical.index));
      });
    });
  });
}
