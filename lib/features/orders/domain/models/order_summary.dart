import 'package:cloud_firestore/cloud_firestore.dart';

/// De quel côté de la vente on se tient.
enum OrderSide { purchase, sale }

/// L'action qu'on attend de moi sur cette commande.
///
/// C'est ce qui fait la valeur de l'écran : une liste d'historique est une
/// archive ; une liste qui dit « déposez ce colis avant vendredi » est un
/// outil de travail. La distinction doit se voir, pas seulement se lire.
enum OrderAction {
  /// Vendeur : le colis n'est pas parti, et le délai court.
  dropOff,

  /// Acheteur : le colis est remis, il reste à le confirmer.
  confirmReception,

  /// Acheteur : le colis attend au point relais.
  pickUp,

  /// Les deux : suivre l'acheminement. Informatif, pas urgent.
  track,

  /// Rien à faire.
  none,
}

/// Une ligne de la liste des commandes.
///
/// Assemblée à partir du reçu et du colis : le reçu porte l'argent, le colis
/// porte l'acheminement, et c'est leur croisement qui dit quoi faire.
class OrderSummary {
  const OrderSummary({
    required this.transactionRef,
    required this.side,
    required this.productId,
    required this.productTitle,
    required this.amountXof,
    required this.createdAt,
    this.productImage,
    this.parcelCode,
    this.parcelStatus,
    this.dropoffDeadline,
    this.deliveryConfirmed = false,
    this.refundedAt,
    this.refundReason,
  });

  final String transactionRef;
  final OrderSide side;
  final String productId;
  final String productTitle;
  final int amountXof;
  final DateTime createdAt;
  final String? productImage;
  final String? parcelCode;
  final String? parcelStatus;
  final DateTime? dropoffDeadline;
  final bool deliveryConfirmed;
  final DateTime? refundedAt;
  final String? refundReason;

  bool get estRembourse => refundedAt != null;

  bool get estTermine => deliveryConfirmed || estRembourse;

  /// Ce qu'on attend de moi, déduit de l'état réel.
  ///
  /// Une seule source : l'état du colis croisé avec celui du règlement. Un
  /// champ stocké en base se désynchroniserait au premier scan manqué.
  OrderAction get action {
    if (estTermine) return OrderAction.none;

    switch (parcelStatus) {
      case 'awaiting_dropoff':
        return side == OrderSide.sale ? OrderAction.dropOff : OrderAction.none;
      case 'ready_for_pickup':
        return side == OrderSide.purchase ? OrderAction.pickUp : OrderAction.none;
      case 'delivered':
        return side == OrderSide.purchase
            ? OrderAction.confirmReception
            : OrderAction.none;
      case 'dropped_off':
      case 'in_transit':
      case 'out_for_delivery':
        return OrderAction.track;
      default:
        return OrderAction.none;
    }
  }

  /// Vrai quand la ligne appelle un geste — et non quand elle informe.
  bool get appelleUnGeste =>
      action == OrderAction.dropOff || action == OrderAction.confirmReception;

  static OrderSummary fromReceipt(
    DocumentSnapshot<Map<String, dynamic>> doc,
    OrderSide side, {
    Map<String, dynamic>? parcel,
  }) {
    final d = doc.data() ?? const {};
    return OrderSummary(
      transactionRef: d['transactionRef'] as String? ?? doc.id,
      side: side,
      productId: d['productId'] as String? ?? '',
      productTitle: d['productTitle'] as String? ?? 'Article',
      // Le vendeur voit ce qu'il encaisse — le prix de l'article. L'acheteur
      // voit ce qu'il a payé — frais compris. Afficher le même chiffre aux
      // deux ferait croire à l'un qu'on lui prend une commission.
      amountXof: side == OrderSide.sale
          ? ((d['productPrice'] as num?)?.round() ?? 0)
          : ((d['totalAmount'] as num?)?.round() ?? 0),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productImage: d['productImage'] as String?,
      parcelCode: d['parcelCode'] as String?,
      parcelStatus: parcel?['status'] as String?,
      dropoffDeadline: (parcel?['dropoffDeadline'] as Timestamp?)?.toDate(),
      deliveryConfirmed: d['deliveryConfirmed'] as bool? ?? false,
      refundedAt: (d['refundedAt'] as Timestamp?)?.toDate(),
      refundReason: d['refundReason'] as String?,
    );
  }
}
