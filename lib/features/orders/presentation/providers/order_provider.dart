import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/order_repository.dart';
import '../../domain/models/order_summary.dart';

/// Combien de lignes on affiche.
///
/// Une fenêtre qu'on agrandit plutôt qu'un curseur de pagination : les deux
/// listes sont courtes au début, et relire tout le flux garde les états de
/// colis à jour sans second mécanisme à synchroniser.
class OrderLimit extends Notifier<int> {
  @override
  int build() => OrderRepository.pageSize;

  void plus() => state = state + OrderRepository.pageSize;
}

/// Un compteur par onglet : agrandir la liste des achats ne doit pas
/// recharger celle des ventes.
final purchaseLimitProvider =
    NotifierProvider<OrderLimit, int>(OrderLimit.new);

final saleLimitProvider = NotifierProvider<OrderLimit, int>(OrderLimit.new);

NotifierProvider<OrderLimit, int> limitProviderFor(OrderSide side) =>
    side == OrderSide.purchase ? purchaseLimitProvider : saleLimitProvider;

final ordersProvider =
    StreamProvider.family<List<OrderSummary>, OrderSide>((ref, side) {
  final limite = ref.watch(limitProviderFor(side));
  return ref.watch(orderRepositoryProvider).watch(side, limit: limite);
});
