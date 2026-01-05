/// Fichier: core/presentation/error_handler.dart
/// Description: Utilitaires pour afficher les erreurs aux utilisateurs

import 'package:flutter/material.dart';
import '../exceptions/exceptions.dart';

/// Classe utilitaire pour gérer l'affichage des erreurs
class ErrorHandler {
  /// Affiche un message d'erreur avec un SnackBar
  static void showError(BuildContext context, Exception exception) {
    final message = getErrorMessage(exception);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Fermer',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          textColor: Colors.white,
        ),
      ),
    );
  }

  /// Affiche un dialogue d'erreur
  static Future<void> showErrorDialog(
    BuildContext context,
    Exception exception, {
    VoidCallback? onRetry,
  }) async {
    final message = getErrorMessage(exception);
    final title = getErrorTitle(exception);

    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Retourne le titre approprié selon le type d'exception
  static String getErrorTitle(Exception exception) {
    if (exception is AppException) {
      switch (exception.code) {
        case 'NOT_AUTHENTICATED':
          return 'Authentification requise';
        case 'INVALID_CREDENTIALS':
          return 'Identifiants invalides';
        case 'USERNAME_TAKEN':
          return 'Pseudo non disponible';
        case 'EMAIL_ALREADY_USED':
          return 'Email déjà utilisé';
        case 'INCOMPLETE_PROFILE':
          return 'Profil incomplet';
        case 'PRODUCT_NOT_FOUND':
          return 'Produit non trouvé';
        case 'CATEGORY_NOT_FOUND':
          return 'Catégorie non trouvée';
        case 'NO_NETWORK':
          return 'Pas de connexion';
        case 'TIMEOUT':
          return 'Délai d\'attente dépassé';
        case 'PERMISSION_DENIED':
          return 'Accès refusé';
        case 'QUOTA_EXCEEDED':
          return 'Trop de requêtes';
        case 'FILE_TOO_LARGE':
          return 'Fichier trop volumineux';
        case 'UNSUPPORTED_FORMAT':
          return 'Format non supporté';
        default:
          return 'Erreur';
      }
    }
    return 'Erreur';
  }

  /// Retourne le message d'erreur utilisateur approprié
  static String getErrorMessage(Exception exception) {
    if (exception is AppException) {
      return exception.message;
    }
    return 'Une erreur inconnue s\'est produite';
  }

  /// Retourne le code d'erreur pour logging/analytics
  static String? getErrorCode(Exception exception) {
    if (exception is AppException) {
      return exception.code;
    }
    return null;
  }

  /// Log l'erreur détaillée pour debugging
  static void logError(Exception exception, {StackTrace? stackTrace}) {
    if (exception is AppException) {
      print(exception.toDetailedString());
      if (exception.stackTrace != null) {
        print('Stack trace:\n${exception.stackTrace}');
      }
    } else {
      print('Exception: $exception');
      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
    }
  }

  /// Détermine si l'erreur est "critère" (nécessite une action immédiate)
  static bool isCriticalError(Exception exception) {
    if (exception is AppException) {
      return {
        'NOT_AUTHENTICATED',
        'PERMISSION_DENIED',
        'USER_DISABLED',
        'QUOTA_EXCEEDED',
      }.contains(exception.code);
    }
    return false;
  }

  /// Détermine si l'erreur est "retryable" (peut être réessayée)
  static bool isRetryable(Exception exception) {
    if (exception is AppException) {
      return {
        'NO_NETWORK',
        'TIMEOUT',
        'QUOTA_EXCEEDED',
      }.contains(exception.code);
    }
    return false;
  }
}

/// Extension pratique sur Exception pour accéder aux utilitaires
extension ErrorHandling on Exception {
  /// Affiche l'erreur avec un SnackBar
  void showAsSnackBar(BuildContext context) {
    ErrorHandler.showError(context, this);
  }

  /// Affiche l'erreur avec un dialogue
  Future<void> showAsDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    await ErrorHandler.showErrorDialog(context, this, onRetry: onRetry);
  }

  /// Retourne le titre approprié
  String getTitle() => ErrorHandler.getErrorTitle(this);

  /// Retourne le message d'erreur
  String getErrorMessage() => ErrorHandler.getErrorMessage(this);

  /// Retourne le code d'erreur
  String? getCode() => ErrorHandler.getErrorCode(this);

  /// Log l'erreur
  void log({StackTrace? stackTrace}) {
    ErrorHandler.logError(this, stackTrace: stackTrace);
  }

  /// Vérifie si c'est une erreur critique
  bool get isCritical => ErrorHandler.isCriticalError(this);

  /// Vérifie si l'erreur peut être réessayée
  bool get canRetry => ErrorHandler.isRetryable(this);
}
