import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Ce qui a fait bouger un solde.
///
/// Un solde est un nombre ; il ne dit pas d'où il vient. Le jour où quelqu'un
/// écrit « il me manque 5 000 F », c'est cette liste qui répond — et sans
/// elle, personne ne peut répondre, vous compris.
///
/// Les mouvements viennent de deux endroits, parce que l'argent y est écrit
/// depuis deux points de vue : `transactions` enregistre ce que la personne a
/// **payé** (achat, mise en avant, rechargement), `receipts` ce qu'elle a
/// **vendu**. Aucune des deux collections ne se suffit à elle-même.
enum WalletEntryKind {
  /// Rechargement du porte-monnaie : l'argent entre.
  topUp,

  /// Achat d'un article : l'argent sort.
  purchase,

  /// Mise en avant d'une annonce : l'argent sort.
  boost,

  /// Un achat annulé : l'argent revient, définitivement disponible. Il
  /// apparaît **en plus** de l'achat, qui reste au relevé — celui-ci doit
  /// montrer ce qui s'est passé, pas faire comme si rien n'avait eu lieu.
  refund,

  /// Un retrait vers un compte mobile money. La somme quitte le solde dès la
  /// demande, et non au versement : sans cela, deux demandes lancées coup sur
  /// coup retireraient le même argent.
  withdrawal,

  /// Un retrait refusé : la somme revient au solde.
  withdrawalRefund,

  /// Vente dont l'article n'est pas encore remis. L'argent est acquis mais
  /// pas encore disponible — c'est le séquestre qui protège l'acheteur.
  salePending,

  /// Vente dont la réception a été confirmée : l'argent est disponible.
  saleReleased;

  /// Un mouvement qui augmente le solde, au sens large — le séquestre compris.
  bool get isCredit =>
      this == topUp ||
      this == refund ||
      this == withdrawalRefund ||
      this == salePending ||
      this == saleReleased;
}

class WalletEntry extends Equatable {
  const WalletEntry({
    required this.reference,
    required this.kind,
    required this.amountXof,
    required this.createdAt,
    this.label,
    this.productId,
    this.paymentMethod,
    this.parcelCode,
    this.netAmountXof,
    this.isPending = false,
  });

  /// La référence de la transaction. C'est elle qu'on cite au support.
  final String reference;
  final WalletEntryKind kind;

  /// Toujours positif : c'est [kind] qui donne le sens, pas le signe. Un
  /// montant négatif affiché tel quel se lit mal en liste.
  final int amountXof;
  final DateTime createdAt;

  /// Le titre de l'article, quand le mouvement en concerne un.
  final String? label;
  final String? productId;
  final String? paymentMethod;
  final String? parcelCode;

  /// Pour un retrait, ce qui arrive réellement sur le compte — frais déduits.
  final int? netAmountXof;

  /// Le mouvement a eu lieu, mais l'opération n'est pas dénouée : un retrait
  /// demandé et pas encore versé.
  final bool isPending;

  /// Un mouvement payé, lu depuis `transactions`.
  ///
  /// Seul celui qui a payé peut lire ces documents : ils portent son choix de
  /// livraison, adresse comprise.
  static WalletEntry? fromTransaction(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return null;

    // Deux cas où un mouvement « pending » doit quand même se voir.
    //
    // Le retrait : la somme quitte le solde **dès la demande**, donc le
    // mouvement est réel avant d'être « completed ». Le masquer ferait
    // chercher un débit qu'on voit pourtant sur son solde.
    //
    // Le paiement externe : l'argent a quitté le compte mobile money de la
    // personne, mais la confirmation de l'opérateur peut tarder. Le masquer
    // pendant ce temps est ce qui fait le plus de dégâts — on a payé, et
    // l'application n'en garde aucune trace visible. Mieux vaut l'afficher
    // comme en attente : la somme est suivie, elle n'est pas perdue.
    final paiementExterne = data['paymentMethod'] != null &&
        data['paymentMethod'] != 'wallet' &&
        data['paymentMethod'] != 'credit';
    final enCours = data['status'] == 'pending' &&
        (data['type'] == 'withdrawal' || paiementExterne);

    // Pour le reste, une opération engagée mais jamais aboutie n'a fait bouger
    // aucun solde : l'afficher ferait chercher un débit inexistant.
    if (data['status'] != 'completed' && !enCours) return null;

    final kind = switch (data['type'] as String?) {
      'recharge' => WalletEntryKind.topUp,
      'purchase' => WalletEntryKind.purchase,
      'boost' => WalletEntryKind.boost,
      // Achat de boosts d'avance : un vrai débit du portefeuille, à montrer.
      // (Le boost dépensé depuis la réserve, `boost_credit`, ne bouge aucun
      // solde — montant nul — et reste donc absent du relevé.)
      'boostpack' => WalletEntryKind.boost,
      'refund' => WalletEntryKind.refund,
      'withdrawal' => WalletEntryKind.withdrawal,
      'withdrawal_refund' => WalletEntryKind.withdrawalRefund,
      _ => null,
    };
    if (kind == null) return null;

    return WalletEntry(
      reference: data['reference'] as String? ?? doc.id,
      kind: kind,
      amountXof: (data['amount'] as num?)?.round() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productId: data['productId'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      label: data['reason'] as String?,
      // Ce que la personne reçoit vraiment, quand des frais s'appliquent.
      netAmountXof: (data['netAmountXof'] as num?)?.round(),
      isPending: enCours,
    );
  }

  /// Une vente, lue depuis `receipts`.
  ///
  /// Le reçu ne porte ni adresse ni choix de livraison : le vendeur le lit
  /// aussi, et il n'a pas à savoir où habite son acheteur.
  static WalletEntry? fromReceipt(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;

    final confirmed = data['deliveryConfirmed'] as bool? ?? false;
    return WalletEntry(
      reference: data['transactionRef'] as String? ?? doc.id,
      kind: confirmed
          ? WalletEntryKind.saleReleased
          : WalletEntryKind.salePending,
      // Le prix de l'article, et non le total payé : les frais de livraison
      // ne reviennent pas au vendeur.
      amountXof: (data['productPrice'] as num?)?.round() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      label: data['productTitle'] as String?,
      productId: data['productId'] as String?,
      parcelCode: data['parcelCode'] as String?,
    );
  }

  IconData get icon => switch (kind) {
    WalletEntryKind.topUp => Icons.add_circle_outline,
    WalletEntryKind.purchase => Icons.shopping_bag_outlined,
    WalletEntryKind.boost => Icons.trending_up,
    WalletEntryKind.refund => Icons.undo_outlined,
    WalletEntryKind.withdrawal => Icons.arrow_outward,
    WalletEntryKind.withdrawalRefund => Icons.undo_outlined,
    WalletEntryKind.salePending => Icons.hourglass_bottom_outlined,
    WalletEntryKind.saleReleased => Icons.check_circle_outline,
  };

  @override
  List<Object?> get props => [reference, kind, amountXof, createdAt];
}
