/// Énumération représentant les différentes méthodes d'authentification
/// disponibles dans l'application Ablony.
///
/// Cette énumération est utilisée pour :
/// - Identifier le fournisseur d'authentification utilisé lors de l'inscription
/// - Afficher les boutons appropriés selon la plateforme (ex: Apple sur iOS uniquement)
/// - Gérer les connexions spécifiques à chaque provider dans Firestore
///
/// Les valeurs possibles sont :
/// - [google] : Authentification via Google Sign-In (disponible sur tous les systèmes)
/// - [facebook] : Authentification via Facebook (disponible sur tous les systèmes)
/// - [apple] : Authentification via Apple ID (uniquement iOS et macOS)
/// - [email] : Authentification classique par email/mot de passe
enum AuthProvider {
  /// Authentification via Google Sign-In
  ///
  /// Disponible sur : Android, iOS, Web
  /// Package utilisé : google_sign_in
  ///
  /// Avantages :
  /// - Connexion rapide et sécurisée
  /// - Récupération automatique de l'email, nom, et photo de profil
  /// - Large adoption par les utilisateurs
  google,

  /// Authentification via Facebook Login
  ///
  /// Disponible sur : Android, iOS, Web
  /// Package utilisé : flutter_facebook_auth
  ///
  /// Avantages :
  /// - Connexion rapide pour les utilisateurs de Facebook
  /// - Récupération des informations de profil
  /// - Populaire en Afrique de l'Ouest
  facebook,

  /// Authentification via Apple Sign-In
  ///
  /// Disponible sur : iOS, macOS uniquement
  /// Package utilisé : sign_in_with_apple
  ///
  /// Important :
  /// - Obligatoire pour les apps iOS qui proposent d'autres connexions sociales
  /// - Permet de masquer son email réel (email relay Apple)
  /// - Doit être affiché en premier sur iOS (selon les guidelines Apple)
  apple,

  /// Authentification classique par email et mot de passe
  ///
  /// Disponible sur : Tous les systèmes
  /// Package utilisé : firebase_auth
  ///
  /// Caractéristiques :
  /// - Nécessite création de mot de passe
  /// - Vérification d'email recommandée
  /// - Gestion de réinitialisation de mot de passe
  email;

  // ============================================================
  // MÉTHODES UTILITAIRES
  // ============================================================

  /// Retourne le nom d'affichage du provider pour l'interface utilisateur
  ///
  /// Exemple :
  /// ```dart
  /// AuthProvider.google.displayName // "Google"
  /// AuthProvider.facebook.displayName // "Facebook"
  /// ```
  String get displayName {
    switch (this) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.facebook:
        return 'Facebook';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.email:
        return 'Email';
    }
  }

  /// Retourne l'identifiant du provider pour Firebase Auth
  ///
  /// Ces identifiants correspondent aux constantes Firebase :
  /// - 'google.com' pour Google
  /// - 'facebook.com' pour Facebook
  /// - 'apple.com' pour Apple
  /// - 'password' pour Email/Password
  ///
  /// Exemple :
  /// ```dart
  /// AuthProvider.google.providerId // "google.com"
  /// ```
  String get providerId {
    switch (this) {
      case AuthProvider.google:
        return 'google.com';
      case AuthProvider.facebook:
        return 'facebook.com';
      case AuthProvider.apple:
        return 'apple.com';
      case AuthProvider.email:
        return 'password';
    }
  }

  /// Convertit une chaîne de caractères en AuthProvider
  ///
  /// Utilisé pour la désérialisation depuis Firestore.
  ///
  /// Exemple :
  /// ```dart
  /// AuthProvider.fromString('google') // AuthProvider.google
  /// AuthProvider.fromString('facebook') // AuthProvider.facebook
  /// ```
  ///
  /// Lance une exception si la valeur n'est pas reconnue.
  static AuthProvider fromString(String value) {
    switch (value.toLowerCase()) {
      case 'google':
        return AuthProvider.google;
      case 'facebook':
        return AuthProvider.facebook;
      case 'apple':
        return AuthProvider.apple;
      case 'email':
        return AuthProvider.email;
      default:
        throw ArgumentError('Provider d\'authentification inconnu : $value');
    }
  }

  /// Convertit l'AuthProvider en chaîne de caractères pour Firestore
  ///
  /// Utilisé pour la sérialisation vers Firestore.
  ///
  /// Exemple :
  /// ```dart
  /// AuthProvider.google.toFirestore() // "google"
  /// ```
  String toFirestore() {
    return name; // Retourne 'google', 'facebook', 'apple', ou 'email'
  }
}
