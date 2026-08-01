import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

import '../../data/follow_repository.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/entities/user.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository();
});

/// Indique si l'utilisateur courant suit [targetUserId].
final isFollowingProvider = FutureProvider.family<bool, String>((
  ref,
  targetUserId,
) async {
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUid == null || currentUid == targetUserId) return false;

  final repository = ref.watch(followRepositoryProvider);
  return repository.isFollowing(targetUserId);
});

/// UIDs des abonnés de [userId].
final followerIdsProvider = FutureProvider.family<List<String>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getFollowerIds(userId);
});

/// UIDs des utilisateurs suivis par [userId].
final followingIdsProvider = FutureProvider.family<List<String>, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(followRepositoryProvider);
  return repository.getFollowingIds(userId);
});

/// Profils complets des abonnés de [userId], pour l'affichage en liste.
final followersProvider = FutureProvider.family<List<User>, String>((
  ref,
  userId,
) async {
  final ids = await ref.watch(followerIdsProvider(userId).future);
  final authRepository = ref.watch(authRepositoryProvider);
  final users = await Future.wait(
    ids.map((id) async {
      try {
        return await authRepository.getUserById(id);
      } catch (_) {
        return null;
      }
    }),
  );
  return users.whereType<User>().toList();
});

/// Profils complets des utilisateurs suivis par [userId], pour l'affichage en liste.
final followingProvider = FutureProvider.family<List<User>, String>((
  ref,
  userId,
) async {
  final ids = await ref.watch(followingIdsProvider(userId).future);
  final authRepository = ref.watch(authRepositoryProvider);
  final users = await Future.wait(
    ids.map((id) async {
      try {
        return await authRepository.getUserById(id);
      } catch (_) {
        return null;
      }
    }),
  );
  return users.whereType<User>().toList();
});

extension FollowHelpers on WidgetRef {
  Future<void> toggleFollow(String targetUserId) async {
    final repository = read(followRepositoryProvider);
    await repository.toggleFollow(targetUserId);
    invalidate(isFollowingProvider(targetUserId));
  }
}
