import 'package:flutter/widgets.dart';

/// Classes de taille d'écran, alignées sur les *window size classes* de
/// Material 3 (https://m3.material.io/foundations/layout/applying-layout).
///
/// On raisonne toujours en **largeur disponible**, jamais en « est-ce un
/// téléphone ou un ordinateur » : une fenêtre de navigateur réduite sur un
/// grand écran doit se comporter comme un téléphone, et une tablette en
/// paysage comme un petit ordinateur.
enum ScreenSize {
  /// < 600 — téléphones en portrait
  compact,

  /// 600–839 — téléphones en paysage, petites tablettes, fenêtres étroites
  medium,

  /// 840–1199 — tablettes en paysage, petits écrans d'ordinateur
  expanded,

  /// 1200–1599 — écrans d'ordinateur classiques
  large,

  /// ≥ 1600 — très grands écrans
  extraLarge;

  /// Détermine la classe de taille à partir d'une largeur en pixels logiques.
  static ScreenSize fromWidth(double width) {
    if (width < Breakpoints.medium) return ScreenSize.compact;
    if (width < Breakpoints.expanded) return ScreenSize.medium;
    if (width < Breakpoints.large) return ScreenSize.expanded;
    if (width < Breakpoints.extraLarge) return ScreenSize.large;
    return ScreenSize.extraLarge;
  }

  /// true si l'écran est au moins aussi large que [other].
  bool isAtLeast(ScreenSize other) => index >= other.index;

  /// Raccourcis de lisibilité
  bool get isCompact => this == ScreenSize.compact;
  bool get isMedium => this == ScreenSize.medium;

  /// true dès qu'on quitte le format « téléphone en portrait ».
  bool get isWide => index >= ScreenSize.medium.index;
}

/// Seuils de bascule (en pixels logiques), valeurs Material 3.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;
  static const double extraLarge = 1600;
}

/// Accès pratique aux informations responsive depuis un [BuildContext].
///
/// ⚠️ Ces extensions se basent sur `MediaQuery`, donc sur la **fenêtre
/// entière**. Pour dimensionner le contenu *à l'intérieur* d'une zone
/// réduite (par ex. à droite d'un rail de navigation), préférer un
/// `LayoutBuilder` et les helpers de `responsive_grid.dart`, qui prennent la
/// largeur réellement disponible.
extension ResponsiveContext on BuildContext {
  /// Classe de taille de la fenêtre.
  ScreenSize get screenSize =>
      ScreenSize.fromWidth(MediaQuery.sizeOf(this).width);

  /// true sur téléphone en portrait (< 600).
  bool get isCompact => screenSize.isCompact;

  /// true dès 600 : on peut se permettre une navigation latérale.
  bool get isWideScreen => screenSize.isWide;

  /// Marge horizontale de page, qui grandit avec l'écran mais reste bornée.
  ///
  /// Remplace les `screenWidth * 0.04` : sur un écran de 1920 px, 4 % font
  /// 77 px de marge, ce qui déséquilibre complètement la mise en page.
  double get pagePadding => switch (screenSize) {
    ScreenSize.compact => 16,
    ScreenSize.medium => 20,
    ScreenSize.expanded => 24,
    ScreenSize.large || ScreenSize.extraLarge => 32,
  };

  /// Espacement vertical standard entre blocs, adapté à la taille d'écran.
  double get sectionSpacing => switch (screenSize) {
    ScreenSize.compact => 16,
    ScreenSize.medium => 20,
    ScreenSize.expanded || ScreenSize.large || ScreenSize.extraLarge => 24,
  };

  /// Largeur de référence pour les dimensionnements **proportionnels**,
  /// bornée à [max].
  ///
  /// Beaucoup d'écrans dimensionnent leurs marges en pourcentage de la
  /// largeur (`largeur * 0.04`). C'est correct sur téléphone, mais absurde
  /// sur ordinateur : 4 % de 1920 px font 77 px de marge, et une image à
  /// 35 % ferait 672 px de côté. En bornant la largeur de référence, les
  /// proportions restent celles pensées pour le mobile, et la mise en page
  /// cesse de grandir une fois la borne atteinte.
  double layoutWidth([double max = ContentWidth.form]) {
    final width = MediaQuery.sizeOf(this).width;
    return width < max ? width : max;
  }

  /// Équivalent vertical de [layoutWidth], pour les hauteurs exprimées en
  /// pourcentage de la hauteur d'écran.
  double layoutHeight([double max = 900]) {
    final height = MediaQuery.sizeOf(this).height;
    return height < max ? height : max;
  }
}

/// Largeurs maximales de contenu.
///
/// Au-delà, on centre plutôt que d'étirer : une ligne de texte de 1900 px de
/// large est illisible, et un formulaire étiré sur toute la largeur d'un
/// écran d'ordinateur donne une impression de page cassée.
abstract final class ContentWidth {
  /// Formulaires, réglages, contenu de lecture (une seule colonne).
  static const double form = 560;

  /// Pages de détail, conversations, listes simples.
  static const double standard = 840;

  /// Grilles de produits : on autorise plus large pour garder une grille
  /// dense, mais on borne quand même pour éviter des vignettes géantes.
  static const double grid = 1500;
}
