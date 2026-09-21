/// Les boosts sont-ils proposés sur cette plateforme ?
///
/// Un boost est un **service numérique consommé dans l'application**. Google
/// Play et l'App Store imposent leur propre système de facturation pour ce
/// type d'achat — pas un prestataire tiers comme GeniusPay. Les articles du
/// marketplace, eux, sont des biens **physiques** : ils restent exemptés, et
/// leur paiement ne change pas.
///
/// La **fonctionnalité** boost est disponible partout. Dépenser un crédit déjà
/// possédé (`applyBoost`) n'est pas un achat : aucune règle de magasin ne s'y
/// oppose. On montre donc le solde et « utiliser un crédit » sur toutes les
/// plateformes — ce qui rend les boosts pleinement utiles sur mobile.
bool get boostsDisponibles => true;

/// Peut-on **acheter** des boosts directement dans l'application ?
///
/// Un boost est une **mise en avant d'annonce** — un service de promotion vendu
/// à un vendeur pour vendre un bien physique, comme le « Bump » de Vinted ou les
/// « promoted listings » d'eBay/Etsy, historiquement facturés par le paiement
/// maison sans Play Billing. On l'active donc partout, payé via GeniusPay (qui
/// prend T-Money/Flooz).
///
/// Zone grise assumée : Google *pourrait* le classer en contenu numérique et
/// exiger Play Billing. Le pire cas est un refus de version, réversible en
/// repassant ce getter à la variante plateforme :
///   kIsWeb || (plateforme != android && plateforme != iOS)
bool get boostsAchatDisponible => true;

/// Configuration du boost de produit, côté affichage client.
///
/// Le prix réel facturé est toujours imposé par la Cloud Function
/// `finalizeBoost` / `finalizeBoostPack` (functions/index.js, `BOOST_CONFIG`) —
/// ces constantes ne servent qu'à l'affichage avant paiement et doivent rester
/// synchronisées avec les valeurs serveur.
const int kBoostPriceXOF = 500;
const int kBoostDurationHours = 48;

/// Prix d'un boost acheté d'avance (« en réserve »). Même prix unitaire que le
/// boost occasionnel : ce qu'on achète, c'est la souplesse de l'utiliser plus
/// tard, sur l'annonce de son choix.
const int kBoostCreditPriceXOF = 500;

/// Bornes du sélecteur de quantité à l'achat d'un lot. Le maximum doit rester
/// aligné avec `BOOST_CONFIG.MAX_CREDITS_PER_PURCHASE` côté serveur.
const int kBoostMaxCreditsPerPurchase = 50;
