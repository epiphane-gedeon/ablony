/// Fichier: app_colors.dart
/// Description: Définit toutes les couleurs utilisées dans l'application Ablony.
/// Ce fichier centralise la palette de couleurs pour maintenir une cohérence
/// visuelle à travers toute l'application.
///
/// Couleurs principales:
/// - Bleu (#2385AE): Couleur primaire de la marque
/// - Blanc (#FFFFFF): Couleur secondaire pour les fonds et textes sur bleu

import 'package:flutter/material.dart';

/// Classe statique contenant toutes les couleurs de l'application Ablony.
/// Utilise un constructeur privé pour empêcher l'instanciation.
class AppColors {
  // Constructeur privé pour empêcher l'instanciation de cette classe utilitaire
  AppColors._();

  // ============================================================================
  // COULEURS PRINCIPALES
  // ============================================================================

  /// Couleur primaire de l'application - Bleu Ablony
  /// Utilisée pour les boutons principaux, liens, et éléments interactifs
  static const Color primary = Color(0xFF2385AE);

  /// Couleur blanche pure
  /// Utilisée pour les fonds, textes sur fond bleu, et espaces négatifs
  static const Color white = Color(0xFFFFFFFF);

  // ============================================================================
  // VARIATIONS DU BLEU PRINCIPAL
  // ============================================================================

  /// Version plus claire du bleu principal
  /// Utilisée pour les états de survol (hover) et les éléments secondaires
  static const Color primaryLight = Color(0xFF4A9DC4);

  /// Version plus foncée du bleu principal
  /// Utilisée pour les états actifs et les ombres colorées
  static const Color primaryDark = Color(0xFF1A6890);

  // ============================================================================
  // COULEURS DE TEXTE
  // ============================================================================

  /// Couleur du texte principal - Noir
  /// Utilisée pour tous les textes importants et titres
  static const Color textPrimary = Color(0xFF000000);

  /// Couleur du texte secondaire - Gris moyen
  /// Utilisée pour les sous-titres, descriptions et textes de moindre importance
  static const Color textSecondary = Color(0xFF757575);

  /// Couleur du texte sur fond bleu - Blanc
  /// Utilisée pour les textes sur les boutons et éléments avec fond bleu
  static const Color textOnPrimary = white;

  // ============================================================================
  // COULEURS DE FOND
  // ============================================================================

  /// Couleur de fond principale de l'application
  static const Color background = white;

  /// Couleur des surfaces (cartes, modales, etc.)
  static const Color surface = white;

  /// Couleur des surfaces de variante - Gris très clair
  /// Utilisée pour les champs de saisie et zones légèrement différenciées
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // ============================================================================
  // COULEURS SYSTÈME (États et notifications)
  // ============================================================================

  /// Couleur pour les messages d'erreur et actions destructives
  static const Color error = Color(0xFFD32F2F);

  /// Couleur pour les messages de succès et confirmations
  static const Color success = Color(0xFF388E3C);

  /// Couleur pour les avertissements et alertes
  static const Color warning = Color(0xFFF57C00);

  /// Couleur pour les messages d'information
  static const Color info = primary;

  // ============================================================================
  // COULEURS DE BORDURE ET SÉPARATEURS
  // ============================================================================

  /// Couleur des séparateurs et lignes de division
  static const Color divider = Color(0xFFE0E0E0);

  /// Couleur des bordures des éléments
  static const Color border = Color(0xFFBDBDBD);
}
