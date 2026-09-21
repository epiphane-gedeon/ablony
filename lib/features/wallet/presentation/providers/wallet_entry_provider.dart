import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../data/wallet_entry_repository.dart';
import '../../domain/models/wallet_entry.dart';

final walletEntryRepositoryProvider = Provider<WalletEntryRepository>((ref) {
  return WalletEntryRepository();
});

/// Le relevé de la personne connectée, tenu à jour.
///
/// [StreamProvider] et non [FutureProvider] : un achat finalisé pendant que
/// l'écran est ouvert doit apparaître, sinon le solde change sans que la
/// ligne qui l'explique n'arrive.
final walletEntriesProvider = StreamProvider<List<WalletEntry>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(walletEntryRepositoryProvider).watchEntries(user.uid);
});
