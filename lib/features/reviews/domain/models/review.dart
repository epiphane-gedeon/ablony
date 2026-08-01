import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Avis laissé par un acheteur sur un vendeur, suite à un achat.
///
/// Stockage : collection `reviews`, id = référence de la transaction
/// (garantit un seul avis par achat). Écrit par le client (acheteur),
/// mais l'agrégat `users/{sellerId}.rating`/`.reviewsCount` est recalculé
/// côté serveur par le trigger Cloud Function `onReviewCreated`.
class Review extends Equatable {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productTitle;
  final int rating;
  final String? comment;
  final String transactionRef;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
    required this.rating,
    this.comment,
    required this.transactionRef,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Review(
      id: doc.id,
      buyerId: data['buyerId'] as String,
      sellerId: data['sellerId'] as String,
      productId: data['productId'] as String,
      productTitle: data['productTitle'] as String? ?? 'Produit',
      rating: (data['rating'] as num).toInt(),
      comment: data['comment'] as String?,
      transactionRef: data['transactionRef'] as String? ?? doc.id,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id];
}
