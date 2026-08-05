import 'package:flutter/material.dart';

/// Helpers de grille adaptative.
///
/// Principe : on ne fixe jamais un nombre de colonnes en dur, on le **déduit
/// de la largeur réellement disponible**, de façon à garder des vignettes de
/// taille à peu près constante (~180–250 px) quelle que soit la taille de
/// l'écran. Plus l'écran est large, plus il y a de colonnes — plutôt que des
/// vignettes étirées.
///
/// La largeur passée doit venir d'un `LayoutBuilder` (donc la zone de contenu
/// réelle, hors rail de navigation), pas de `MediaQuery`.
abstract final class ResponsiveGrid {
  /// Ratio largeur/hauteur d'une carte produit (identique à l'existant, pour
  /// ne rien changer visuellement sur téléphone).
  static const double productAspectRatio = 0.5;

  static const double productSpacing = 12;
  static const double productRunSpacing = 16;

  /// Nombre de colonnes pour une grille de produits.
  static int productColumns(double width) {
    if (width < 600) return 2;
    if (width < 840) return 3;
    if (width < 1100) return 4;
    if (width < 1400) return 5;
    return 6;
  }

  /// Delegate prêt à l'emploi pour une grille de produits.
  static SliverGridDelegateWithFixedCrossAxisCount productDelegate(
    double width,
  ) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: productColumns(width),
      childAspectRatio: productAspectRatio,
      crossAxisSpacing: productSpacing,
      mainAxisSpacing: productRunSpacing,
    );
  }

  /// Nombre de colonnes pour la grille de catégories.
  ///
  /// Les tuiles de catégorie sont plus larges que hautes (ratio 1.2), on peut
  /// donc en aligner un peu moins que des produits à largeur égale.
  static int categoryColumns(double width) {
    if (width < 600) return 2;
    if (width < 840) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  /// Nombre de colonnes pour la grille de sélection de photos (mise en vente).
  ///
  /// Les vignettes sont carrées et petites : on en met plus par ligne dès
  /// qu'on a de la place, sans jamais descendre sous 3.
  static int photoColumns(double width) {
    if (width < 600) return 3;
    if (width < 840) return 4;
    if (width < 1100) return 5;
    return 6;
  }
}
