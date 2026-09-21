import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_fav_provider.dart';

/// Bouton réutilisable pour marquer/demarquer un produit en favoris.
///
/// Le cœur bascule *immédiatement* au tap (état optimiste local) sans attendre
/// l'aller-retour Firestore : on ne veut pas que l'utilisateur ait l'impression
/// que rien ne s'est passé et tape une deuxième fois. L'état optimiste est
/// abandonné dès que le stream Firestore confirme la même valeur (ou en cas
/// d'erreur, on revient à la vérité serveur).
class FavToggle extends ConsumerStatefulWidget {
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
  ConsumerState<FavToggle> createState() => _FavToggleState();
}

class _FavToggleState extends ConsumerState<FavToggle> {
  /// Valeur affichée en attendant que le stream confirme. null = on suit la
  /// vérité serveur.
  bool? _optimistic;

  Future<void> _onPressed(bool currentlyFav) async {
    final target = !currentlyFav;
    setState(() => _optimistic = target);
    widget.onChanged?.call();
    try {
      await ref.toggleFavorite(widget.productId);
    } catch (_) {
      // L'écriture a échoué : on abandonne l'optimisme et on réaffiche la
      // vérité serveur.
      if (mounted) setState(() => _optimistic = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serverFav = ref.watch(isProductFavoriteProvider(widget.productId));

    // Le stream a rattrapé notre optimisme → on repasse en mode « suivi
    // serveur » pour refléter d'éventuels changements venus d'ailleurs.
    if (_optimistic != null && _optimistic == serverFav) {
      _optimistic = null;
    }

    final isFav = _optimistic ?? serverFav;

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: widget.size, minHeight: widget.size),
      onPressed: () => _onPressed(isFav),
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? Theme.of(context).colorScheme.primary : Colors.white,
        size: widget.size,
      ),
      tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
    );
  }
}
