/// Fichier: app_assets.dart
/// Description: Centralise tous les chemins des assets de l'application.
/// Évite les erreurs de typo et facilite la maintenance des chemins d'assets.

/// Classe statique contenant tous les chemins des assets de l'application.
class AppAssets {
  // Constructeur privé pour empêcher l'instanciation
  AppAssets._();

  // ============================================================================
  // IMAGES
  // ============================================================================

  /// Logo principal de l'application (carré, fond transparent)
  static const String logo = 'assets/images/logo.png';

  /// Logo en version blanche (pour fonds sombres)
  static const String logoWhite = 'assets/images/logo_white.png';

  /// Logo pour le splash screen (optionnel, peut être différent)
  static const String splashLogo = 'assets/images/splash_logo.png';

  // ============================================================================
  // ICÔNES
  // ============================================================================

  /// Icône de l'application (utilisée pour générer les icônes natives)
  static const String appIcon = 'assets/icons/app_icon.png';

  // ============================================================================
  // IMAGES DE PLACEHOLDER (à ajouter plus tard)
  // ============================================================================

  /// Image par défaut pour les produits sans image
  static const String productPlaceholder =
      'assets/images/product_placeholder.png';

  /// Image par défaut pour les avatars utilisateurs
  static const String avatarPlaceholder =
      'assets/images/avatar_placeholder.png';
}
