import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user.dart';
import '../../../../l10n/app_localizations.dart';

/// Liste de profils utilisateurs (abonnés / abonnements), avec tap vers le profil public.
class UserListView extends ConsumerWidget {
  final AsyncValue<List<User>> usersAsync;
  final String emptyMessage;

  const UserListView({
    super.key,
    required this.usersAsync,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(user.username.substring(0, 1).toUpperCase())
                    : null,
              ),
              title: Text(user.username),
              subtitle: Text(user.country.name),
              onTap: () => context.push('/profile/${user.uid}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(AppLocalizations.of(context)!.errorGenericMsg(error.toString())),
      ),
    );
  }
}
