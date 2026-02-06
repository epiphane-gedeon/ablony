enum OfferStatus {
  pending,
  accepted,
  rejected;

  String toFirestore() {
    switch (this) {
      case OfferStatus.pending:
        return 'pending';
      case OfferStatus.accepted:
        return 'accepted';
      case OfferStatus.rejected:
        return 'rejected';
    }
  }

  static OfferStatus fromFirestore(String value) {
    switch (value) {
      case 'pending':
        return OfferStatus.pending;
      case 'accepted':
        return OfferStatus.accepted;
      case 'rejected':
        return OfferStatus.rejected;
      default:
        return OfferStatus.pending;
    }
  }
}
