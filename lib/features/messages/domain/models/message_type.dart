enum MessageType {
  system,
  offer,
  counterOffer,
  text,
  image;

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
      case MessageType.image:
        return 'image';
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
      case 'image':
        return MessageType.image;
      default:
        return MessageType.text;
    }
  }
}
