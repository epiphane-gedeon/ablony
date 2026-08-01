import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Reçu d'achat, généré côté serveur (Cloud Functions) à la finalisation
/// d'un paiement. Stockage : collection `receipts`, id = référence de la
/// transaction (`transactionRef`).
class Receipt extends Equatable {
  final String id;
  final String transactionRef;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productTitle;
  final double productPrice;
  final double totalAmount;
  final String paymentMethod;
  final bool deliveryConfirmed;

  /// Id du document `qrcodes` associé à cet achat — c'est cette valeur (et
  /// non [transactionRef]) qui est encodée dans le QR de remise en main
  /// propre affiché au vendeur. Peut être `null` pour un reçu antérieur à
  /// cette fonctionnalité.
  final String? qrCodeId;

  final DateTime createdAt;

  const Receipt({
    required this.id,
    required this.transactionRef,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    required this.totalAmount,
    required this.paymentMethod,
    required this.deliveryConfirmed,
    this.qrCodeId,
    required this.createdAt,
  });

  factory Receipt.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Receipt(
      id: doc.id,
      transactionRef: data['transactionRef'] as String? ?? doc.id,
      buyerId: data['buyerId'] as String,
      sellerId: data['sellerId'] as String,
      productId: data['productId'] as String,
      productTitle: data['productTitle'] as String? ?? 'Produit',
      productPrice: (data['productPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] as String? ?? '',
      deliveryConfirmed: data['deliveryConfirmed'] as bool? ?? false,
      qrCodeId: data['qrCodeId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id];
}
