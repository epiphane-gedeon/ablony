import 'package:flutter/material.dart';

import 'breakpoints.dart';
import 'responsive_grid.dart';

/// Grille de produits adaptative, centrée et bornée sur les grands écrans.
///
/// Évite de répéter partout le trio `LayoutBuilder` + `ConstrainedBox` +
/// calcul du nombre de colonnes. Le nombre de colonnes est déduit de la
/// largeur réellement disponible (donc hors rail de navigation).
///
/// [itemsBuilder] reçoit le nombre de colonnes retenu : c'est utile quand la
/// composition de la liste en dépend (par exemple la page d'accueil, qui
/// réserve une ligne complète sur trois aux produits boostés). Dans le cas
/// courant, on ignore simplement ce paramètre :
///
/// ```dart
/// ResponsiveProductGrid<Product>(
///   itemsBuilder: (_) => products,
///   itemBuilder: (context, product) => ProductCard(product: product),
/// )
/// ```
class ResponsiveProductGrid<T> extends StatelessWidget {
  /// Construit la liste à afficher, en fonction du nombre de colonnes retenu.
  final List<T> Function(int columns) itemsBuilder;

  /// Construit la carte d'un élément.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Contrôleur de défilement (pagination au scroll).
  final ScrollController? controller;

  /// Padding de la grille. Par défaut, la marge de page adaptative.
  final EdgeInsets? padding;

  /// Pour une grille imbriquée dans une autre zone défilante.
  final bool shrinkWrap;

  /// Physique de défilement (par ex. `NeverScrollableScrollPhysics` si
  /// imbriquée).
  final ScrollPhysics? physics;

  /// Affiche un indicateur de chargement en dernière cellule (pagination).
  final bool showTrailingLoader;

  const ResponsiveProductGrid({
    super.key,
    required this.itemsBuilder,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.showTrailingLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On borne la largeur prise en compte : au-delà, on ajoute des
        // colonnes plutôt que d'étirer les vignettes.
        final gridWidth = constraints.maxWidth > ContentWidth.grid
            ? ContentWidth.grid
            : constraints.maxWidth;
        final columns = ResponsiveGrid.productColumns(gridWidth);
        final items = itemsBuilder(columns);

        final grid = GridView.builder(
          controller: controller,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding ?? EdgeInsets.all(context.pagePadding),
          gridDelegate: ResponsiveGrid.productDelegate(gridWidth),
          itemCount: items.length + (showTrailingLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return itemBuilder(context, items[index]);
          },
        );

        // Sur grand écran, la grille est centrée plutôt qu'étirée.
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ContentWidth.grid),
            child: grid,
          ),
        );
      },
    );
  }
}
