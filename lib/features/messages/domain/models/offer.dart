import 'offer_status.dart';

class Offer {
  final double amount;
  final OfferStatus status;
  final String productId;

  const Offer({
    required this.amount,
    required this.status,
    required this.productId,
  });

  factory Offer.fromFirestore(Map<String, dynamic> data) {
    return Offer(
      amount: (data['amount'] as num).toDouble(),
      status: OfferStatus.fromFirestore(data['status'] as String),
      productId: data['productId'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'status': status.toFirestore(),
      'productId': productId,
    };
  }

  Offer copyWith({double? amount, OfferStatus? status, String? productId}) {
    return Offer(
      amount: amount ?? this.amount,
      status: status ?? this.status,
      productId: productId ?? this.productId,
    );
  }
}
