import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/product/presentation/providers/product_provider.dart';
import '../../l10n/app_localizations.dart';

/// Carte de produit réutilisable
///
/// Affiche les informations d'un produit :
/// - Image du produit
/// - Marque
/// - Taille (optionnelle)
/// - État (condition)
/// - Prix classique
/// - Prix avec protection client (en bleu)
/// - Bouton favoris
class ProductCard extends ConsumerWidget {
  final Product? product; // Passer le produit complet pour une résolution automatique
  final String? imageUrl;
  final dynamic brand;
  final dynamic size;
  final String? sizeAttributeId;
  final String? brandAttributeId;
  final dynamic condition;
  final double price;
  final double priceWithProtection;
  final int? favoritesCount;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const ProductCard({
    super.key,
    this.product,
    this.imageUrl,
    this.brand,
    this.size,
    this.sizeAttributeId,
    this.brandAttributeId,
    this.condition,
    this.price = 0,
    this.priceWithProtection = 0,
    this.favoritesCount,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Utiliser les données du produit s'il est fourni, sinon utiliser les paramètres individuels
    final effectiveImageUrl = imageUrl ?? product?.imageUrls.firstOrNull;
    final effectiveBrand = brand ?? product?.primaryBrandValue ?? product?.title;
    final effectiveBrandId = brandAttributeId ?? product?.primaryBrandAttributeId ?? 'brand';
    final effectiveSize = size ?? product?.primarySizeValue;
    final effectiveSizeId = sizeAttributeId ?? product?.primarySizeAttributeId ?? 'size';
    final effectiveCondition = condition ?? product?.condition.index;
    final effectivePrice = product?.price ?? price;
    final effectivePriceWithProtection = product != null ? product!.price * 1.05 : priceWithProtection;
    final effectiveFavoritesCount = favoritesCount ?? product?.favoritesCount;

    // Résolution dynamique des libellés (index -> label ou string -> string)
    final resolvedBrand = ref.watch(
          attributeLabelProvider((attributeId: effectiveBrandId, value: effectiveBrand)),
        ).value ??
        effectiveBrand?.toString() ??
        '';

    final resolvedCondition = ref.watch(
          attributeLabelProvider((attributeId: 'condition', value: effectiveCondition)),
        ).value ??
        effectiveCondition?.toString() ??
        '';

    String? resolvedSize;
    if (effectiveSize != null) {
      resolvedSize = ref.watch(
            attributeLabelProvider(
                (attributeId: effectiveSizeId, value: effectiveSize)),
          ).value ??
          effectiveSize.toString();
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du produit avec badge favoris
          Expanded(
            child: Stack(
              children: [
                // Image avec coins arrondis partout
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: effectiveImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            effectiveImageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        ),
                ),

                // Badge favoris (coin inférieur droit)
                if (effectiveFavoritesCount != null && effectiveFavoritesCount > 0)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            effectiveFavoritesCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Informations du produit (sans background, directement sur le fond)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Marque
                Text(
                  resolvedBrand,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Taille et état
                Text(
                  resolvedSize != null
                      ? '$resolvedSize • $resolvedCondition'
                      : resolvedCondition,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Prix classique
                Text(
                  '${effectivePrice.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                // Prix avec protection (en bleu)
                Row(
                  children: [
                    Text(
                      l10n.priceWithProtection(
                        effectivePriceWithProtection.toStringAsFixed(0),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_user,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
