import 'package:logger/logger.dart';

/// Thin wrapper around `package:logger` so the rest of the app depends on
/// this class rather than the third-party API directly — swapping logging
/// backends later only touches this file.
class LoggerService {
  LoggerService._internal();
  static final LoggerService instance = LoggerService._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  void d(String message) => _logger.d(message);
  void i(String message) => _logger.i(message);
  void w(String message) => _logger.w(message);
  void e(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
