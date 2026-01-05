/// Fichier: core/exceptions/app_exceptions.dart
/// Description: Classes d'exceptions personnalisées pour une meilleure gestion d'erreurs
///
/// Cette hiérarchie d'exceptions permet de :
/// - Identifier précisément le type d'erreur
/// - Fournir des messages utilisateur adaptés
/// - Logger les erreurs techniquement détaillées
/// - Implémenter des stratégies de retry intelligentes

import 'package:firebase_core/firebase_core.dart';

/// Exception de base pour l'application
abstract class AppException implements Exception {
  /// Message affiché à l'utilisateur
  final String message;

  /// Code d'erreur technique pour logs/analytics
  final String code;

  /// Exception interne (cause)
  final Exception? originalException;

  /// Stack trace pour debugging
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    required this.code,
    this.originalException,
    this.stackTrace,
  });

  /// Convertit l'exception en string lisible
  @override
  String toString() => 'AppException($code): $message';

  /// Message complètement détaillé pour logs
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('=== Exception Détaillée ===');
    buffer.writeln('Type: ${runtimeType.toString()}');
    buffer.writeln('Code: $code');
    buffer.writeln('Message: $message');
    if (originalException != null) {
      buffer.writeln('Cause: $originalException');
    }
    return buffer.toString();
  }
}

// ============================================================
// EXCEPTIONS AUTHENTIFICATION
// ============================================================

/// Exception pour les erreurs d'authentification
abstract class AuthException extends AppException {
  AuthException({
    required super.message,
    required super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Utilisateur non authentifié
class NotAuthenticatedException extends AuthException {
  NotAuthenticatedException({
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message:
             'Vous devez être connecté pour accéder à cette fonctionnalité',
         code: 'NOT_AUTHENTICATED',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Email/password invalides
class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException({
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Email ou mot de passe incorrect',
         code: 'INVALID_CREDENTIALS',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Username déjà pris
class UsernameTakenException extends AuthException {
  final String username;

  UsernameTakenException({
    required this.username,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Le pseudo "$username" est déjà utilisé',
         code: 'USERNAME_TAKEN',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Email déjà utilisé
class EmailAlreadyUsedException extends AuthException {
  EmailAlreadyUsedException({
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Cet email est déjà utilisé',
         code: 'EMAIL_ALREADY_USED',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Mot de passe trop faible
class WeakPasswordException extends AuthException {
  WeakPasswordException({Exception? originalException, StackTrace? stackTrace})
    : super(
        message: 'Le mot de passe doit contenir au moins 8 caractères',
        code: 'WEAK_PASSWORD',
        originalException: originalException,
        stackTrace: stackTrace,
      );
}

/// Compte utilisateur désactivé
class UserDisabledException extends AuthException {
  UserDisabledException({Exception? originalException, StackTrace? stackTrace})
    : super(
        message: 'Ce compte a été désactivé',
        code: 'USER_DISABLED',
        originalException: originalException,
        stackTrace: stackTrace,
      );
}

/// Profil utilisateur incomplet
class IncompleteProfileException extends AuthException {
  IncompleteProfileException({
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message:
             'Votre profil n\'est pas complet. Veuillez le remplir pour continuer',
         code: 'INCOMPLETE_PROFILE',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

// ============================================================
// EXCEPTIONS PRODUITS
// ============================================================

/// Exception pour les erreurs liées aux produits
abstract class ProductException extends AppException {
  ProductException({
    required super.message,
    required super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Produit non trouvé
class ProductNotFoundException extends ProductException {
  final String productId;

  ProductNotFoundException({
    required this.productId,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Le produit n\'existe pas ou a été supprimé',
         code: 'PRODUCT_NOT_FOUND',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Accès refusé au produit
class ProductAccessDeniedException extends ProductException {
  ProductAccessDeniedException({
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Vous n\'avez pas accès à ce produit',
         code: 'PRODUCT_ACCESS_DENIED',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Données produit invalides
class InvalidProductDataException extends ProductException {
  final List<String> missingFields;

  InvalidProductDataException({
    required this.missingFields,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Données produit incomplètes: ${missingFields.join(", ")}',
         code: 'INVALID_PRODUCT_DATA',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Prix invalide
class InvalidPriceException extends ProductException {
  InvalidPriceException({Exception? originalException, StackTrace? stackTrace})
    : super(
        message: 'Le prix doit être supérieur à 0',
        code: 'INVALID_PRICE',
        originalException: originalException,
        stackTrace: stackTrace,
      );
}

/// Images invalides
class InvalidImagesException extends ProductException {
  final String reason;

  InvalidImagesException({
    required this.reason,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Images invalides: $reason',
         code: 'INVALID_IMAGES',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Catégorie non trouvée
class CategoryNotFoundException extends ProductException {
  final String categoryId;

  CategoryNotFoundException({
    required this.categoryId,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'La catégorie n\'existe pas',
         code: 'CATEGORY_NOT_FOUND',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Produit déjà vendu
class ProductAlreadySoldException extends ProductException {
  ProductAlreadySoldException({
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Ce produit a déjà été vendu',
         code: 'PRODUCT_ALREADY_SOLD',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

// ============================================================
// EXCEPTIONS RÉSEAU/FIRESTORE
// ============================================================

/// Exception pour les erreurs réseau/base de données
abstract class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    required super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Pas de connexion internet
class NetworkException extends DatabaseException {
  NetworkException({Exception? originalException, StackTrace? stackTrace})
    : super(
        message: 'Pas de connexion internet. Vérifiez votre connexion',
        code: 'NO_NETWORK',
        originalException: originalException,
        stackTrace: stackTrace,
      );
}

/// Timeout (délai d'attente dépassé)
class TimeoutException extends DatabaseException {
  TimeoutException({Exception? originalException, StackTrace? stackTrace})
    : super(
        message: 'La requête a pris trop de temps. Réessayez',
        code: 'TIMEOUT',
        originalException: originalException,
        stackTrace: stackTrace,
      );
}

/// Accès à Firestore refusé (permissions)
class PermissionDeniedException extends DatabaseException {
  PermissionDeniedException({
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message:
             'Vous n\'avez pas les permissions pour effectuer cette action',
         code: 'PERMISSION_DENIED',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Quota Firestore dépassé
class QuotaExceededException extends DatabaseException {
  QuotaExceededException({Exception? originalException, StackTrace? stackTrace})
    : super(
        message: 'Trop de requêtes. Réessayez dans quelques secondes',
        code: 'QUOTA_EXCEEDED',
        originalException: originalException,
        stackTrace: stackTrace,
      );
}

// ============================================================
// EXCEPTIONS STOCKAGE (Images)
// ============================================================

/// Exception pour les erreurs de stockage
abstract class StorageException extends AppException {
  StorageException({
    required super.message,
    required super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Fichier trop volumineux
class FileTooLargeException extends StorageException {
  final int fileSizeInMB;
  final int maxSizeInMB;

  FileTooLargeException({
    required this.fileSizeInMB,
    required this.maxSizeInMB,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message:
             'Image trop volumineux ($fileSizeInMB MB). Max: $maxSizeInMB MB',
         code: 'FILE_TOO_LARGE',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Format de fichier non supporté
class UnsupportedFormatException extends StorageException {
  final String format;

  UnsupportedFormatException({
    required this.format,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Format "$format" non supporté. Formats autorisés: JPEG, PNG',
         code: 'UNSUPPORTED_FORMAT',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

// ============================================================
// EXCEPTIONS VALIDATION/FORMULAIRE
// ============================================================

/// Exception pour les erreurs de validation
abstract class ValidationException extends AppException {
  ValidationException({
    required super.message,
    required super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Champ requis vide
class RequiredFieldException extends ValidationException {
  final String fieldName;

  RequiredFieldException({
    required this.fieldName,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Le champ "$fieldName" est requis',
         code: 'REQUIRED_FIELD',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

/// Format invalide (email, URL, etc.)
class InvalidFormatException extends ValidationException {
  final String fieldName;
  final String format;

  InvalidFormatException({
    required this.fieldName,
    required this.format,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: 'Format invalide pour "$fieldName". Attendu: $format',
         code: 'INVALID_FORMAT',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

// ============================================================
// EXCEPTION GÉNÉRIQUE INCONNUE
// ============================================================

/// Exception pour les erreurs non identifiées
class UnknownException extends AppException {
  UnknownException({
    String? message,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
         message: message ?? 'Une erreur inconnue s\'est produite',
         code: 'UNKNOWN_ERROR',
         originalException: originalException,
         stackTrace: stackTrace,
       );
}

// ============================================================
// UTILITAIRE : Convertir FirebaseException → AppException
// ============================================================

/// Convertit une FirebaseException en AppException appropriée
AppException handleFirebaseException(
  FirebaseException e, {
  StackTrace? stackTrace,
}) {
  final code = e.code;
  final message = e.message ?? '';

  // Auth errors
  if (code == 'user-not-found') {
    return ProductNotFoundException(
      productId: 'unknown',
      originalException: e,
      stackTrace: stackTrace,
    );
  }
  // Codes pour mot de passe/identifiants incorrects (ancien et nouveau)
  if (code == 'wrong-password' || code == 'invalid-credential') {
    return InvalidCredentialsException(
      originalException: e,
      stackTrace: stackTrace,
    );
  }
  if (code == 'email-already-in-use') {
    return EmailAlreadyUsedException(
      originalException: e,
      stackTrace: stackTrace,
    );
  }
  if (code == 'weak-password') {
    return WeakPasswordException(originalException: e, stackTrace: stackTrace);
  }
  if (code == 'user-disabled') {
    return UserDisabledException(originalException: e, stackTrace: stackTrace);
  }

  // Database errors
  if (code == 'permission-denied') {
    return PermissionDeniedException(
      originalException: e,
      stackTrace: stackTrace,
    );
  }
  if (code == 'resource-exhausted') {
    return QuotaExceededException(originalException: e, stackTrace: stackTrace);
  }
  if (code == 'deadline-exceeded') {
    return TimeoutException(originalException: e, stackTrace: stackTrace);
  }
  if (code == 'unavailable' || code == 'unauthenticated') {
    return NetworkException(originalException: e, stackTrace: stackTrace);
  }

  // Storage errors
  if (code == 'invalid-argument') {
    if (message.contains('size') || message.contains('bytes')) {
      return FileTooLargeException(
        fileSizeInMB: 0,
        maxSizeInMB: 5,
        originalException: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Exception non identifiée
  return UnknownException(
    message: 'Une erreur s\'est produite. Réessayez plus tard',
    originalException: e,
    stackTrace: stackTrace,
  );
}
