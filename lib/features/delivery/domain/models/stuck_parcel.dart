import 'package:equatable/equatable.dart';

/// Pourquoi un colis attend une décision humaine.
///
/// Trois silences différents, trois causes différentes. Les confondre ferait
/// traiter « le vendeur n'a rien déposé » comme « notre tournée a pris du
/// retard » : la première situation rembourse, la seconde s'explique.
enum StuckReason {
  /// Le délai de dépôt est passé et aucun scan n'a eu lieu. L'acheteur doit
  /// être remboursé — le vendeur avait le temps et les rappels.
  neverDroppedOff,

  /// Le colis est chez nous depuis trop longtemps sans arriver. C'est notre
  /// retard, pas celui du vendeur.
  inTransitTooLong,

  /// Le colis attend en point relais et personne ne vient le chercher.
  waitingAtRelay;

  static StuckReason fromWire(String? value) => switch (value) {
    'never_dropped_off' => StuckReason.neverDroppedOff,
    'waiting_at_relay' => StuckReason.waitingAtRelay,
    _ => StuckReason.inTransitTooLong,
  };
}

class StuckParcel extends Equatable {
  const StuckParcel({
    required this.code,
    required this.transactionRef,
    required this.productTitle,
    required this.status,
    required this.method,
    required this.reason,
    this.buyerScannedAt,
    this.createdAt,
  });

  final String code;
  final String transactionRef;
  final String productTitle;
  final String status;
  final String method;
  final StuckReason reason;

  /// L'acheteur a scanné l'étiquette : il a donc eu le colis en main, même
  /// s'il n'a rien confirmé ensuite. C'est l'information qui tranche la
  /// plupart des dossiers.
  final DateTime? buyerScannedAt;
  final DateTime? createdAt;

  factory StuckParcel.fromJson(Map<String, dynamic> json) => StuckParcel(
    code: json['code'] as String? ?? '',
    transactionRef: json['transactionRef'] as String? ?? '',
    productTitle: json['productTitle'] as String? ?? 'Article',
    status: json['status'] as String? ?? '',
    method: json['method'] as String? ?? 'relay',
    reason: StuckReason.fromWire(json['reason'] as String?),
    buyerScannedAt: DateTime.tryParse(json['buyerScannedAt'] as String? ?? ''),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );

  @override
  List<Object?> get props => [code, status, reason];
}
