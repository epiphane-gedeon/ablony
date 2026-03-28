import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_fav_provider.dart';

/// Bouton réutilisable pour marquer/demarquer un produit en favoris
class FavToggle extends ConsumerWidget {
  final String productId;
  final double size;
  final VoidCallback? onChanged;

  const FavToggle({
    super.key,
    required this.productId,
    this.size = 28,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isProductFavoriteProvider(productId));

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      onPressed: () async {
        await ref.toggleFavorite(productId);
        if (onChanged != null) onChanged!();
      },
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? Theme.of(context).colorScheme.primary : Colors.white,
        size: size,
      ),
      tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
    );
  }
}
