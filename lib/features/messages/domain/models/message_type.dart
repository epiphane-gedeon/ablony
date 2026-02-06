enum MessageType {
  system,
  offer,
  counterOffer,
  text;

  String toFirestore() {
    switch (this) {
      case MessageType.system:
        return 'system';
      case MessageType.offer:
        return 'offer';
      case MessageType.counterOffer:
        return 'counter_offer';
      case MessageType.text:
        return 'text';
    }
  }

  static MessageType fromFirestore(String value) {
    switch (value) {
      case 'system':
        return MessageType.system;
      case 'offer':
        return MessageType.offer;
      case 'counter_offer':
        return MessageType.counterOffer;
      case 'text':
        return MessageType.text;
      default:
        return MessageType.text;
    }
  }
}
