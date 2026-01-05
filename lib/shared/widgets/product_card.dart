import 'package:flutter/material.dart';
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
class ProductCard extends StatelessWidget {
  final String? imageUrl;
  final String brand;
  final String? size;
  final String condition;
  final double price;
  final double priceWithProtection;
  final int? favoritesCount;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const ProductCard({
    super.key,
    this.imageUrl,
    required this.brand,
    this.size,
    required this.condition,
    required this.price,
    required this.priceWithProtection,
    this.favoritesCount,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl!,
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
                if (favoritesCount != null && favoritesCount! > 0)
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
                            favoritesCount.toString(),
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
                  brand,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Taille et état
                Text(
                  size != null ? '$size • $condition' : condition,
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
                  '${price.toStringAsFixed(0)} FCFA',
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
                        priceWithProtection.toStringAsFixed(0),
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
