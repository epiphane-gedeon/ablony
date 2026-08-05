import 'dart:collection';

import 'entities/product.dart';

/// Fusionne une liste de produits classiques avec les produits boostés pour
/// réserver une ligne sur trois (grille à [crossAxisCount] colonnes) aux
/// produits boostés.
///
/// Règles :
/// - Une ligne sur trois (la 3e, la 6e, la 9e, ...) est prioritairement
///   remplie avec des produits boostés, jusqu'à épuisement du pool.
/// - S'il n'y a pas (ou plus) assez de produits boostés pour compléter une
///   ligne réservée, les places libres sont prises par les prochains
///   produits classiques — jamais de case vide.
/// - Un produit boosté n'apparaît qu'une fois dans le résultat : il est
///   retiré du flux classique pour éviter un doublon visuel.
List<Product> mergeWithBoostedRows({
  required List<Product> regularProducts,
  required List<Product> boostedProducts,
  int crossAxisCount = 2,
}) {
  final boostedIds = boostedProducts.map((p) => p.id).toSet();
  final regularQueue = Queue<Product>.of(
    regularProducts.where((p) => !boostedIds.contains(p.id)),
  );
  final boostedQueue = Queue<Product>.of(boostedProducts);

  final result = <Product>[];
  var row = 0;

  while (regularQueue.isNotEmpty || boostedQueue.isNotEmpty) {
    final isReservedRow = (row + 1) % 3 == 0;

    for (var col = 0; col < crossAxisCount; col++) {
      if (isReservedRow && boostedQueue.isNotEmpty) {
        result.add(boostedQueue.removeFirst());
      } else if (regularQueue.isNotEmpty) {
        result.add(regularQueue.removeFirst());
      } else if (boostedQueue.isNotEmpty) {
        result.add(boostedQueue.removeFirst());
      } else {
        break;
      }
    }

    row++;
  }

  return result;
}
