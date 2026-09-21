import 'package:equatable/equatable.dart';

import 'product.dart';

/// Une page de résultats de recherche, avec de quoi demander la suivante.
///
/// La recherche téléchargeait autrefois **tout** le catalogue puis filtrait en
/// mémoire : à six mille annonces, le quota Firestore gratuit était épuisé
/// après huit recherches par jour. Elle est désormais paginée, et il faut donc
/// rapporter un curseur — d'où ce type plutôt qu'une simple liste.
class SearchPage extends Equatable {
  const SearchPage({required this.products, required this.nextCursor});

  final List<Product> products;

  /// L'identifiant du dernier document de la page, à passer en `startAfter`
  /// pour obtenir la suivante. `null` quand il n'y a plus rien à charger.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [products, nextCursor];
}
