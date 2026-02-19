import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant le porte-monnaie d'un utilisateur
class Wallet {
  /// Prénom(s) du titulaire du compte
  final String firstName;

  /// Nom de famille du titulaire du compte
  final String lastName;

  /// Nationalité du titulaire
  final String nationality;

  /// Date de naissance du titulaire
  final DateTime birthDate;

  /// Montant disponible en FCFA
  final int availableAmount;

  /// Montant en attente en FCFA
  final int pendingAmount;

  /// Indique si le porte-monnaie est activé
  final bool isActivated;

  /// Date d'activation du porte-monnaie
  final DateTime? activatedAt;

  const Wallet({
    required this.firstName,
    required this.lastName,
    required this.nationality,
    required this.birthDate,
    this.availableAmount = 0,
    this.pendingAmount = 0,
    required this.isActivated,
    this.activatedAt,
  });

  /// Crée un Wallet à partir des données Firestore
  factory Wallet.fromFirestore(Map<String, dynamic> data) {
    return Wallet(
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      nationality: data['nationality'] as String,
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      availableAmount: data['availableAmount'] as int? ?? 0,
      pendingAmount: data['pendingAmount'] as int? ?? 0,
      isActivated: data['isActivated'] as bool? ?? false,
      activatedAt: data['activatedAt'] != null
          ? (data['activatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convertit le Wallet en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'nationality': nationality,
      'birthDate': Timestamp.fromDate(birthDate),
      'availableAmount': availableAmount,
      'pendingAmount': pendingAmount,
      'isActivated': isActivated,
      'activatedAt': activatedAt != null
          ? Timestamp.fromDate(activatedAt!)
          : null,
    };
  }

  /// Montant disponible en FCFA (conversion en double pour l'affichage)
  double get availableAmountInXOF => availableAmount.toDouble();

  /// Montant en attente en FCFA (conversion en double pour l'affichage)
  double get pendingAmountInXOF => pendingAmount.toDouble();

  /// Copie le wallet avec des modifications
  Wallet copyWith({
    String? firstName,
    String? lastName,
    String? nationality,
    DateTime? birthDate,
    int? availableAmount,
    int? pendingAmount,
    bool? isActivated,
    DateTime? activatedAt,
  }) {
    return Wallet(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationality: nationality ?? this.nationality,
      birthDate: birthDate ?? this.birthDate,
      availableAmount: availableAmount ?? this.availableAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      isActivated: isActivated ?? this.isActivated,
      activatedAt: activatedAt ?? this.activatedAt,
    );
  }
}
