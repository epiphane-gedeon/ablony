import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/boost_config.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_status.dart';
import '../providers/product_provider.dart';
import '../widgets/boost_bottom_sheet.dart';
import '../widgets/boost_pack_sheet.dart';

/// Mettre ses annonces en avant.
///
/// La mise en avant existait déjà, mais seulement depuis la fiche d'une
/// annonce — il fallait donc savoir laquelle promouvoir avant de pouvoir le
/// faire. Ici, on les voit toutes, et celles déjà en avant le disent.
class PromotionPage extends ConsumerWidget {
  const PromotionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final utilisateur = ref.watch(authStateProvider).value;

    if (utilisateur == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.promotionTools)));
    }

    // L'entrée du menu est masquée sur mobile, mais la route reste atteignable
    // par lien direct : on referme ici aussi, pour qu'aucun achat de boost ne
    // puisse contourner la facturation du magasin.
    if (!boostsDisponibles) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.promotionTools)),
        body: EmptyState(
          icon: Icons.rocket_launch_outlined,
          title: l10n.promotionUnavailable,
          message: l10n.promotionUnavailableHint,
        ),
      );
    }

    final annonces = ref.watch(sellerProductsProvider(utilisateur.uid));
    final credits = ref.watch(currentUserProvider).value?.boostCredits ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.promotionTools)),
      body: annonces.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (liste) {
          // Seules les annonces en vente peuvent être mises en avant : payer
          // pour promouvoir un article vendu serait de l'argent perdu.
          final promouvables = liste
              .where((p) => p.status == ProductStatus.active)
              .toList();

          return Column(
            children: [
              // La réserve de boosts, toujours en tête : on peut en acheter
              // même sans annonce à promouvoir pour l'instant.
              _CarteReserve(credits: credits),
              const Divider(height: 1),
              Expanded(
                child: promouvables.isEmpty
                    ? EmptyState(
                        icon: Icons.rocket_launch_outlined,
                        title: l10n.promotionEmpty,
                        message: l10n.promotionEmptyHint,
                      )
                    : ListView.separated(
                        itemCount: promouvables.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _LignePromotion(produit: promouvables[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// La réserve de boosts, en tête de la page : combien il en reste, et de quoi
/// en acheter d'avance.
class _CarteReserve extends ConsumerWidget {
  const _CarteReserve({required this.credits});

  final int credits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.promotionCreditsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$credits',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.promotionCreditsHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          // Acheter des lots : dans l'app seulement là où c'est autorisé
          // (`boostsAchatDisponible`). Ailleurs (mobile), on indique où acheter
          // sans lien de paiement direct — les crédits déjà acquis restent
          // utilisables partout.
          if (boostsAchatDisponible)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  await BoostPackSheet.show(context);
                  ref.invalidate(currentUserProvider);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.boostBuyPacks),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.hintColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.boostBuyOnWeb,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LignePromotion extends StatelessWidget {
  const _LignePromotion({required this.produit});

  final Product produit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final enAvant = produit.isBoosted;

    return ListTile(
      onTap: () => context.push('/product/${produit.id}'),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 52,
          height: 52,
          child: produit.imageUrls.isNotEmpty
              ? Image.network(produit.imageUrls.first, fit: BoxFit.cover)
              : Container(color: theme.dividerColor),
        ),
      ),
      title: Text(
        produit.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        enAvant && produit.boostExpiresAt != null
            ? l10n.promotionActiveUntil(
                DateFormat('d MMMM').format(produit.boostExpiresAt!),
              )
            : '${produit.price.round()} FCFA',
        style: TextStyle(
          color: enAvant ? theme.colorScheme.primary : theme.hintColor,
          fontWeight: enAvant ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: enAvant
          // Déjà en avant : rien à vendre de plus, et proposer quand même
          // reviendrait à faire payer deux fois la même chose.
          ? Icon(Icons.rocket_launch, color: theme.colorScheme.primary)
          : FilledButton.tonal(
              onPressed: () => BoostBottomSheet.show(context, produit),
              child: Text(l10n.promotionBoost),
            ),
    );
  }
}
