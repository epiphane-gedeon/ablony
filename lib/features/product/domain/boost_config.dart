/// Configuration du boost de produit, côté affichage client.
///
/// Le prix réel facturé est toujours imposé par la Cloud Function
/// `finalizeBoost` (functions/index.js, `BOOST_CONFIG`) — ces constantes
/// ne servent qu'à l'affichage avant paiement et doivent rester synchronisées
/// avec la valeur serveur.
const int kBoostPriceXOF = 500;
const int kBoostDurationHours = 48;
