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
      primaryColor: const Color(0xFF2385AE),

      /// Couleur de fond par défaut des Scaffold (écrans)
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),

      // ========================================================================
      // SCHÉMA DE COULEURS (Color Scheme)
      // ========================================================================
      // Définit comment les couleurs sont utilisées dans les différents contextes
      colorScheme: const ColorScheme.light(
        /// Couleur primaire de l'application
        primary: Color(0xFF2385AE),

        /// Couleur du contenu sur la couleur primaire (texte sur bleu)
        onPrimary: Color(0xFFFFFFFF),

        /// Couleur secondaire (variation claire du bleu)
        secondary: Color(0xFF4A9DC4),

        /// Couleur du contenu sur la couleur secondaire
        onSecondary: Color(0xFFFFFFFF),

        /// Couleur pour les erreurs
        error: Color(0xFFD32F2F),

        /// Couleur du contenu sur fond d'erreur
        onError: Color(0xFFFFFFFF),

        /// Couleur des surfaces (cartes, modales, etc.)
        surface: Color(0xFFFFFFFF),

        /// Couleur du contenu sur les surfaces
        onSurface: Color(0xFF000000),

        /// Couleur des surfaces avec variante (champs de texte, etc.)
        surfaceContainerHighest: Color(0xFFF5F5F5),

        /// Couleur pour le texte secondaire
        onSurfaceVariant: Color(0xFF757575),

        // ========================================================================
        // COULEURS DES BULLES DE MESSAGE (Message Bubbles)
        // ========================================================================
        /// Background des messages envoyés (isMe) - Noir
        tertiary: Color(0xFF000000),

        /// Texte des messages envoyés (isMe) - Blanc
        onTertiary: Color(0xFFFFFFFF),

        /// Background des messages reçus (notIsMe) - Transparent
        tertiaryContainer: Colors.transparent,

        /// Texte des messages reçus (notIsMe) en mode clair - Noir
        onTertiaryContainer: Color(0xFF000000),
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
          color: const Color(0xFF000000),
        ),

        /// Display Medium - 45px, Bold (w700)
        /// Utilisation: Grands titres d'accueil
        displayMedium: GoogleFonts.beVietnamPro(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF000000),
        ),

        /// Display Small - 36px, SemiBold (w600)
        /// Utilisation: Titres importants de pages
        displaySmall: GoogleFonts.beVietnamPro(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF000000),
        ),

        // ======================================================================
        // HEADLINE - Titres de sections et catégories
        // ======================================================================

        /// Headline Large - 32px, SemiBold (w600)
        /// Utilisation: Titres de sections principales
        headlineLarge: GoogleFonts.beVietnamPro(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF000000),
        ),

        /// Headline Medium - 28px, SemiBold (w600)
        /// Utilisation: Titres de sous-sections
        headlineMedium: GoogleFonts.beVietnamPro(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF000000),
        ),

        /// Headline Small - 24px, SemiBold (w600)
        /// Utilisation: Titres de catégories
        headlineSmall: GoogleFonts.beVietnamPro(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF000000),
        ),

        // ======================================================================
        // TITLE - Titres de cartes, dialogues, et composants
        // ======================================================================

        /// Title Large - 22px, Medium (w500)
        /// Utilisation: Titres de dialogues, bottom sheets
        titleLarge: GoogleFonts.beVietnamPro(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF000000),
        ),

        /// Title Medium - 16px, Medium (w500)
        /// Utilisation: Titres de cartes, éléments de liste
        titleMedium: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF000000),
        ),

        /// Title Small - 14px, Medium (w500)
        /// Utilisation: Petits titres, labels importants
        titleSmall: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF000000),
        ),

        // ======================================================================
        // BODY - Texte de contenu principal
        // ======================================================================

        /// Body Large - 16px, Regular (w400)
        /// Utilisation: Paragraphes principaux, texte important
        bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF000000),
        ),

        /// Body Medium - 14px, Regular (w400)
        /// Utilisation: Texte standard, descriptions
        bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF000000),
        ),

        /// Body Small - 12px, Regular (w400), Couleur secondaire
        /// Utilisation: Petits textes, notes, métadonnées
        bodySmall: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF757575),
        ),

        // ======================================================================
        // LABEL - Texte de boutons, chips, et badges
        // ======================================================================

        /// Label Large - 14px, Medium (w500)
        /// Utilisation: Boutons principaux, actions importantes
        labelLarge: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF000000),
        ),

        /// Label Medium - 12px, Medium (w500)
        /// Utilisation: Chips, tags, badges
        labelMedium: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF000000),
        ),

        /// Label Small - 11px, Medium (w500), Couleur secondaire
        /// Utilisation: Petits labels, timestamps
        labelSmall: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF757575),
        ),
      ),

      // ========================================================================
      // THÈME DE L'APPBAR (Barre supérieure de navigation)
      // ========================================================================
      appBarTheme: AppBarTheme(
        /// Couleur de fond de l'AppBar (blanc)
        backgroundColor: const Color(0xFFFFFFFF),

        /// Couleur des icônes et texte dans l'AppBar
        foregroundColor: const Color(0xFF000000),

        /// Pas d'ombre sous l'AppBar pour un design épuré
        elevation: 0,

        /// Titre centré dans l'AppBar
        centerTitle: true,

        /// Style du titre de l'AppBar
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF000000),
        ),
      ),

      // ========================================================================
      // THÈME DES BOUTONS ELEVÉS (Boutons avec fond coloré)
      // ========================================================================
      // Utilisés pour les actions principales (ex: "Connexion", "Enregistrer")
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          /// Fond bleu
          backgroundColor: const Color(0xFF2385AE),

          /// Texte blanc
          foregroundColor: const Color(0xFFFFFFFF),

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
          foregroundColor: const Color(0xFF2385AE),

          /// Bordure bleue de 1.5px
          side: const BorderSide(color: const Color(0xFF2385AE), width: 1.5),

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
          foregroundColor: const Color(0xFF2385AE),

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
        fillColor: const Color(0xFFF5F5F5),

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
          borderSide: const BorderSide(
            color: const Color(0xFF2385AE),
            width: 2,
          ),
        ),

        /// Bordure rouge quand il y a une erreur de validation
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: const Color(0xFFD32F2F),
            width: 1,
          ),
        ),

        /// Bordure rouge épaisse quand le champ en erreur est focus
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: const Color(0xFFD32F2F),
            width: 2,
          ),
        ),

        /// Espacement interne du champ (padding)
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        /// Style du texte placeholder (hint)
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: const Color(0xFF757575),
        ),

        /// Style du label flottant
        labelStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: const Color(0xFF757575),
        ),
      ),

      // ========================================================================
      // THÈME DES CARTES (Card Widget)
      // ========================================================================
      // Utilisées pour grouper du contenu (produits, profils, etc.)
      cardTheme: CardThemeData(
        /// Fond blanc
        color: const Color(0xFFFFFFFF),

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
        color: const Color(0xFFE0E0E0),

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
        color: const Color(0xFF000000),

        /// Taille par défaut des icônes
        size: 24,
      ),

      // ========================================================================
      // THÈME DU BOUTON D'ACTION FLOTTANT (FAB)
      // ========================================================================
      // Bouton rond en bas à droite pour l'action principale
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        /// Fond bleu
        backgroundColor: const Color(0xFF2385AE),

        /// Icône blanche
        foregroundColor: const Color(0xFFFFFFFF),

        /// Élévation moyenne pour qu'il se démarque
        elevation: 4,
      ),
    );
  }

  // ============================================================================
  // THÈME SOMBRE (DARK)
  // ============================================================================

  /// Retourne le thème sombre de l'application.
  /// Optimisé pour une utilisation en faible luminosité avec des couleurs adaptées.
  static ThemeData get darkTheme {
    return ThemeData(
      // Active Material Design 3
      useMaterial3: true,
      brightness: Brightness.dark,

      // ========================================================================
      // COULEURS PRINCIPALES
      // ========================================================================
      primaryColor: const Color(0xFF2385AE),
      scaffoldBackgroundColor: const Color(0xFF121212),

      // ========================================================================
      // SCHÉMA DE COULEURS (Color Scheme)
      // ========================================================================
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2385AE),
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFF90CAF9),
        onSecondary: Color(0xFF000000),
        error: Color(0xFFD32F2F),
        onError: Color(0xFFFFFFFF),
        surface: Color(0xFF1E1E1E),
        onSurface: Color(0xFFE0E0E0),
        surfaceContainerHighest: Color(0xFF2C2C2C),
        onSurfaceVariant: Color(0xFFB0B0B0),

        // ========================================================================
        // COULEURS DES BULLES DE MESSAGE (Message Bubbles)
        // ========================================================================
        /// Background des messages envoyés (isMe) - Noir
        tertiary: Color(0xFF000000),

        /// Texte des messages envoyés (isMe) - Blanc
        onTertiary: Color(0xFFFFFFFF),

        /// Background des messages reçus (notIsMe) - Transparent
        tertiaryContainer: Colors.transparent,

        /// Texte des messages reçus (notIsMe) en mode sombre - Blanc
        onTertiaryContainer: Color(0xFFFFFFFF),
      ),

      // ========================================================================
      // TYPOGRAPHIE - Police Be Vietnam Pro
      // ========================================================================
      textTheme: GoogleFonts.beVietnamProTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.beVietnamPro(
              fontSize: 57,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0E0E0),
            ),
            displayMedium: GoogleFonts.beVietnamPro(
              fontSize: 45,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0E0E0),
            ),
            displaySmall: GoogleFonts.beVietnamPro(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE0E0E0),
            ),
            headlineLarge: GoogleFonts.beVietnamPro(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE0E0E0),
            ),
            headlineMedium: GoogleFonts.beVietnamPro(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE0E0E0),
            ),
            headlineSmall: GoogleFonts.beVietnamPro(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE0E0E0),
            ),
            titleLarge: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE0E0E0),
            ),
            titleMedium: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE0E0E0),
            ),
            titleSmall: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE0E0E0),
            ),
            bodyLarge: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFE0E0E0),
            ),
            bodyMedium: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFE0E0E0),
            ),
            bodySmall: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFB0B0B0),
            ),
            labelLarge: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE0E0E0),
            ),
            labelMedium: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE0E0E0),
            ),
            labelSmall: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFB0B0B0),
            ),
          ),

      // ========================================================================
      // THÈME DE L'APPBAR
      // ========================================================================
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: const Color(0xFFE0E0E0),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE0E0E0),
        ),
      ),

      // ========================================================================
      // THÈME DES BOUTONS ELEVÉS
      // ========================================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2385AE),
          foregroundColor: const Color(0xFF000000),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================================
      // THÈME DES BOUTONS OUTLINED
      // ========================================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2385AE),
          side: const BorderSide(color: const Color(0xFF2385AE), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================================
      // THÈME DES BOUTONS TEXTE
      // ========================================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2385AE),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================================
      // THÈME DES CHAMPS DE SAISIE
      // ========================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: const Color(0xFF2385AE),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: const Color(0xFFD32F2F),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: const Color(0xFFD32F2F),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: const Color(0xFFB0B0B0),
        ),
        labelStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: const Color(0xFFB0B0B0),
        ),
      ),

      // ========================================================================
      // THÈME DES CARTES
      // ========================================================================
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ========================================================================
      // THÈME DES SÉPARATEURS
      // ========================================================================
      dividerTheme: const DividerThemeData(
        color: const Color(0xFF2A2A2A),
        thickness: 1,
        space: 1,
      ),

      // ========================================================================
      // THÈME DES ICÔNES
      // ========================================================================
      iconTheme: const IconThemeData(color: const Color(0xFFE0E0E0), size: 24),

      // ========================================================================
      // THÈME DU BOUTON D'ACTION FLOTTANT (FAB)
      // ========================================================================
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF2385AE),
        foregroundColor: const Color(0xFF000000),
        elevation: 4,
      ),
    );
  }
}

// ==============================================================================
// EXTENSION POUR LES COULEURS DES BULLES DE MESSAGE
// ==============================================================================
/// Extension pour faciliter l'accès aux couleurs des bulles de message
extension MessageBubbleColors on ColorScheme {
  /// Background des messages envoyés (isMe) - Noir (clair et sombre)
  Color get bubbleSentBackground => tertiary;

  /// Texte des messages envoyés (isMe) - Blanc (clair et sombre)
  Color get bubbleSentText => onTertiary;

  /// Background des messages reçus (notIsMe) - Transparent (clair et sombre)
  Color get bubbleReceivedBackground => tertiaryContainer;

  /// Texte des messages reçus (notIsMe) - Noir (clair) / Blanc (sombre)
  Color get bubbleReceivedText => onTertiaryContainer;
}
