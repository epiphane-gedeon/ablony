import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/block_repository.dart';

/// Les personnes que j'ai bloquées, en flux : débloquer depuis la liste doit
/// rouvrir la conversation sans qu'on ait à quitter l'écran.
final blockedUsersProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(blockRepositoryProvider).watchBlocked();
});

/// Ai-je bloqué cette personne ?
///
/// Dérivé du flux plutôt que lu à part : une lecture séparée resterait vraie
/// une seconde de trop après un déblocage.
final isBlockedProvider = Provider.family<bool, String>((ref, uid) {
  return ref.watch(blockedUsersProvider).value?.contains(uid) ?? false;
});
