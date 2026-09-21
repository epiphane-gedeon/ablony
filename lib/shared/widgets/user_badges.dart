import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_providers.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../l10n/app_localizations.dart';

/// Les badges d'un membre, à côté de son pseudo.
///
/// Deux distinctions, deux couleurs : **Fondateur** (bleu de la marque), donné
/// aux premiers arrivés ; **Star** (doré), attribué à la main par
/// l'administration. Les deux peuvent coexister — un fondateur peut être star.
///
/// Rien si le membre n'a aucun badge : le widget disparaît proprement plutôt
/// que de laisser un espace vide.
class UserBadges extends StatelessWidget {
  const UserBadges({super.key, required this.user, this.compact = false});

  final User user;

  /// En version compacte, seule l'icône/la lettre s'affiche (listes serrées).
  final bool compact;

  static const Color _bleuAblony = Color(0xFF2385AE);
  static const Color _dore = Color(0xFFD4A017);

  @override
  Widget build(BuildContext context) {
    if (!user.isFounder && !user.isStar) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // La star d'abord : c'est la distinction la plus rare. Juste
        // l'étoile dorée, sans rectangle — mais calée sur la même hauteur que
        // le badge Fondateur pour que la ligne reste alignée.
        if (user.isStar)
          SizedBox(
            height: _hauteur,
            child: Center(
              child: Icon(Icons.star, color: _dore, size: _hauteur - 3),
            ),
          ),
        if (user.isStar && user.isFounder) const SizedBox(width: 4),
        if (user.isFounder)
          _Puce(
            fond: _bleuAblony,
            label: compact ? 'F' : l10n.founderBadge,
          ),
      ],
    );
  }
}

/// Hauteur commune à tous les badges, pour une ligne bien alignée.
const double _hauteur = 20;

class _Puce extends StatelessWidget {
  const _Puce({required this.fond, required this.label});

  final Color fond;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _hauteur,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Les badges d'un membre à partir de son seul identifiant.
///
/// Pratique là où on n'a que l'`userId` sous la main — une ligne de
/// conversation, un en-tête de chat, une carte produit : on n'a pas besoin de
/// charger l'utilisateur entier ailleurs pour afficher ses badges.
///
/// Rien ne s'affiche tant que l'utilisateur n'est pas chargé, en cas d'erreur,
/// ou s'il n'a aucun badge — jamais d'espace vide qui clignote.
class UserBadgesById extends ConsumerWidget {
  const UserBadgesById({super.key, required this.userId, this.compact = false});

  final String userId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userByIdProvider(userId)).value;
    if (user == null) return const SizedBox.shrink();
    return UserBadges(user: user, compact: compact);
  }
}
