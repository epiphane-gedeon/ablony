import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/user_badges.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/application/auth_providers.dart';
import '../../data/block_repository.dart';
import '../providers/block_provider.dart';

/// Les personnes que j'ai bloquées.
///
/// Vide, l'écran dit à quoi il sert : une liste vide sans explication laisse
/// croire à une panne.
class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bloques = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsersTitle)),
      body: bloques.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (liste) {
          if (liste.isEmpty) {
            return EmptyState(
              icon: Icons.block,
              title: l10n.blockedUsersEmpty,
              message: l10n.blockedUsersHint,
            );
          }

          return ListView.separated(
            itemCount: liste.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _LigneBloquee(uid: liste[i]),
          );
        },
      ),
    );
  }
}

class _LigneBloquee extends ConsumerWidget {
  const _LigneBloquee({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final personne = ref.watch(userByIdProvider(uid));

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Row(
        children: [
          Flexible(
            child: Text(
              personne.value?.username ?? uid,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (personne.value != null) ...[
            const SizedBox(width: 6),
            UserBadges(user: personne.value!, compact: true),
          ],
        ],
      ),
      trailing: TextButton(
        onPressed: () async {
          await ref.read(blockRepositoryProvider).unblock(uid);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.unblockDone)),
          );
        },
        child: Text(l10n.unblockUser),
      ),
    );
  }
}
