/// Fichier: app_colors.dart
/// Description: Définit toutes les couleurs utilisées dans l'application Ablony.
/// Ce fichier centralise la palette de couleurs pour les thèmes clair et sombre.
///
/// Couleurs principales:
/// - Mode clair: Bleu (#2385AE), fond blanc
/// - Mode sombre: Bleu clair (#64B5F6), fond noir Material Design

import 'package:flutter/material.dart';

/// Classe statique contenant toutes les couleurs de l'application Ablony.
/// Supporte les thèmes clair et sombre avec des palettes adaptées.
class AppColors {
  // Constructeur privé pour empêcher l'instanciation
  AppColors._();

  // ============================================================================
  // COULEURS MODE CLAIR (LIGHT)
  // ============================================================================

  /// Couleur primaire - Bleu Ablony
  static const Color lightPrimary = Color(0xFF2385AE);

  /// Couleur primaire claire
  static const Color lightPrimaryLight = Color(0xFF4A9DC4);

  /// Couleur primaire foncée
  static const Color lightPrimaryDark = Color(0xFF1A6890);

  /// Fond principal
  static const Color lightBackground = Color(0xFFFFFFFF);

  /// Surface (cartes, modales)
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Surface variante (inputs, zones différenciées)
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);

  /// Texte principal
  static const Color lightTextPrimary = Color(0xFF000000);

  /// Texte secondaire
  static const Color lightTextSecondary = Color(0xFF757575);

  /// Texte sur couleur primaire
  static const Color lightTextOnPrimary = Color(0xFFFFFFFF);

  /// Bordures
  static const Color lightBorder = Color(0xFFBDBDBD);

  /// Séparateurs
  static const Color lightDivider = Color(0xFFE0E0E0);

  // ============================================================================
  // COULEURS MODE SOMBRE (DARK)
  // ============================================================================

  /// Couleur primaire - Bleu clair pour meilleur contraste
  static const Color darkPrimary = Color(0xFF2385AE);

  /// Couleur primaire claire
  static const Color darkPrimaryLight = Color(0xFF90CAF9);

  /// Couleur primaire foncée
  static const Color darkPrimaryDark = Color(0xFF42A5F5);

  /// Fond principal - Material Design dark
  static const Color darkBackground = Color(0xFF121212);

  /// Surface élevée
  static const Color darkSurface = Color(0xFF1E1E1E);

  /// Surface variante (inputs, cartes)
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);

  /// Texte principal
  static const Color darkTextPrimary = Color(0xFFE0E0E0);

  /// Texte secondaire
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  /// Texte sur couleur primaire
  static const Color darkTextOnPrimary = Color(0xFF000000);

  /// Bordures
  static const Color darkBorder = Color(0xFF3A3A3A);

  /// Séparateurs
  static const Color darkDivider = Color(0xFF2A2A2A);

  // ============================================================================
  // COULEURS SYSTÈME (Identiques pour les deux thèmes)
  // ============================================================================

  /// Couleur d'erreur
  static const Color error = Color(0xFFD32F2F);

  /// Couleur de succès
  static const Color success = Color(0xFF388E3C);

  /// Couleur d'avertissement
  static const Color warning = Color(0xFFF57C00);

  /// Couleur d'information
  static const Color info = Color(0xFF2196F3);

  // ============================================================================
  // MÉTHODES HELPER POUR OBTENIR LES COULEURS SELON LE THÈME
  // ============================================================================

  /// Retourne la couleur primaire selon le mode
  static Color primaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkPrimary : lightPrimary;

  /// Retourne la couleur de fond selon le mode
  static Color backgroundFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkBackground : lightBackground;

  /// Retourne la couleur de surface selon le mode
  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;

  /// Retourne la couleur de surface variante selon le mode
  static Color surfaceVariantFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaceVariant : lightSurfaceVariant;

  /// Retourne la couleur de texte principal selon le mode
  static Color textPrimaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  /// Retourne la couleur de texte secondaire selon le mode
  static Color textSecondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  /// Retourne la couleur de bordure selon le mode
  static Color borderFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  // ============================================================================
  // COMPATIBILITÉ RÉTROACTIVE (pour transition progressive)
  // ============================================================================

  /// Couleur primaire (défaut: mode clair)
  static const Color primary = lightPrimary;

  /// Couleur blanche
  static const Color white = Color(0xFFFFFFFF);

  /// Couleur primaire claire (défaut: mode clair)
  static const Color primaryLight = lightPrimaryLight;

  /// Couleur primaire foncée (défaut: mode clair)
  static const Color primaryDark = lightPrimaryDark;

  /// Texte principal (défaut: mode clair)
  static const Color textPrimary = lightTextPrimary;

  /// Texte secondaire (défaut: mode clair)
  static const Color textSecondary = lightTextSecondary;

  /// Texte sur primaire (défaut: mode clair)
  static const Color textOnPrimary = lightTextOnPrimary;

  /// Fond (défaut: mode clair)
  static const Color background = lightBackground;

  /// Surface (défaut: mode clair)
  static const Color surface = lightSurface;

  /// Surface variante (défaut: mode clair)
  static const Color surfaceVariant = lightSurfaceVariant;

  /// Bordure (défaut: mode clair)
  static const Color border = lightBorder;

  /// Séparateur (défaut: mode clair)
  static const Color divider = lightDivider;
}
