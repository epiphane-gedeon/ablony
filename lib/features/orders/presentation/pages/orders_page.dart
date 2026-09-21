import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/order_repository.dart';
import '../../domain/models/order_summary.dart';
import '../providers/order_provider.dart';
import '../widgets/order_tile.dart';

/// Ventes et achats.
///
/// C'est ici qu'on vient quand on se demande « où en est ma commande ? » — la
/// question la plus fréquente sur une place de seconde main, où l'attente dure
/// plusieurs jours. Et c'est le seul endroit d'où un vendeur distrait rattrape
/// un colis oublié.
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key, this.ongletVentes = false});

  /// Arrive-t-on depuis une notification de vente ?
  final bool ongletVentes;

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _onglets = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.ongletVentes ? 1 : 0,
  );

  @override
  void dispose() {
    _onglets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ordersTitle),
        bottom: TabBar(
          controller: _onglets,
          tabs: [
            Tab(text: l10n.ordersPurchases),
            Tab(text: l10n.ordersSales),
          ],
        ),
      ),
      body: TabBarView(
        controller: _onglets,
        children: const [
          _Liste(side: OrderSide.purchase),
          _Liste(side: OrderSide.sale),
        ],
      ),
    );
  }
}

class _Liste extends ConsumerWidget {
  const _Liste({required this.side});

  final OrderSide side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final commandes = ref.watch(ordersProvider(side));
    final limite = ref.watch(limitProviderFor(side));

    return commandes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (liste) {
        if (liste.isEmpty) {
          // Deux vides différents : « rien acheté » et « rien vendu »
          // n'appellent pas la même suite.
          return EmptyState(
            icon: side == OrderSide.purchase
                ? Icons.shopping_bag_outlined
                : Icons.sell_outlined,
            title: side == OrderSide.purchase
                ? l10n.ordersNoPurchases
                : l10n.ordersNoSales,
            message: side == OrderSide.purchase
                ? l10n.ordersNoPurchasesHint
                : l10n.ordersNoSalesHint,
          );
        }

        // Une page pleine veut dire qu'il y en a peut-être d'autres.
        final peutEtrePlus = liste.length >= limite;

        return ListView.builder(
          itemCount: liste.length + (peutEtrePlus ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == liste.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.read(limitProviderFor(side).notifier).plus(),
                    child: Text(l10n.ordersLoadMore),
                  ),
                ),
              );
            }
            return OrderTile(commande: liste[i]);
          },
        );
      },
    );
  }
}

/// Exposé pour la taille de page, utilisée par l'écran vide.
const int ordersPageSize = OrderRepository.pageSize;
