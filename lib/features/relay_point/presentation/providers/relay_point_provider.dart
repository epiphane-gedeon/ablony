import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/relay_point_repository.dart';
import '../../domain/models/relay_point.dart';

final relayPointRepositoryProvider = Provider<RelayPointRepository>((ref) {
  return RelayPointRepository();
});

final relayPointsProvider = StreamProvider<List<RelayPoint>>((ref) {
  final repository = ref.watch(relayPointRepositoryProvider);
  return repository.watchRelayPoints();
});

/// Les points relais réellement proposables (actifs). C'est cette liste qui
/// décide, à l'écran de paiement, s'il faut un sélecteur (≥2), un choix imposé
/// (1) ou pas de retrait relais du tout (0).
final activeRelayPointsProvider = Provider<AsyncValue<List<RelayPoint>>>((ref) {
  return ref.watch(relayPointsProvider).whenData(
        (points) => points.where((p) => p.isActive).toList(),
      );
});
