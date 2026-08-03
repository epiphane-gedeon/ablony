import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/relay_point.dart';

class RelayPointRepository {
  RelayPointRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RelayPoint>> watchRelayPoints() {
    return _firestore
        .collection('relayPoints')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(RelayPoint.fromFirestore).toList());
  }
}
