import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/follow_provider.dart';
import '../widgets/user_list_view.dart';
import '../../../../l10n/app_localizations.dart';

/// Liste des abonnés d'un utilisateur.
class FollowersPage extends ConsumerWidget {
  final String userId;

  const FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final followersAsync = ref.watch(followersProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followersPageTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: UserListView(
        usersAsync: followersAsync,
        emptyMessage: l10n.noFollowersYet,
      ),
    );
  }
}
