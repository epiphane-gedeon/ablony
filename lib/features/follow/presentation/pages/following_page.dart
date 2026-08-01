import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/follow_provider.dart';
import '../widgets/user_list_view.dart';
import '../../../../l10n/app_localizations.dart';

/// Liste des utilisateurs suivis par un utilisateur.
class FollowingPage extends ConsumerWidget {
  final String userId;

  const FollowingPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final followingAsync = ref.watch(followingProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.followingPageTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: UserListView(
        usersAsync: followingAsync,
        emptyMessage: l10n.noFollowingYet,
      ),
    );
  }
}
