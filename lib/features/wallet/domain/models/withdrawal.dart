import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Où en est une demande de retrait.
enum WithdrawalStatus {
  /// Enregistrée. La somme a déjà quitté le solde disponible — sans quoi deux
  /// demandes lancées coup sur coup retireraient le même argent.
  requested,

  /// Versée. L'argent est parti vers le compte mobile money.
  paid,

  /// Refusée. La somme est revenue sur le solde, et le motif est lisible.
  rejected;

  static WithdrawalStatus fromWire(String? value) => switch (value) {
    'paid' => WithdrawalStatus.paid,
    'rejected' => WithdrawalStatus.rejected,
    _ => WithdrawalStatus.requested,
  };

  bool get isSettled => this != WithdrawalStatus.requested;
}

/// Par où l'argent part.
enum WithdrawalMethod {
  tmoney('T-Money'),
  flooz('Flooz'),
  bank('Virement bancaire');

  const WithdrawalMethod(this.label);
  final String label;

  static WithdrawalMethod fromWire(String? value) => switch (value) {
    'flooz' => WithdrawalMethod.flooz,
    'bank' => WithdrawalMethod.bank,
    _ => WithdrawalMethod.tmoney,
  };

  String get wireValue => name;
}

/// Une demande de retrait.
///
/// Le versement se fait à la main : quelques virements par semaine prennent
/// quelques minutes. Ce que l'application apporte, c'est la retenue de la
/// somme dès la demande, la trace, et le retour de l'argent en cas de refus.
class Withdrawal extends Equatable {
  const Withdrawal({
    required this.id,
    required this.amountXof,
    required this.feeXof,
    required this.netAmountXof,
    required this.method,
    required this.destinationMasked,
    required this.status,
    required this.createdAt,
    this.reason,
    this.settledAt,
  });

  final String id;

  /// Ce qui a quitté le solde disponible.
  final int amountXof;

  /// Les frais de transfert, retenus sur le montant demandé.
  final int feeXof;

  /// Ce que le vendeur reçoit réellement. C'est le chiffre qui compte pour
  /// lui — les deux autres l'expliquent.
  final int netAmountXof;

  final WithdrawalMethod method;
  final String destinationMasked;
  final WithdrawalStatus status;
  final DateTime createdAt;

  /// Le motif, en cas de refus.
  final String? reason;
  final DateTime? settledAt;

  factory Withdrawal.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final montant = (data['amountXof'] as num?)?.round() ?? 0;
    return Withdrawal(
      id: data['id'] as String? ?? doc.id,
      amountXof: montant,
      feeXof: (data['feeXof'] as num?)?.round() ?? 0,
      // Les demandes antérieures aux frais n'ont pas le champ : le net vaut
      // alors le brut.
      netAmountXof: (data['netAmountXof'] as num?)?.round() ?? montant,
      method: WithdrawalMethod.fromWire(data['method'] as String?),
      destinationMasked: data['destinationMasked'] as String? ?? '',
      status: WithdrawalStatus.fromWire(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'] as String?,
      settledAt: (data['settledAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [id, status, amountXof, settledAt];
}

/// Les frais d'un retrait, calculés comme le serveur les calcule.
///
/// Recopiés ici pour **montrer** le montant avant confirmation : demander
/// 15 000 et en recevoir 14 800 sans l'avoir su à l'avance est la meilleure
/// façon de recevoir un message au support. Le serveur reste seul à décider —
/// ce calcul n'est qu'un affichage.
///
/// Doit rester identique à `withdrawalFee` dans `functions/index.js`.
abstract final class WithdrawalFees {
  static const int minimumXof = 2000;
  static const int fixedXof = 100;
  static const double rate = 0.01;
  static const int capXof = 2100;

  static int of(int amountXof) {
    final brut = fixedXof + (amountXof * rate).ceil();
    return brut < capXof ? brut : capXof;
  }

  static int netOf(int amountXof) => amountXof - of(amountXof);
}
