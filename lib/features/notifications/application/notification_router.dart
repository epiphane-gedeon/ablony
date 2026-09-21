import '../domain/models/app_notification.dart';

/// Où mène une notification.
///
/// **Une seule table**, ici, pour la boîte de réception comme pour l'appui sur
/// une notification système. Deux routages parallèles finissent par diverger,
/// et le jour où ils divergent, un push mène ailleurs que la ligne qui lui
/// correspond — sans que rien ne le signale.
///
/// C'est le fichier qu'on rouvre à chaque nouveau type. Il est donc court, et
/// il le reste.
///
/// Renvoie `null` quand il n'y a nulle part où aller : un type inconnu, écrit
/// par une version plus récente du serveur, ne doit rien casser.
String? destinationOf(String type, Map<String, dynamic> data) {
  String? s(String cle) {
    final v = data[cle];
    return v is String && v.isNotEmpty ? v : null;
  }

  final ref = s('transactionRef');
  final colis = s('parcelCode');

  switch (type) {
    // Le vendeur a **une** chose à faire : imprimer son étiquette. On l'y
    // mène directement plutôt que sur le reçu, qui la contient mais la noie.
    case 'purchase_received':
      return colis != null ? '/delivery/label/$colis' : _recu(ref);

    case 'purchase_confirmed':
    case 'parcel_on_its_way':
    case 'parcel_ready_for_pickup':
    case 'parcel_delivered':
    case 'dispute_opened':
    case 'dispute_resolved':
      return _recu(ref);

    // L'argent a bougé : le relevé est le seul écran qui le montre.
    case 'refund_issued':
    case 'sale_refunded':
    case 'funds_released':
    case 'withdrawal_paid':
    case 'withdrawal_rejected':
      return '/profile/wallet/statement';

    case 'new_message':
      final conversation = s('conversationId');
      return conversation != null ? '/chat/$conversation' : null;

    case 'new_product_from_followed':
      final produit = s('productId');
      return produit != null ? '/product/$produit' : null;

    // Une annonce à corriger mène au formulaire, pas à la fiche : ce qu'on
    // attend du vendeur, c'est une retouche.
    case 'product_rejected':
      final annonce = s('productId');
      if (annonce == null) return null;
      return data['decision'] == 'correction'
          ? '/product/$annonce?corriger=1'
          : '/product/$annonce';

    case 'new_follower':
    case 'review_received':
      final qui = s('userId') ?? s('followerId') ?? s('reviewerId');
      return qui != null ? '/profile/$qui' : null;

    case 'suspension_lifted':
    case 'account_banned':
    case 'dropoff_reminder':
      return colis != null ? '/delivery/label/$colis' : null;

    default:
      return null;
  }
}

String? _recu(String? ref) => ref != null ? '/receipt/$ref' : null;

/// Raccourci pour une notification de la boîte.
String? destinationOfNotification(AppNotification notification) =>
    destinationOf(notification.rawType, notification.data);
