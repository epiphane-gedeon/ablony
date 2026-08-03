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
