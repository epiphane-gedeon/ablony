import 'package:cloud_firestore/cloud_firestore.dart';

/// Ce que l'acheteur — ou le vendeur — reproche à la vente.
///
/// Acheteur et vendeur ne rencontrent pas les mêmes problèmes : l'acheteur
/// conteste le colis (jamais reçu, non conforme, abîmé) ; le vendeur, lui,
/// conteste le comportement de l'acheteur (ne confirme pas, réclame sans
/// motif). D'où deux jeux de motifs, choisis selon le rôle de celui qui ouvre.
enum DisputeReason {
  // Motifs acheteur.
  notReceived('not_received'),
  notAsDescribed('not_as_described'),
  damaged('damaged'),
  // Motifs vendeur.
  buyerNotConfirming('buyer_not_confirming'),
  buyerNoValidReason('buyer_no_valid_reason'),
  // Commun aux deux.
  other('other');

  const DisputeReason(this.wireValue);

  /// La valeur envoyée au serveur, et stockée telle quelle.
  final String wireValue;

  static DisputeReason fromWire(String? valeur) {
    for (final r in DisputeReason.values) {
      if (r.wireValue == valeur) return r;
    }
    return DisputeReason.other;
  }

  /// Les motifs proposés à l'acheteur.
  static const List<DisputeReason> buyerReasons = [
    notReceived,
    notAsDescribed,
    damaged,
    other,
  ];

  /// Les motifs proposés au vendeur.
  static const List<DisputeReason> sellerReasons = [
    buyerNotConfirming,
    buyerNoValidReason,
    other,
  ];
}

/// Où en est le dossier.
///
/// Deux issues, et l'argent va entièrement à l'un ou à l'autre : Ablony ne
/// garde jamais la somme d'une vente contestée.
enum DisputeStatus {
  open('open'),
  refunded('refunded'),
  released('released');

  const DisputeStatus(this.wireValue);

  final String wireValue;

  static DisputeStatus fromWire(String? valeur) {
    for (final s in DisputeStatus.values) {
      if (s.wireValue == valeur) return s;
    }
    return DisputeStatus.open;
  }

  bool get estOuvert => this == DisputeStatus.open;
}

/// Un litige sur une vente.
///
/// L'identifiant du document **est** la référence de transaction : une vente,
/// un litige. C'est Firestore qui garantit l'unicité, pas une vérification
/// applicative qu'on peut oublier d'écrire.
class Dispute {
  const Dispute({
    required this.transactionRef,
    required this.buyerId,
    required this.sellerId,
    required this.openedBy,
    required this.reason,
    required this.description,
    required this.photoUrls,
    required this.status,
    required this.createdAt,
    this.productTitle,
    this.amountXof = 0,
    this.resolutionNote,
    this.resolvedAt,
  });

  final String transactionRef;
  final String buyerId;
  final String sellerId;
  final String openedBy;
  final DisputeReason reason;
  final String description;
  final List<String> photoUrls;
  final DisputeStatus status;
  final DateTime createdAt;
  final String? productTitle;
  final int amountXof;
  final String? resolutionNote;
  final DateTime? resolvedAt;

  bool ouvertPar(String uid) => openedBy == uid;

  static Dispute fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Dispute(
      transactionRef: d['transactionRef'] as String? ?? doc.id,
      buyerId: d['buyerId'] as String? ?? '',
      sellerId: d['sellerId'] as String? ?? '',
      openedBy: d['openedBy'] as String? ?? '',
      reason: DisputeReason.fromWire(d['reason'] as String?),
      description: d['description'] as String? ?? '',
      photoUrls: List<String>.from(d['photoUrls'] as List<dynamic>? ?? []),
      status: DisputeStatus.fromWire(d['status'] as String?),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productTitle: d['productTitle'] as String?,
      amountXof: (d['amountXof'] as num?)?.round() ?? 0,
      resolutionNote: d['resolutionNote'] as String?,
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
