/// Fichier: app_theme.dart
/// Description: Définit le thème complet de l'application Ablony.
/// Ce fichier configure tous les aspects visuels de l'application incluant:
/// - La typographie avec la police Be Vietnam Pro (Google Fonts)
/// - Les couleurs et leur utilisation dans les différents composants
/// - Le style des boutons, champs de texte, cartes, et autres widgets
/// - Material Design 3 pour un design moderne et cohérent
///
/// Police utilisée: Be Vietnam Pro (disponible via Google Fonts)
/// Couleurs principales: Bleu #2385AE et Blanc #FFFFFF

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Classe statique contenant le thème de l'application Ablony.
/// Fournit une configuration ThemeData complète pour Flutter.
class AppTheme {
  // Constructeur privé pour empêcher l'instanciation de cette classe utilitaire
  AppTheme._();

  /// Retourne le thème clair de l'application.
  /// Ce thème est appliqué à toute l'application via MaterialApp.
  static ThemeData get lightTheme {
    return ThemeData(
      // Active Material Design 3 pour un design moderne
      useMaterial3: true,

      // ========================================================================
      // COULEURS PRINCIPALES
      // ========================================================================

      /// Couleur primaire utilisée dans toute l'application
      primaryColor: AppColors.primary,

      /// Couleur de fond par défaut des Scaffold (écrans)
      scaffoldBackgroundColor: AppColors.background,

      // ========================================================================
      // SCHÉMA DE COULEURS (Color Scheme)
      // ========================================================================
      // Définit comment les couleurs sont utilisées dans les différents contextes
      colorScheme: const ColorScheme.light(
        /// Couleur primaire de l'application
        primary: AppColors.primary,

        /// Couleur du contenu sur la couleur primaire (texte sur bleu)
        onPrimary: AppColors.white,

        /// Couleur secondaire (variation claire du bleu)
        secondary: AppColors.primaryLight,

        /// Couleur du contenu sur la couleur secondaire
        onSecondary: AppColors.white,

        /// Couleur pour les erreurs
        error: AppColors.error,

        /// Couleur du contenu sur fond d'erreur
        onError: AppColors.white,

        /// Couleur des surfaces (cartes, modales, etc.)
        surface: AppColors.surface,

        /// Couleur du contenu sur les surfaces
        onSurface: AppColors.textPrimary,

        /// Couleur des surfaces avec variante (champs de texte, etc.)
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),

      // ========================================================================
      // TYPOGRAPHIE - Police Be Vietnam Pro
      // ========================================================================
      // Définit tous les styles de texte utilisés dans l'application
      // Hiérarchie: Display > Headline > Title > Body > Label
      textTheme: GoogleFonts.beVietnamProTextTheme().copyWith(
        // ======================================================================
        // DISPLAY - Très grands titres (utilisés rarement, écrans d'accueil)
        // ======================================================================

        /// Display Large - 57px, Bold (w700)
        /// Utilisation: Titres héros, écrans d'onboarding
        displayLarge: GoogleFonts.beVietnamPro(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),

        /// Display Medium - 45px, Bold (w700)
        /// Utilisation: Grands titres d'accueil
        displayMedium: GoogleFonts.beVietnamPro(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),

        /// Display Small - 36px, SemiBold (w600)
        /// Utilisation: Titres importants de pages
        displaySmall: GoogleFonts.beVietnamPro(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // ======================================================================
        // HEADLINE - Titres de sections et catégories
        // ======================================================================

        /// Headline Large - 32px, SemiBold (w600)
        /// Utilisation: Titres de sections principales
        headlineLarge: GoogleFonts.beVietnamPro(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        /// Headline Medium - 28px, SemiBold (w600)
        /// Utilisation: Titres de sous-sections
        headlineMedium: GoogleFonts.beVietnamPro(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        /// Headline Small - 24px, SemiBold (w600)
        /// Utilisation: Titres de catégories
        headlineSmall: GoogleFonts.beVietnamPro(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // ======================================================================
        // TITLE - Titres de cartes, dialogues, et composants
        // ======================================================================

        /// Title Large - 22px, Medium (w500)
        /// Utilisation: Titres de dialogues, bottom sheets
        titleLarge: GoogleFonts.beVietnamPro(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),

        /// Title Medium - 16px, Medium (w500)
        /// Utilisation: Titres de cartes, éléments de liste
        titleMedium: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),

        /// Title Small - 14px, Medium (w500)
        /// Utilisation: Petits titres, labels importants
        titleSmall: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),

        // ======================================================================
        // BODY - Texte de contenu principal
        // ======================================================================

        /// Body Large - 16px, Regular (w400)
        /// Utilisation: Paragraphes principaux, texte important
        bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),

        /// Body Medium - 14px, Regular (w400)
        /// Utilisation: Texte standard, descriptions
        bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),

        /// Body Small - 12px, Regular (w400), Couleur secondaire
        /// Utilisation: Petits textes, notes, métadonnées
        bodySmall: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),

        // ======================================================================
        // LABEL - Texte de boutons, chips, et badges
        // ======================================================================

        /// Label Large - 14px, Medium (w500)
        /// Utilisation: Boutons principaux, actions importantes
        labelLarge: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),

        /// Label Medium - 12px, Medium (w500)
        /// Utilisation: Chips, tags, badges
        labelMedium: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),

        /// Label Small - 11px, Medium (w500), Couleur secondaire
        /// Utilisation: Petits labels, timestamps
        labelSmall: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),

      // ========================================================================
      // THÈME DE L'APPBAR (Barre supérieure de navigation)
      // ========================================================================
      appBarTheme: AppBarTheme(
        /// Couleur de fond de l'AppBar (blanc)
        backgroundColor: AppColors.white,

        /// Couleur des icônes et texte dans l'AppBar
        foregroundColor: AppColors.textPrimary,

        /// Pas d'ombre sous l'AppBar pour un design épuré
        elevation: 0,

        /// Titre centré dans l'AppBar
        centerTitle: true,

        /// Style du titre de l'AppBar
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // ========================================================================
      // THÈME DES BOUTONS ELEVÉS (Boutons avec fond coloré)
      // ========================================================================
      // Utilisés pour les actions principales (ex: "Connexion", "Enregistrer")
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          /// Fond bleu
          backgroundColor: AppColors.primary,

          /// Texte blanc
          foregroundColor: AppColors.white,

          /// Pas d'ombre pour un design flat moderne
          elevation: 0,

          /// Espacement interne du bouton
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

          /// Coins arrondis de 12px
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          /// Style du texte du bouton
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================================
      // THÈME DES BOUTONS OUTLINED (Boutons avec bordure)
      // ========================================================================
      // Utilisés pour les actions secondaires (ex: "Annuler", "Retour")
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          /// Texte bleu
          foregroundColor: AppColors.primary,

          /// Bordure bleue de 1.5px
          side: const BorderSide(color: AppColors.primary, width: 1.5),

          /// Espacement interne du bouton
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

          /// Coins arrondis de 12px
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          /// Style du texte du bouton
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================================
      // THÈME DES BOUTONS TEXTE (Boutons sans fond ni bordure)
      // ========================================================================
      // Utilisés pour les actions tertiaires (ex: "Mot de passe oublié?")
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          /// Texte bleu
          foregroundColor: AppColors.primary,

          /// Espacement interne réduit
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

          /// Style du texte du bouton
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================================
      // THÈME DES CHAMPS DE SAISIE (TextField, TextFormField)
      // ========================================================================
      inputDecorationTheme: InputDecorationTheme(
        /// Fond rempli avec couleur gris clair
        filled: true,
        fillColor: AppColors.surfaceVariant,

        /// Bordure par défaut - pas de bordure visible, fond gris suffit
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        /// Bordure quand le champ est activé mais pas focus
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        /// Bordure bleue de 2px quand le champ est focus (en cours de saisie)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),

        /// Bordure rouge quand il y a une erreur de validation
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),

        /// Bordure rouge épaisse quand le champ en erreur est focus
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),

        /// Espacement interne du champ (padding)
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        /// Style du texte placeholder (hint)
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),

        /// Style du label flottant
        labelStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // ========================================================================
      // THÈME DES CARTES (Card Widget)
      // ========================================================================
      // Utilisées pour grouper du contenu (produits, profils, etc.)
      cardTheme: CardThemeData(
        /// Fond blanc
        color: AppColors.surface,

        /// Légère élévation pour effet de profondeur
        elevation: 2,

        /// Ombre noire très subtile (10% d'opacité)
        shadowColor: Colors.black.withValues(alpha: 0.1),

        /// Coins arrondis de 16px (plus arrondis que les boutons)
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ========================================================================
      // THÈME DES SÉPARATEURS (Divider Widget)
      // ========================================================================
      dividerTheme: const DividerThemeData(
        /// Couleur gris clair
        color: AppColors.divider,

        /// Épaisseur de 1px
        thickness: 1,

        /// Espace vertical occupé par le divider
        space: 1,
      ),

      // ========================================================================
      // THÈME DES ICÔNES
      // ========================================================================
      iconTheme: const IconThemeData(
        /// Couleur par défaut des icônes (noir)
        color: AppColors.textPrimary,

        /// Taille par défaut des icônes
        size: 24,
      ),

      // ========================================================================
      // THÈME DU BOUTON D'ACTION FLOTTANT (FAB)
      // ========================================================================
      // Bouton rond en bas à droite pour l'action principale
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        /// Fond bleu
        backgroundColor: AppColors.primary,

        /// Icône blanche
        foregroundColor: AppColors.white,

        /// Élévation moyenne pour qu'il se démarque
        elevation: 4,
      ),
    );
  }
}
