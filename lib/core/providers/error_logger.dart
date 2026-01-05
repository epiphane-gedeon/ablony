/// Fichier: core/providers/error_logger.dart
/// Description: Utilitaires pour logger les erreurs en production

import 'package:flutter/foundation.dart';
import '../exceptions/exceptions.dart';

/// Service pour logger les erreurs
class ErrorLogger {
  /// Log une exception dans la console et envoyer à un service de monitoring
  static Future<void> logException(
    Exception exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    final isProduction = const bool.fromEnvironment('dart.vm.product');

    // En debug, toujours logger dans la console
    if (kDebugMode) {
      _logToConsole(exception, stackTrace);
    }

    // En production, envoyer à un service de monitoring
    if (isProduction && exception is AppException) {
      await _logToRemoteService(exception, context);
    }
  }

  /// Log la détail complet de l'erreur dans la console
  static void _logToConsole(Exception exception, StackTrace? stackTrace) {
    if (exception is AppException) {
      debugPrint(
        '╔════════════════════════════════════════════════════════════╗',
      );
      debugPrint('║ ❌ ERREUR APPLICATIVE ║');
      debugPrint(
        '╠════════════════════════════════════════════════════════════╣',
      );
      debugPrint('║ Type: ${exception.runtimeType.toString()}');
      debugPrint('║ Code: ${exception.code}');
      debugPrint('║ Message: ${exception.message}');

      if (exception.originalException != null) {
        debugPrint('║ Cause: ${exception.originalException}');
      }

      if (stackTrace != null) {
        debugPrint('║');
        debugPrint('║ Stack Trace:');
        stackTrace.toString().split('\n').forEach((line) {
          debugPrint('║   $line');
        });
      }

      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
    } else {
      debugPrint('⚠️ Exception non typée: $exception\n$stackTrace');
    }
  }

  /// Envoyer l'erreur à un service de monitoring (ex: Sentry, Firebase Crashlytics)
  static Future<void> _logToRemoteService(
    AppException exception,
    Map<String, dynamic>? context,
  ) async {
    // TODO: Intégrer un service de monitoring comme Sentry ou Firebase Crashlytics
    // Exemple avec Sentry:
    // await Sentry.captureException(
    //   exception,
    //   stackTrace: exception.stackTrace,
    //   hint: Hint.withMap(context ?? {}),
    // );

    debugPrint(
      '📤 [PRODUCTION] Erreur envoyée au service de monitoring: ${exception.code}',
    );
  }
}

/// Classe pour collecter du contexte sur une erreur
class ErrorContext {
  final String? userId;
  final String? currentRoute;
  final String? action;
  final Map<String, dynamic>? additionalData;

  ErrorContext({
    this.userId,
    this.currentRoute,
    this.action,
    this.additionalData,
  });

  /// Convertit le contexte en Map pour l'envoyer au service de monitoring
  Map<String, dynamic> toMap() => {
    if (userId != null) 'userId': userId,
    if (currentRoute != null) 'route': currentRoute,
    if (action != null) 'action': action,
    if (additionalData != null) ...additionalData!,
  };
}
