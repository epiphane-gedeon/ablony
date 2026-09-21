/// Ce qu'une personne est autorisée à faire chez Ablony.
///
/// Le rôle vit dans `users/{uid}.role` et **son titulaire ne peut pas le
/// modifier** : les règles Firestore le figent. Sans cette barrière, n'importe
/// qui se déclarerait agent, marquerait ses propres ventes comme remises et se
/// ferait payer sans avoir rien envoyé — ce qui viderait le séquestre de son
/// sens.
///
/// Côté application, le rôle ne fait qu'afficher ou masquer des écrans. Les
/// Cloud Functions le relisent en base avant d'agir : un client trafiqué ne
/// gagne rien à mentir ici.
enum UserRole {
  /// Le cas de tout le monde : on achète, on vend.
  member,

  /// Le personnel qui achemine les colis.
  ///
  /// Un agent scanne les étiquettes et enregistre les étapes. C'est son
  /// constat — et lui seul — qui fait d'Ablony un tiers de confiance : ni
  /// l'acheteur ni le vendeur ne peuvent le produire, et aucun des deux n'a
  /// donc à croire l'autre sur parole.
  agent,

  /// L'administration : tout ce que fait un agent, plus l'arbitrage des
  /// situations bloquées.
  admin;

  static UserRole fromWire(String? value) => switch (value) {
    'agent' => UserRole.agent,
    'admin' => UserRole.admin,
    // Tout le reste retombe sur `member`, y compris un rôle inconnu : une
    // valeur inattendue ne doit jamais ouvrir de portes.
    _ => UserRole.member,
  };

  String get wireValue => name;
}
