/// Motif de signalement d'un article par un utilisateur.
enum ReportReason {
  counterfeit,
  inappropriate,
  scam,
  other;

  /// Valeur stockée en base (stable même si les libellés affichés changent).
  String get value => name;
}
