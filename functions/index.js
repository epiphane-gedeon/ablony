const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated, onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const crypto = require("crypto");

// Initialiser Firebase Admin
admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({maxInstances: 10});

// Configuration de GeniusPay
// Ces clés seront lues depuis les variables d'environnement
const GENIUSPAY_CONFIG = {
  API_KEY: process.env.GENIUSPAY_API_KEY || "pk_sandbox_votre_cle_publique",
  API_SECRET: process.env.GENIUSPAY_API_SECRET || "sk_sandbox_votre_cle_secrete",
  WEBHOOK_SECRET: process.env.GENIUSPAY_WEBHOOK_SECRET || "whsec_votre_secret_webhook",
  BASE_URL: "https://pay.genius.ci/api/v1/merchant",
  // La passerelle, choisie selon le moyen de paiement.
  //
  // Sans choix explicite, GeniusPay ouvre sa page de sélection et y propose des
  // opérateurs absents du Togo. Mais toutes les passerelles ne coûtent pas la
  // même chose, et l'écart est considérable — GeniusPay prend 100 F + 1 %, et
  // le fournisseur ajoute sa propre commission par-dessus :
  //
  //   paiementpro   100 F + 11,0 %   ← seul à couvrir T-Money et Flooz
  //   paystack      100 F +  6,0 %   ← cartes
  //   wave          100 F +  2,5 %   ← pas encore ouvert au Togo (à surveiller)
  //
  // Mesuré sur le compte, pas lu dans une documentation. D'où ce routage : la
  // carte part chez Paystack, ce qui économise cinq points sur chaque paiement
  // par carte, et le mobile money va chez PaiementPro faute d'alternative.
  //
  // Le jour où Wave ouvre au Togo, une ligne suffit à diviser les frais par
  // quatre.
  GATEWAY_PAR_MOYEN: {
    card: "paystack",
    tmoney: "paiementpro",
    flooz: "paiementpro",
  },
  GATEWAY_DEFAUT: "paiementpro",
};

/** La passerelle la moins chère qui sache traiter ce moyen de paiement. */
function passerellePour(moyen) {
  return GENIUSPAY_CONFIG.GATEWAY_PAR_MOYEN[moyen] ||
    GENIUSPAY_CONFIG.GATEWAY_DEFAUT;
}

/// Sommes-nous en bac à sable ? Déduit des clés elles-mêmes, et non d'un
/// drapeau séparé qu'on oublierait de basculer : le jour où des clés `pk_live_`
/// sont posées dans functions/.env, tout assouplissement réservé aux tests
/// s'éteint de lui-même.
const MODE_BAC_A_SABLE =
  String(GENIUSPAY_CONFIG.API_KEY).startsWith("pk_sandbox_");

// Configuration du boost de produit (prix fixe, imposé côté serveur —
// jamais celui envoyé par le client — et durée du boost).
// Garder en phase avec BOOST_PRICE_XOF côté client (lib/features/product/...).
// ============================================================================
// LIVRAISON
// ============================================================================
//
// Ablony achemine lui-même les colis, en point relais ou à domicile. Le
// vendeur imprime le code de son colis, le colle sur le carton et le dépose
// dans un point relais : son travail s'arrête là. C'est ce qui fait d'Ablony
// un tiers de confiance — la remise est constatée par nos agents, et non
// déclarée par une des deux parties.
const DELIVERY_CONFIG = {
  // Repli ultime, si le doc `config/delivery` (défaut modifiable en admin) est
  // absent. Le vrai tarif vient de la sous-catégorie, sinon de ce défaut.
  // Doit rester égal aux valeurs codées en dur du client tant que d'anciens
  // clients (tarif figé) sont en circulation — sinon leur total ne colle plus.
  FEES_XOF: {relay: 1000, home: 1500},
  // Ramassage à domicile : le vendeur paie pour qu'on vienne chercher le colis
  // chez lui au lieu de le déposer en relais. Défaut de repli ; le vrai tarif
  // vient de la sous-catégorie, sinon du défaut modifiable en admin.
  PICKUP_FEE_XOF: 1500,
  PROTECTION_RATE: 0.05,
  // Du paiement au dépôt. Au-delà, l'acheteur doit être remboursé : il n'a
  // pas à attendre indéfiniment un colis qui n'est jamais parti.
  DROPOFF_DEADLINE_DAYS: 5,
};

// Alphabet sans O/0 ni I/1 : un agent doit pouvoir dicter ce code au
// téléphone sans que son interlocuteur se trompe en le recopiant.
const PARCEL_CODE_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";

/**
 * Génère le code imprimé sur l'étiquette du colis, de la forme
 * `AB-XXXXX-XXXXX`.
 *
 * C'est **le même code partout** : le vendeur l'imprime une fois, nos agents
 * le scannent à chaque étape, l'acheteur le retrouve dans son suivi. Il n'y a
 * pas un code par étape ni un code par rôle.
 *
 * Ce code n'autorise rien : il est collé sur un carton que tout le monde peut
 * voir. Ce n'est pas lui qui déclenche une étape, mais l'agent qui le scanne.
 */
function newParcelCode() {
  const bloc = () => Array.from(
      crypto.randomBytes(5),
      (octet) => PARCEL_CODE_ALPHABET[octet % PARCEL_CODE_ALPHABET.length],
  ).join("");
  return `AB-${bloc()}-${bloc()}`;
}

/**
 * Valide le choix de livraison envoyé par l'application, et le normalise.
 *
 * Vérifié **avant** tout débit : découvrir après coup qu'un point relais
 * n'existe pas laisserait un achat payé et un colis que personne ne sait où
 * livrer. C'est précisément ce qui arrivait — l'écran de paiement collectait
 * le mode de livraison, le point relais et l'adresse, puis n'en transmettait
 * rien.
 *
 * @returns {Promise<{method: string, relayPointId: string|null, address: Object|null, feeXof: number}>}
 * @throws {Error} si le choix est absent, incomplet ou inexploitable.
 */
/**
 * Le défaut de livraison, modifiable en admin (`config/delivery`). Repli sur
 * `DELIVERY_CONFIG.FEES_XOF` si le doc n'existe pas. Court cache : il change
 * rarement, et on ne veut pas une lecture par paiement.
 */
let _cacheDefautLivraison = null;
async function defautLivraison() {
  if (_cacheDefautLivraison && Date.now() - _cacheDefautLivraison.at < 60000) {
    return _cacheDefautLivraison;
  }
  let relay = DELIVERY_CONFIG.FEES_XOF.relay;
  let home = DELIVERY_CONFIG.FEES_XOF.home;
  let pickup = DELIVERY_CONFIG.PICKUP_FEE_XOF;
  try {
    const snap = await db.collection("config").doc("delivery").get();
    if (snap.exists) {
      const d = snap.data();
      if (Number.isFinite(d.defaultRelayXof)) relay = Math.round(d.defaultRelayXof);
      if (Number.isFinite(d.defaultHomeXof)) home = Math.round(d.defaultHomeXof);
      if (Number.isFinite(d.defaultPickupXof)) pickup = Math.round(d.defaultPickupXof);
    }
  } catch (_) {
    // Doc absent ou illisible : on garde le repli code.
  }
  _cacheDefautLivraison = {relay, home, pickup, at: Date.now()};
  return _cacheDefautLivraison;
}

/**
 * Frais de ramassage à domicile pour une sous-catégorie. Même logique que
 * `fraisLivraison` : le tarif posé sur la sous-catégorie (`pickupXof`) prime,
 * sinon le défaut global (`defaultPickupXof`), sinon le repli code.
 */
async function fraisRamassage(subcategoryId) {
  if (subcategoryId) {
    try {
      const snap = await db.collection("config").doc("subcategories")
          .collection("items").doc(String(subcategoryId)).get();
      if (snap.exists) {
        const v = snap.data().pickupXof;
        if (Number.isFinite(v) && v >= 0) return Math.round(v);
      }
    } catch (_) {
      // On retombe sur le défaut.
    }
  }
  const def = await defautLivraison();
  return def.pickup;
}

/**
 * Frais d'acheminement pour un mode et une sous-catégorie. Priorité : le tarif
 * posé sur la sous-catégorie (`config/subcategories/items/{id}`), sinon le
 * défaut global, sinon le repli code. Un article encombrant coûte plus qu'un
 * téléphone même s'ils sont dans la même catégorie racine.
 */
async function fraisLivraison(method, subcategoryId) {
  const champ = method === "home" ? "deliveryHomeXof" : "deliveryRelayXof";
  if (subcategoryId) {
    try {
      const snap = await db.collection("config").doc("subcategories")
          .collection("items").doc(String(subcategoryId)).get();
      if (snap.exists) {
        const v = snap.data()[champ];
        if (Number.isFinite(v) && v >= 0) return Math.round(v);
      }
    } catch (_) {
      // On retombe sur le défaut.
    }
  }
  const def = await defautLivraison();
  return method === "home" ? def.home : def.relay;
}

async function normalizeDeliveryChoice(delivery, subcategoryId) {
  if (!delivery || typeof delivery !== "object") {
    throw new Error("Choisissez un mode de livraison");
  }

  const method = delivery.method === "home" ? "home" : "relay";
  const feeXof = await fraisLivraison(method, subcategoryId);

  // Contact acheteur (nom + téléphone), pour le joindre à la livraison. NON
  // obligatoire ici : un ancien client (déjà installé) n'en envoie pas, et on
  // ne veut pas bloquer son paiement. Le nouveau client, lui, l'exige côté UI.
  const contactName = delivery.contactName ?
    String(delivery.contactName).slice(0, 120) : null;
  const contactPhone = delivery.contactPhone ?
    String(delivery.contactPhone).slice(0, 40) : null;

  if (method === "relay") {
    const relayPointId = delivery.relayPointId;
    if (!relayPointId) throw new Error("Choisissez un point relais");

    const relaySnap = await db.collection("relayPoints").doc(relayPointId).get();
    if (!relaySnap.exists) throw new Error("Ce point relais n'est pas disponible");
    if (relaySnap.data().isActive === false) {
      throw new Error("Ce point relais n'est plus disponible");
    }

    return {
      method, relayPointId, address: null, contactName, contactPhone, feeXof,
    };
  }

  const address = delivery.address;
  if (!address || !address.fullName || !address.street) {
    throw new Error("Renseignez une adresse de livraison");
  }

  return {
    method,
    relayPointId: null,
    // Recopiée, et non référencée : si l'acheteur déménage ensuite, le colis
    // en cours doit continuer d'aller au bon endroit.
    address: {
      fullName: String(address.fullName),
      phone: address.phone ? String(address.phone) : null,
      street: String(address.street),
      city: address.city ? String(address.city) : null,
      country: address.country ? String(address.country) : null,
      latitude: address.latitude != null ? Number(address.latitude) : null,
      longitude: address.longitude != null ? Number(address.longitude) : null,
    },
    contactName,
    contactPhone,
    feeXof,
  };
}

const BOOST_CONFIG = {
  // Boost occasionnel : on paie 500 F et le produit part immédiatement en avant.
  PRICE_XOF: 500,
  DURATION_HOURS: 48,
  // Crédit de boost acheté d'avance (« lot »). Même prix unitaire que le boost
  // occasionnel ; ce qu'on achète, c'est le droit de booster plus tard, quand
  // on veut. Le premium (plus tard) créditera ce même solde sans passer par un
  // achat. Un crédit ne fixe aucune durée : la durée court à l'usage.
  CREDIT_PRICE_XOF: 500,
  MAX_CREDITS_PER_PURCHASE: 50,
};

/*
exports.verifyRecaptcha = onRequest(async (req, res) => {
  const token = req.body.token;
  const secret = require("firebase-functions").config().recaptcha?.secret || "fallback_secret";

  if (!token) {
    return res.status(400).json({success: false, message: "Token manquant"});
  }

  try {
    const response = await fetch(
        `https://www.google.com/recaptcha/api/siteverify?secret=${secret}&response=${token}`,
        {method: "POST"},
    );
    const data = await response.json();
    if (data.success) {
      res.json({success: true});
    } else {
      res.json({success: false, errorCodes: data["error-codes"]});
    }
  } catch (error) {
    res.status(500).json({success: false, message: "Erreur serveur"});
  }
});
*/

// ============================================================================
// FONCTION UTILITAIRE : construit un objet wallet toujours complet
// ============================================================================

/**
 * Construit l'objet `wallet` complet à écrire dans Firestore, en conservant
 * les champs personnels existants (ou `null` si le wallet n'a jamais été
 * activé) et en appliquant les montants fournis dans `patch`.
 *
 * Évite d'écrire un wallet partiel (ex : `{pendingAmount, updatedAt}` sans
 * firstName/lastName/nationality/birthDate/isActivated) quand un vendeur
 * reçoit un premier crédit avant d'avoir activé son wallet — un wallet
 * partiel fait planter la désérialisation côté client (Wallet.fromFirestore)
 * et bloque l'utilisateur sur l'écran de complétion de profil.
 *
 * @param {Object} existingWallet - `userData.wallet || {}`
 * @param {Object} patch - Champs à mettre à jour (ex : {pendingAmount: 500})
 * @return {Object} Objet wallet complet prêt pour un `update({wallet: ...})`
 */
function buildWalletUpdate(existingWallet, patch) {
  return {
    firstName: existingWallet.firstName || null,
    lastName: existingWallet.lastName || null,
    nationality: existingWallet.nationality || null,
    birthDate: existingWallet.birthDate || null,
    isActivated: existingWallet.isActivated || false,
    activatedAt: existingWallet.activatedAt || null,
    availableAmount: Number(existingWallet.availableAmount || 0),
    pendingAmount: Number(existingWallet.pendingAmount || 0),
    ...patch,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

// ============================================================================
// FONCTION UTILITAIRE PARTAGÉE : Finalisation d'un achat
// Appelée par : initiatePayment (wallet-only), confirmPayment, geniusPayWebhook
// ============================================================================

/**
 * Finalise un achat de produit de manière atomique :
 * 1. Débite le wallet de l'acheteur (si walletDeduction > 0)
 * 2. Crédite le pendingAmount du vendeur (toujours)
 * 3. Marque le produit comme vendu
 * 4. Met à jour / crée la transaction comme "completed"
 *
 * @param {Object} params
 * @param {string} params.buyerId - UID de l'acheteur
 * @param {string} params.sellerId - UID du vendeur
 * @param {string} params.productId - ID du produit
 * @param {number} params.productPrice - Prix total du produit (= montant crédité au vendeur)
 * @param {number} params.walletDeduction - Montant à débiter du wallet de l'acheteur (0 si aucun)
 * @param {string} params.transactionRef - Référence de la transaction Firestore
 * @param {string} params.paymentMethod - Méthode de paiement utilisée
 * @param {number} params.totalAmount - Montant total de la transaction (incluant les frais éventuels)
 */
async function finalizePurchase({
  buyerId, sellerId, productId, productPrice, walletDeduction,
  transactionRef, paymentMethod, totalAmount, delivery,
}) {
  // Le XOF n'a pas de décimales. Tout montant qui touche un solde doit être un
  // entier : un demi-franc (frais de protection non arrondi, prix négocié
  // fractionnaire) transformerait `availableAmount` en double et corromprait le
  // compte. On arrondit ici, seul point traversé par TOUS les canaux de
  // paiement (wallet direct, confirmPayment, webhook GeniusPay).
  productPrice = Math.round(Number(productPrice) || 0);
  walletDeduction = Math.round(Number(walletDeduction) || 0);
  totalAmount = Math.round(Number(totalAmount) || 0);

  const buyerRef = db.collection("users").doc(buyerId);
  const sellerRef = db.collection("users").doc(sellerId);
  const productRef = db.collection("products").doc(productId);
  const txDocRef = db.collection("transactions").doc(transactionRef);

  const result = await db.runTransaction(async (dbTx) => {
    // ── PHASE LECTURES (toutes les lectures d'abord, règle Firestore) ──────
    const txDoc = await dbTx.get(txDocRef);
    const buyerDoc = await dbTx.get(buyerRef);
    const sellerDoc = await dbTx.get(sellerRef);
    const productDoc = await dbTx.get(productRef);

    // Vérifier idempotence
    if (txDoc.exists && txDoc.data().status === "completed") {
      console.log(`Transaction ${transactionRef} déjà complétée, ignorée.`);
      return {alreadyCompleted: true};
    }

    // Vérifier l'existence des documents
    if (!buyerDoc.exists) throw new Error("Acheteur introuvable");
    if (!sellerDoc.exists) throw new Error("Vendeur introuvable");
    if (!productDoc.exists) throw new Error("Produit introuvable");

    // Verrou faisant autorité contre les cas de course (webhook GeniusPay
    // concurrent à une autre finalisation, double clic, etc.) : le check
    // équivalent dans initiatePayment n'est qu'un échec rapide côté UX, pas
    // une garantie — seul celui-ci, dans la transaction, l'est vraiment.
    const productDataCheck = productDoc.data();
    if (productDataCheck.isSold) throw new Error("Ce produit a déjà été vendu");
    if (productDataCheck.isReserved) throw new Error("Ce produit est réservé");
    if (productDataCheck.isHidden) throw new Error("Ce produit n'est plus disponible à l'achat");

    // Lire les données nécessaires
    const buyerData = buyerDoc.data();
    const buyerWallet = buyerData.wallet || {};
    const buyerAvailable = Number(buyerWallet.availableAmount || 0);

    const sellerData = sellerDoc.data();
    const sellerWallet = sellerData.wallet || {};
    const sellerPending = Number(sellerWallet.pendingAmount || 0);

    // Valider le solde de l'acheteur si déduction wallet nécessaire
    if (walletDeduction > 0 && buyerAvailable < walletDeduction) {
      throw new Error("Solde insuffisant dans le porte-monnaie");
    }

    // ── PHASE ÉCRITURES (après toutes les lectures) ────────────────────────

    // 1. Débiter le wallet de l'acheteur si nécessaire
    if (walletDeduction > 0) {
      dbTx.update(buyerRef, {
        wallet: buildWalletUpdate(buyerWallet, {
          availableAmount: buyerAvailable - walletDeduction,
        }),
      });
    }

    // 2. Créditer le pendingAmount du vendeur (TOUJOURS, quel que soit le moyen de paiement)
    dbTx.update(sellerRef, {
      wallet: buildWalletUpdate(sellerWallet, {
        pendingAmount: sellerPending + productPrice,
      }),
    });

    // 3. Marquer le produit comme vendu
    //
    // `status` **et** le booléen hérité. Depuis que toutes les annonces
    // portent `status`, `statusFromLegacy` ne s'applique plus jamais : ne
    // basculer que `isSold` laissait l'annonce en `active`, donc visible dans
    // les listes et affichée « en vente » au vendeur, qui ne voyait pas son
    // étiquette à imprimer.
    dbTx.update(productRef, {
      status: "sold",
      isSold: true,
      soldAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Créer ou mettre à jour la transaction comme complétée
    if (txDoc.exists) {
      // Transaction déjà créée (par initiatePayment), on la met à jour
      dbTx.update(txDocRef, {
        status: "completed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      // Créer la transaction (cas wallet-only, pas de transaction préexistante)
      dbTx.set(txDocRef, {
        reference: transactionRef,
        userId: buyerId,
        amount: totalAmount,
        paymentMethod: paymentMethod,
        status: "completed",
        type: "purchase",
        productId: productId,
        sellerId: sellerId,
        productPrice: productPrice,
        walletDeduction: walletDeduction || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      alreadyCompleted: false,
      productTitle: productDoc.exists ? (productDoc.data().title || "Produit") : "Produit",
      // Recopiée sur le reçu : la liste des commandes affiche une vignette, et
      // aller la chercher sur l'annonce coûterait une lecture par ligne — pour
      // une image qui, de toute façon, ne doit plus changer une fois vendue.
      productImage: productDoc.exists ?
        ((productDoc.data().imageUrls || [])[0] || null) :
        null,
    };
  });

  console.log(`✅ Achat finalisé : acheteur=${buyerId}, vendeur=${sellerId}, produit=${productId}, prix=${productPrice}, walletDéduit=${walletDeduction}, ref=${transactionRef}`);

  // Notifications + reçu : best-effort, ne doit jamais faire échouer le paiement déjà finalisé
  if (!result.alreadyCompleted) {
    try {
      await notifyPurchase({
        buyerId, sellerId, productId,
        productTitle: result.productTitle,
        productImage: result.productImage,
        productPrice, totalAmount, paymentMethod,
        transactionRef, delivery,
      });
    } catch (notifyError) {
      console.error(`⚠️ Échec notifications/reçu pour ${transactionRef}:`, notifyError);
    }
  }
}

// ============================================================================
// FONCTION UTILITAIRE : Finalisation d'un boost de produit
// Appelée par : initiatePayment (wallet-only), confirmPayment, geniusPayWebhook
// ============================================================================

/**
 * Finalise le boost d'un produit de manière atomique :
 * 1. Débite le wallet du vendeur si le boost est payé (en tout ou partie) via le wallet
 * 2. Marque le produit comme boosté, avec expiration dans BOOST_CONFIG.DURATION_HOURS
 * 3. Met à jour / crée la transaction comme "completed"
 *
 * Le prix (BOOST_CONFIG.PRICE_XOF) n'est jamais lu depuis le paramètre `amount`
 * fourni par le client — il est toujours imposé par la constante serveur.
 *
 * @param {Object} params
 * @param {string} params.userId - UID du vendeur qui boost son produit
 * @param {string} params.productId - ID du produit à booster
 * @param {number} params.walletDeduction - Montant à débiter du wallet (0 si payé 100% par carte/mobile money)
 * @param {string} params.transactionRef - Référence de la transaction Firestore
 */
async function finalizeBoost({userId, productId, walletDeduction, transactionRef}) {
  const userRef = db.collection("users").doc(userId);
  const productRef = db.collection("products").doc(productId);
  const txDocRef = db.collection("transactions").doc(transactionRef);

  await db.runTransaction(async (dbTx) => {
    // ── PHASE LECTURES ──────────────────────────────────────────────────
    const txDoc = await dbTx.get(txDocRef);

    // Vérifier idempotence
    if (txDoc.exists && txDoc.data().status === "completed") {
      console.log(`Boost ${transactionRef} déjà complété, ignoré.`);
      return;
    }

    const userDoc = await dbTx.get(userRef);
    const productDoc = await dbTx.get(productRef);

    if (!userDoc.exists) throw new Error("Utilisateur introuvable");
    if (!productDoc.exists) throw new Error("Produit introuvable");

    const productData = productDoc.data();
    if (productData.sellerId !== userId) {
      throw new Error("Seul le vendeur peut booster ce produit");
    }
    if (productData.isSold) {
      throw new Error("Impossible de booster un produit déjà vendu");
    }

    const userData = userDoc.data();
    const userWallet = userData.wallet || {};
    const userAvailable = Number(userWallet.availableAmount || 0);

    if (walletDeduction > 0 && userAvailable < walletDeduction) {
      throw new Error("Solde insuffisant dans le porte-monnaie");
    }

    // ── PHASE ÉCRITURES (après toutes les lectures) ────────────────────────

    // 1. Débiter le wallet si le boost est (en partie) payé depuis le solde
    if (walletDeduction > 0) {
      dbTx.update(userRef, {
        wallet: buildWalletUpdate(userWallet, {
          availableAmount: userAvailable - walletDeduction,
        }),
      });
    }

    // 2. Marquer le produit comme boosté
    const boostExpiresAt = new Date(Date.now() + BOOST_CONFIG.DURATION_HOURS * 60 * 60 * 1000);
    dbTx.update(productRef, {
      isBoosted: true,
      boostExpiresAt: admin.firestore.Timestamp.fromDate(boostExpiresAt),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Créer ou mettre à jour la transaction comme complétée
    if (txDoc.exists) {
      dbTx.update(txDocRef, {
        status: "completed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      dbTx.set(txDocRef, {
        reference: transactionRef,
        userId: userId,
        amount: BOOST_CONFIG.PRICE_XOF,
        paymentMethod: "wallet",
        status: "completed",
        type: "boost",
        productId: productId,
        walletDeduction: walletDeduction || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  console.log(`✅ Boost finalisé : utilisateur=${userId}, produit=${productId}, ref=${transactionRef}`);
}

// ============================================================================
// RAMASSAGE À DOMICILE (payé par le vendeur)
// ============================================================================

/**
 * Finalise un ramassage à domicile, de manière atomique et idempotente. Le
 * vendeur paie pour qu'un agent vienne chercher le colis chez lui au lieu de le
 * déposer en relais. On débite le solde (si payé en tout ou partie au
 * porte-monnaie), on marque le colis `pickupRequested`, et on range l'adresse
 * + le contact du vendeur dans un sous-document privé (les mêmes règles de
 * confidentialité que pour l'adresse de l'acheteur : jamais sur le colis
 * lui-même). L'argent va à Ablony — c'est un service, pas une contrepartie.
 *
 * @param {Object} params
 * @param {string} params.userId - UID du vendeur (payeur)
 * @param {string} params.parcelCode - code du colis à récupérer
 * @param {number} params.walletDeduction - montant débité du solde (0 si externe)
 * @param {number} params.feeXof - frais de ramassage imposés par le serveur
 * @param {Object|null} params.pickupContact - {name, phone} du vendeur
 * @param {Object|null} params.pickupAddress - adresse structurée du vendeur
 * @param {string} params.transactionRef - référence de la transaction
 */
async function finalizePickup({
  userId, parcelCode, walletDeduction, feeXof,
  pickupContact, pickupAddress, transactionRef,
}) {
  const userRef = db.collection("users").doc(userId);
  const parcelRef = db.collection("parcels").doc(String(parcelCode));
  const pickupPrivateRef = parcelRef.collection("private").doc("pickup");
  const txDocRef = db.collection("transactions").doc(transactionRef);

  await db.runTransaction(async (dbTx) => {
    const txDoc = await dbTx.get(txDocRef);
    if (txDoc.exists && txDoc.data().status === "completed") {
      console.log(`Ramassage ${transactionRef} déjà complété, ignoré.`);
      return;
    }

    const userDoc = await dbTx.get(userRef);
    const parcelDoc = await dbTx.get(parcelRef);
    if (!userDoc.exists) throw new Error("Utilisateur introuvable");
    if (!parcelDoc.exists) throw new Error("Colis introuvable");

    const parcelData = parcelDoc.data();
    if (parcelData.sellerId !== userId) {
      throw new Error("Seul le vendeur du colis peut demander un ramassage");
    }
    if (parcelData.pickupRequested === true) {
      throw new Error("Un ramassage a déjà été demandé pour ce colis");
    }

    const userData = userDoc.data();
    const userWallet = userData.wallet || {};
    const userAvailable = Number(userWallet.availableAmount || 0);
    if (walletDeduction > 0 && userAvailable < walletDeduction) {
      throw new Error("Solde insuffisant dans le porte-monnaie");
    }

    // ── ÉCRITURES ──────────────────────────────────────────────────────────
    if (walletDeduction > 0) {
      dbTx.update(userRef, {
        wallet: buildWalletUpdate(userWallet, {
          availableAmount: userAvailable - walletDeduction,
        }),
      });
    }

    // Le colis porte seulement le drapeau (lisible des deux parties) ; l'adresse
    // et le téléphone du vendeur, eux, restent dans le sous-document privé.
    dbTx.update(parcelRef, {
      pickupRequested: true,
      pickupFeeXof: Math.round(Number(feeXof) || 0),
      pickupRequestedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    dbTx.set(pickupPrivateRef, {
      sellerId: userId,
      contactName: pickupContact ? (pickupContact.name || null) : null,
      contactPhone: pickupContact ? (pickupContact.phone || null) : null,
      address: pickupAddress || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (txDoc.exists) {
      dbTx.update(txDocRef, {
        status: "completed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      dbTx.set(txDocRef, {
        reference: transactionRef,
        userId: userId,
        amount: Math.round(Number(feeXof) || 0),
        paymentMethod: "wallet",
        status: "completed",
        type: "pickup",
        parcelCode: String(parcelCode),
        walletDeduction: walletDeduction || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  console.log(`✅ Ramassage finalisé : vendeur=${userId}, colis=${parcelCode}, ref=${transactionRef}`);
}

// ============================================================================
// LOTS DE CRÉDITS DE BOOST
// ============================================================================

/**
 * Finalise l'achat d'un lot de crédits de boost, de manière atomique et
 * idempotente : crédite `quantity` boosts au solde de l'utilisateur, débite le
 * wallet si le lot est payé (en tout ou partie) depuis le solde, et marque la
 * transaction « completed ». Aucun produit n'est boosté ici — les crédits sont
 * dépensés plus tard via `applyBoost`.
 *
 * @param {Object} params
 * @param {string} params.userId - UID de l'acheteur du lot
 * @param {number} params.quantity - nombre de crédits achetés
 * @param {number} params.walletDeduction - montant à débiter du wallet (0 si 100% externe)
 * @param {string} params.transactionRef - référence de la transaction Firestore
 */
async function finalizeBoostPack({userId, quantity, walletDeduction, transactionRef}) {
  const userRef = db.collection("users").doc(userId);
  const txDocRef = db.collection("transactions").doc(transactionRef);
  const qte = Math.max(1, Math.floor(Number(quantity) || 1));

  await db.runTransaction(async (dbTx) => {
    const txDoc = await dbTx.get(txDocRef);
    if (txDoc.exists && txDoc.data().status === "completed") {
      console.log(`Lot de boosts ${transactionRef} déjà complété, ignoré.`);
      return;
    }

    const userDoc = await dbTx.get(userRef);
    if (!userDoc.exists) throw new Error("Utilisateur introuvable");

    const userData = userDoc.data();
    const userWallet = userData.wallet || {};
    const userAvailable = Number(userWallet.availableAmount || 0);

    if (walletDeduction > 0 && userAvailable < walletDeduction) {
      throw new Error("Solde insuffisant dans le porte-monnaie");
    }

    if (walletDeduction > 0) {
      dbTx.update(userRef, {
        wallet: buildWalletUpdate(userWallet, {
          availableAmount: userAvailable - walletDeduction,
        }),
      });
    }

    dbTx.update(userRef, {
      boostCredits: admin.firestore.FieldValue.increment(qte),
    });

    if (txDoc.exists) {
      dbTx.update(txDocRef, {
        status: "completed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      dbTx.set(txDocRef, {
        reference: transactionRef,
        userId: userId,
        amount: BOOST_CONFIG.CREDIT_PRICE_XOF * qte,
        paymentMethod: "wallet",
        status: "completed",
        type: "boostpack",
        quantity: qte,
        walletDeduction: walletDeduction || 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  console.log(`✅ Lot de ${qte} crédit(s) de boost finalisé : utilisateur=${userId}, ref=${transactionRef}`);
}

// ============================================================================
// NOTIFICATIONS + REÇU (déclenchés après un achat finalisé)
// ============================================================================

/**
 * Envoie une notification push à un utilisateur via ses tokens FCM enregistrés
 * (users/{uid}.fcmTokens). Nettoie automatiquement les tokens expirés/invalides.
 */
async function sendPushToUser(uid, {title, body}, data) {
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) return;

  const tokens = userDoc.data().fcmTokens || [];
  if (tokens.length === 0) return;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data: Object.fromEntries(
        Object.entries(data || {}).map(([k, v]) => [k, String(v)]),
    ),
  });

  // Nettoyer les tokens invalides/désinstallés pour éviter de les renvoyer plus tard
  const staleTokens = [];
  response.responses.forEach((res, index) => {
    if (!res.success) {
      const code = res.error && res.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        staleTokens.push(tokens[index]);
      }
    }
  });

  if (staleTokens.length > 0) {
    await db.collection("users").doc(uid).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
    });
  }
}

/**
 * Crée le reçu, les notifications in-app (acheteur + vendeur) et envoie les push
 * correspondants suite à un achat finalisé. Les IDs sont dérivés de transactionRef
 * pour rester idempotents en cas de rejeu (webhook + confirmPayment par exemple).
 */
async function notifyPurchase({
  buyerId, sellerId, productId, productTitle, productImage, productPrice,
  totalAmount, paymentMethod, transactionRef, delivery,
}) {
  const receiptRef = db.collection("receipts").doc(transactionRef);
  const sellerNotifRef = db.collection("notifications").doc(`${transactionRef}_seller`);
  const buyerNotifRef = db.collection("notifications").doc(`${transactionRef}_buyer`);

  const now = admin.firestore.FieldValue.serverTimestamp();

  // Le colis, et son code d'étiquette. Ce code remplace l'ancienne
  // indirection "qrcodes", qui servait une remise en main propre : le vendeur
  // affichait un QR, l'acheteur le scannait. Ce n'est pas ce que fait Ablony.
  // Le vendeur imprime ce code, le colle sur le carton, et le dépose en point
  // relais — son travail s'arrête là.
  const parcelCode = newParcelCode();
  const dropoffDeadline = admin.firestore.Timestamp.fromMillis(
      Date.now() + DELIVERY_CONFIG.DROPOFF_DEADLINE_DAYS * 24 * 60 * 60 * 1000,
  );

  const parcelRef = db.collection("parcels").doc(parcelCode);

  // Le colis lui-même est lisible par les deux parties : le vendeur y prend
  // son code à imprimer, l'acheteur y suit son acheminement. Il ne porte donc
  // que ce qu'ils peuvent voir tous les deux. Le point relais en fait partie —
  // c'est une adresse publique.
  await parcelRef.set({
    code: parcelCode,
    transactionRef,
    sellerId,
    buyerId,
    productId,
    productTitle,
    method: delivery ? delivery.method : "relay",
    relayPointId: delivery ? delivery.relayPointId : null,
    status: "awaiting_dropoff",
    dropoffDeadline,
    droppedOffAt: null,
    deliveredAt: null,
    createdAt: now,
  });

  // L'adresse du domicile, elle, va dans un document à part : une règle
  // Firestore autorise ou refuse un document entier, jamais un champ. Laissée
  // sur le colis, elle serait lisible par le vendeur — qui ne livre pas et n'a
  // pas à savoir où habite son acheteur. Nos agents l'obtiennent par
  // `resolveParcel`, qui vérifie leur rôle.
  // L'adresse ET le téléphone de contact vont dans ce document privé : le
  // vendeur peut lire le colis, mais n'a à connaître ni où habite l'acheteur ni
  // son numéro. Nos agents l'obtiennent par `resolveParcel`, après vérification
  // de leur rôle. On crée le document dès qu'il y a une adresse OU un contact —
  // donc aussi pour un retrait en point relais (contact seul).
  const contactName = delivery ? (delivery.contactName || null) : null;
  const contactPhone = delivery ? (delivery.contactPhone || null) : null;
  if (delivery && (delivery.address || contactName || contactPhone)) {
    await parcelRef.collection("private").doc("destination").set({
      buyerId,
      address: delivery.address || null,
      contactName,
      contactPhone,
      createdAt: now,
    });
  }

  await receiptRef.set({
    transactionRef,
    buyerId,
    sellerId,
    productId,
    productTitle,
    productImage: productImage || null,
    productPrice,
    totalAmount,
    paymentMethod,
    deliveryConfirmed: false,
    parcelCode,
    // Ni adresse ni choix de livraison : le reçu est lu par le vendeur aussi.
    // Le mode suffit à expliquer les frais ; le reste appartient au colis.
    deliveryMethod: delivery ? delivery.method : "relay",
    createdAt: now,
  });

  const consigne = delivery && delivery.method === "home" ?
    "Imprimez votre étiquette et déposez le colis en point relais : nous le livrons ensuite à domicile." :
    "Imprimez votre étiquette et déposez le colis en point relais.";

  await sellerNotifRef.set({
    userId: sellerId,
    type: "purchase_received",
    title: "Nouvelle vente !",
    body: `Votre article "${productTitle}" vient d'être vendu pour ${productPrice} FCFA. ${consigne}`,
    data: {productId, transactionRef, buyerId, parcelCode},
    read: false,
    createdAt: now,
  });

  await buyerNotifRef.set({
    userId: buyerId,
    type: "purchase_confirmed",
    title: "Achat confirmé",
    body: `Vous avez acheté "${productTitle}". Votre reçu est disponible.`,
    data: {productId, transactionRef, receiptId: transactionRef, sellerId},
    read: false,
    createdAt: now,
  });

  await Promise.all([
    sendPushToUser(
        sellerId,
        {
          title: "Nouvelle vente !",
          body: `"${productTitle}" est vendu. Imprimez l'étiquette ${parcelCode} et déposez le colis en point relais.`,
        },
        {type: "purchase_received", productId, transactionRef, parcelCode},
    ),
    sendPushToUser(
        buyerId,
        {
          title: "Achat confirmé",
          body: `Vous avez acheté "${productTitle}". Votre reçu est disponible.`,
        },
        {type: "purchase_confirmed", productId, transactionRef, receiptId: transactionRef},
    ),
  ]);

  console.log(`🔔 Notifications + reçu + colis ${parcelCode} créés pour ${transactionRef}`);
}

// ============================================================================
// 1. INITIER UN PAIEMENT
// ============================================================================

/**
 * Dépense un crédit de boost pour mettre un produit en avant, sans paiement.
 *
 * Le solde de crédits (`boostCredits`) est alimenté à l'achat d'un lot
 * (`finalizeBoostPack`) ou, plus tard, par l'abonnement premium. Ici on n'en
 * consomme qu'un et on marque le produit boosté pour BOOST_CONFIG.DURATION_HOURS
 * — la durée court à partir de **cet instant**, pas de l'achat du crédit.
 *
 * Tout se joue dans une transaction Firestore : le décrément du solde et le
 * boost sont indissociables. Si le solde est nul, ou si le produit n'appartient
 * pas au demandeur / est déjà vendu, rien n'est débité.
 *
 * Authentification via ID token (header `Authorization: Bearer <token>`) :
 * l'uid du token est la seule source d'identité, jamais un champ du corps.
 */
exports.applyBoost = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.status(204).send("");
    return;
  }

  const authHeader = req.headers.authorization || "";
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!idToken) {
    return res.status(401).json({success: false, error: {message: "Authentification requise"}});
  }

  let decodedToken;
  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    return res.status(401).json({success: false, error: {message: "Token invalide"}});
  }

  const userId = decodedToken.uid;
  const {productId} = req.body;
  if (!productId) {
    return res.status(400).json({success: false, error: {message: "Paramètre requis manquant : productId"}});
  }

  const userRef = db.collection("users").doc(userId);
  const productRef = db.collection("products").doc(productId);

  try {
    const boostExpiresAt = new Date(Date.now() + BOOST_CONFIG.DURATION_HOURS * 60 * 60 * 1000);

    await db.runTransaction(async (dbTx) => {
      const userDoc = await dbTx.get(userRef);
      const productDoc = await dbTx.get(productRef);

      if (!userDoc.exists) throw new Error("Utilisateur introuvable");
      if (!productDoc.exists) throw new Error("Produit introuvable");

      const productData = productDoc.data();
      if (productData.sellerId !== userId) {
        throw new Error("Seul le vendeur peut booster ce produit");
      }
      if (productData.isSold) {
        throw new Error("Impossible de booster un produit déjà vendu");
      }
      // Déjà boosté et non expiré : ne pas consommer un crédit pour ne gagner
      // que l'écart d'expiration.
      if (productData.isBoosted === true &&
          productData.boostExpiresAt &&
          productData.boostExpiresAt.toDate() > new Date()) {
        throw new Error("Ce produit est déjà boosté");
      }

      const credits = Math.floor(Number(userDoc.data().boostCredits || 0));
      if (credits < 1) {
        throw new Error("Aucun crédit de boost disponible");
      }

      dbTx.update(userRef, {
        boostCredits: admin.firestore.FieldValue.increment(-1),
      });
      dbTx.update(productRef, {
        isBoosted: true,
        boostExpiresAt: admin.firestore.Timestamp.fromDate(boostExpiresAt),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      // Trace comptable : un boost dépensé, montant nul (déjà payé à l'achat
      // du lot, ou offert par le premium). Sert au suivi et à l'historique.
      const reference = "TX-BSTC-" + Date.now();
      dbTx.set(db.collection("transactions").doc(reference), {
        reference: reference,
        userId: userId,
        amount: 0,
        paymentMethod: "credit",
        status: "completed",
        type: "boost_credit",
        productId: productId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`✅ Boost par crédit : utilisateur=${userId}, produit=${productId}`);
    return res.status(200).json({
      success: true,
      data: {status: "completed", boostExpiresAt: boostExpiresAt.toISOString()},
    });
  } catch (error) {
    console.error("Erreur applyBoost:", error);
    const message = error.message || "Erreur lors de l'application du boost";
    const code = message.includes("crédit") ? 400 :
      message.includes("déjà boosté") ? 400 :
        message.includes("vendeur") ? 403 :
          message.includes("vendu") ? 400 :
            message.includes("introuvable") ? 404 : 500;
    return res.status(code).json({success: false, error: {message}});
  }
});

/**
 * Recherche d'un lieu par son nom (géocodage direct).
 *
 * Pourquoi passer par le serveur plutôt que par un paquet Flutter : le paquet
 * `geocoding` ne gère qu'Android et iOS. Sur le web, la recherche d'adresse ne
 * renvoyait donc jamais rien. Un seul appel HTTP ici sert les trois
 * plateformes, et la clé Google reste côté serveur.
 *
 * Les résultats sont restreints au Togo et au Bénin : ce sont les deux pays
 * livrés, et sans ce filtre « Kara » ou « Agoè » ramène des lieux à l'autre
 * bout du monde.
 *
 * Authentification par ID token : sans cela, l'adresse publique de cette
 * fonction serait un service de géocodage gratuit pour n'importe qui, facturé
 * sur notre compte Google.
 */
exports.geocodeSearch = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.status(204).send("");
    return;
  }

  const authHeader = req.headers.authorization || "";
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!idToken) {
    return res.status(401).json({success: false, error: {message: "Authentification requise"}});
  }
  try {
    await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    return res.status(401).json({success: false, error: {message: "Token invalide"}});
  }

  const query = String(req.body?.query || "").trim();
  if (!query) {
    return res.status(400).json({success: false, error: {message: "Paramètre requis manquant : query"}});
  }

  const cle = process.env.GOOGLE_MAPS_API_KEY;
  if (!cle) {
    console.error("GOOGLE_MAPS_API_KEY absente de functions/.env");
    return res.status(500).json({
      success: false,
      error: {message: "Recherche d'adresse indisponible"},
    });
  }

  const composant = (types, resultat, champ = "long_name") => {
    const trouve = (resultat.address_components || [])
      .find((c) => types.some((t) => c.types.includes(t)));
    return trouve ? trouve[champ] : null;
  };

  // Le paramètre `components` de Google ne restreint pas de façon fiable :
  // « Bruxelles » remonte quand même la Belgique, et les requêtes floues
  // renvoient le centre du pays (type `country`) en tête — une « adresse » où
  // aucun colis ne peut être livré. On filtre donc nous-mêmes.
  const PAYS_LIVRES = ["Togo", "Bénin", "Benin"];
  const tropVague = (r) => (r.types || []).some((t) =>
    t === "country" || t === "administrative_area_level_1");

  /** Un appel de géocodage, nettoyé. Renvoie [] si rien d'exploitable. */
  async function geocoder(adresse) {
    const url = "https://maps.googleapis.com/maps/api/geocode/json" +
      `?address=${encodeURIComponent(adresse)}` +
      "&components=country:TG|country:BJ" +
      "&language=fr" +
      `&key=${cle}`;

    const corps = await (await fetch(url)).json();

    // ZERO_RESULTS est une réponse normale, pas une panne.
    if (corps.status !== "OK" && corps.status !== "ZERO_RESULTS") {
      const erreur = new Error(corps.error_message || corps.status);
      erreur.statutGoogle = corps.status;
      throw erreur;
    }

    return (corps.results || [])
      .filter((r) => !tropVague(r))
      .map((r) => ({
        latitude: r.geometry.location.lat,
        longitude: r.geometry.location.lng,
        formattedAddress: r.formatted_address,
        street: composant(["route", "street_address"], r),
        city: composant(["locality", "administrative_area_level_2"], r),
        postalCode: composant(["postal_code"], r),
        country: composant(["country"], r),
      }))
      .filter((r) => PAYS_LIVRES.includes(r.country))
      .slice(0, 5);
  }

  try {
    // L'API Geocoding attend une adresse complète, pas un nom de quartier :
    // « Agoe » seul retombe sur le centre du Togo, alors que « Agoe, Lomé »
    // trouve. On réessaie donc en ajoutant la ville, ce qui couvre les noms de
    // quartiers que les gens tapent réellement. La grande majorité des
    // recherches aboutit dès le premier appel ; les replis ne coûtent que sur
    // les requêtes qui auraient sinon échoué.
    const villes = req.body?.country === "BJ"
      ? ["Cotonou", "Lomé"]
      : ["Lomé", "Cotonou"];

    let results = await geocoder(query);
    for (const ville of villes) {
      if (results.length > 0) break;
      if (query.toLowerCase().includes(ville.toLowerCase())) continue;
      results = await geocoder(`${query}, ${ville}`);
    }

    return res.status(200).json({success: true, data: {results}});
  } catch (error) {
    console.error("Erreur geocodeSearch:", error);
    return res.status(500).json({
      success: false,
      error: {message: "La recherche d'adresse a échoué"},
    });
  }
});

/**
 * Suggestions de lieux au fil de la frappe, façon Google Maps.
 *
 * Deux usages, un seul point d'entrée :
 * - `{input}`     → la liste des suggestions (Places Autocomplete) ;
 * - `{placeId}`   → les coordonnées du lieu choisi (Place Details).
 *
 * Pourquoi pas l'API Geocoding utilisée par `geocodeSearch` : elle attend une
 * adresse complète et ne répond rien sur une saisie partielle (« Adido »).
 * Autocomplete est faite pour ça.
 *
 * **Le `sessionToken` n'est pas un détail de confort : c'est ce qui contient la
 * facture.** Google regroupe toutes les frappes d'une même recherche et le
 * `placeId` finalement retenu en *une* session facturée, au lieu de facturer
 * chaque appel. Le client génère un jeton quand il commence à taper et le
 * réutilise jusqu'au choix du lieu.
 */
exports.placeSearch = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.status(204).send("");
    return;
  }

  const authHeader = req.headers.authorization || "";
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!idToken) {
    return res.status(401).json({success: false, error: {message: "Authentification requise"}});
  }
  try {
    await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    return res.status(401).json({success: false, error: {message: "Token invalide"}});
  }

  const cle = process.env.GOOGLE_MAPS_API_KEY;
  if (!cle) {
    console.error("GOOGLE_MAPS_API_KEY absente de functions/.env");
    return res.status(500).json({success: false, error: {message: "Recherche indisponible"}});
  }

  const {input, placeId, sessionToken} = req.body || {};

  try {
    // ── Le lieu a été choisi : on va chercher ses coordonnées ────────────
    if (placeId) {
      const url = `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}` +
        "?languageCode=fr" +
        (sessionToken ? `&sessionToken=${encodeURIComponent(sessionToken)}` : "");

      const reponse = await fetch(url, {
        headers: {
          "X-Goog-Api-Key": cle,
          "X-Goog-FieldMask": "formattedAddress,location,addressComponents",
        },
      });
      const corps = await reponse.json();

      if (corps.error) {
        console.error("Place Details refusé:", corps.error.status, corps.error.message);
        return res.status(502).json({success: false, error: {message: "Lieu introuvable"}});
      }

      const composant = (types) => {
        const trouve = (corps.addressComponents || [])
          .find((c) => types.some((t) => (c.types || []).includes(t)));
        return trouve ? trouve.longText : null;
      };

      return res.status(200).json({
        success: true,
        data: {
          place: {
            latitude: corps.location.latitude,
            longitude: corps.location.longitude,
            formattedAddress: corps.formattedAddress,
            street: composant(["route", "street_address"]),
            city: composant(["locality", "administrative_area_level_2"]),
            postalCode: composant(["postal_code"]),
            country: composant(["country"]),
          },
        },
      });
    }

    // ── Frappe en cours : on renvoie des suggestions ─────────────────────
    const saisie = String(input || "").trim();
    // Sous trois caractères, les suggestions n'ont aucune valeur et chaque
    // appel se facture : on ne demande rien.
    if (saisie.length < 3) {
      return res.status(200).json({success: true, data: {suggestions: []}});
    }

    const reponse = await fetch("https://places.googleapis.com/v1/places:autocomplete", {
      method: "POST",
      headers: {"X-Goog-Api-Key": cle, "Content-Type": "application/json"},
      body: JSON.stringify({
        input: saisie,
        // Les deux seuls pays livrés : inutile de proposer Bruxelles.
        includedRegionCodes: ["TG", "BJ"],
        languageCode: "fr",
        ...(sessionToken ? {sessionToken} : {}),
      }),
    });
    const corps = await reponse.json();

    if (corps.error) {
      console.error("Autocomplete refusé:", corps.error.status, corps.error.message);
      return res.status(502).json({success: false, error: {message: "La recherche a échoué"}});
    }

    const suggestions = (corps.suggestions || [])
      .filter((s) => s.placePrediction)
      .slice(0, 5)
      .map((s) => ({
        placeId: s.placePrediction.placeId,
        title: s.placePrediction.structuredFormat?.mainText?.text ||
          s.placePrediction.text?.text || "",
        subtitle: s.placePrediction.structuredFormat?.secondaryText?.text || "",
      }));

    return res.status(200).json({success: true, data: {suggestions}});
  } catch (error) {
    console.error("Erreur placeSearch:", error);
    return res.status(500).json({success: false, error: {message: "La recherche a échoué"}});
  }
});

/**
 * Prix négocié d'un article, lu depuis l'offre acceptée — jamais depuis le
 * client. Sans cela, une vente conclue à un prix inférieur au prix affiché
 * échouerait au contrôle de montant (le serveur ne connaîtrait que le prix de
 * base). On cherche l'offre `accepted` la plus récente pour ce trio exact
 * (acheteur, vendeur, article) dans leur conversation.
 *
 * Sécurité : on ne fait confiance à `offer.status == 'accepted'` que parce que
 * les règles Firestore interdisent d'accepter sa propre offre (seul le
 * destinataire le peut) et gèlent `offer.amount`/`offer.productId`. Dans les
 * deux sens de négociation, cela garantit que le VENDEUR a consenti au montant
 * (il a soit accepté l'offre de l'acheteur, soit émis la contre-offre que
 * l'acheteur a acceptée). Sans ces règles, cette lecture serait exploitable.
 *
 * @param {string} buyerId - Acheteur (utilisateur authentifié qui paie).
 * @param {string} sellerId - Vendeur, lu de l'annonce (jamais de la requête).
 * @param {string} productId - Article acheté.
 * @return {Promise<number|null>} Le montant négocié, ou null si aucune offre
 *   acceptée n'existe (achat au prix affiché).
 */
async function prixNegocieAccepte(buyerId, sellerId, productId) {
  if (!buyerId || !sellerId || !productId) return null;

  const conversations = await db
      .collection("conversations")
      .where("participants", "array-contains", buyerId)
      .get();

  let prix = null;
  let tsMax = -1;

  for (const conv of conversations.docs) {
    const participants = conv.get("participants") || [];
    if (!participants.includes(sellerId)) continue;

    const offres = await conv.ref
        .collection("messages")
        .where("offer.productId", "==", productId)
        .where("offer.status", "==", "accepted")
        .get();

    for (const msg of offres.docs) {
      const offer = msg.get("offer") || {};
      const montant = Number(offer.amount);
      const ts = msg.get("timestamp");
      const tsMs = ts && typeof ts.toMillis === "function" ? ts.toMillis() : 0;
      // On retient la plus récente : une offre acceptée fait foi tant qu'elle
      // n'a pas été remplacée par une nouvelle négociation.
      if (Number.isFinite(montant) && montant > 0 && tsMs >= tsMax) {
        tsMax = tsMs;
        prix = montant;
      }
    }
  }

  return prix;
}

exports.initiatePayment = onRequest(async (req, res) => {
  // Configuration CORS
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.status(204).send("");
    return;
  }

  let {amount, paymentMethod, phone, userId, email, name, description, type, productId, sellerId, productPrice, walletDeduction, delivery, quantity, parcelCode} = req.body;
  let deliveryChoice = null;
  let pickupContext = null;

  if (!amount || !paymentMethod || !userId) {
    return res.status(400).json({
      success: false,
      error: {message: "Paramètres requis manquants : amount, paymentMethod, userId"},
    });
  }

  if (type === "purchase" && (!productId || !sellerId)) {
    return res.status(400).json({
      success: false,
      error: {message: "Paramètres requis manquants pour un achat : productId, sellerId"},
    });
  }

  if (type === "purchase") {
    // Échec rapide avant même de contacter GeniusPay : évite de faire payer
    // quelqu'un pour un article devenu indisponible entre l'ouverture de la
    // fiche produit et le clic sur "Acheter" (vendu, réservé, ou masqué —
    // notamment suite à la suppression du compte vendeur, cf. deleteAccount
    // ci-dessous). Le vrai verrou, contre les cas de course (webhook
    // GeniusPay concurrent, double clic), est dans finalizePurchase.
    const productSnap = await db.collection("products").doc(productId).get();
    if (!productSnap.exists) {
      return res.status(404).json({
        success: false,
        error: {message: "Produit introuvable"},
      });
    }
    const productData = productSnap.data();
    if (productData.isSold) {
      return res.status(400).json({
        success: false,
        error: {message: "Ce produit a déjà été vendu"},
      });
    }
    if (productData.isReserved) {
      return res.status(400).json({
        success: false,
        error: {message: "Ce produit est réservé"},
      });
    }
    if (productData.isHidden) {
      return res.status(400).json({
        success: false,
        error: {message: "Ce produit n'est plus disponible à l'achat"},
      });
    }

    // La destination est validée ici, avant tout débit et avant d'appeler
    // GeniusPay. Un achat sans destination exploitable est un article vendu
    // et attendu nulle part.
    try {
      deliveryChoice = await normalizeDeliveryChoice(
          delivery, productData.subcategoryId,
      );
    } catch (deliveryError) {
      return res.status(400).json({
        success: false,
        error: {message: deliveryError.message},
      });
    }

    // Le prix vient de l'annonce, jamais de la requête : le lire dans le
    // corps reviendrait à laisser l'acheteur fixer le prix. `productPrice`
    // est écrasé pour que la suite de la fonction — et la finalisation —
    // travaille sur la seule valeur qui fasse foi.
    productPrice = Number(productData.price);

    // Vente négociée : si une offre a été acceptée pour ce trio
    // (acheteur, vendeur, article), c'est ce montant-là qui fait foi, pas le
    // prix affiché. Le vendeur (productData.sellerId) est la seule référence
    // de confiance — jamais le `sellerId` de la requête.
    const prixNegocie = await prixNegocieAccepte(
        userId, productData.sellerId, productId,
    );
    if (prixNegocie != null) {
      productPrice = prixNegocie;
    }

    // XOF sans décimales : on arrondit le prix avant tout calcul de frais, pour
    // que le total attendu et le crédit vendeur tombent juste.
    productPrice = Math.round(productPrice);

    // Le total est recalculé de la même façon. Le client l'affiche, il ne le
    // fixe pas : sans ce contrôle, il suffirait d'annoncer 0 F de frais.
    const attendu = Math.round(
        productPrice +
      productPrice * DELIVERY_CONFIG.PROTECTION_RATE +
      deliveryChoice.feeXof,
    );

    // `amount` ne vaut le total que si le paiement passe par un seul canal.
    // En paiement mixte, il ne porte que la part externe, le reste venant du
    // porte-monnaie : c'est leur somme qu'il faut comparer. Comparer `amount`
    // seul ferait échouer tout paiement mixte, et le remplacer par le total
    // débiterait l'acheteur deux fois.
    const partPorteMonnaie = walletDeduction != null ? Number(walletDeduction) : 0;
    const totalAnnonce = Number(amount) + partPorteMonnaie;

    if (Math.abs(totalAnnonce - attendu) > 1) {
      return res.status(400).json({
        success: false,
        error: {message: `Montant incohérent : ${attendu} FCFA attendus`},
      });
    }

    // Le montant qui fait foi est le total attendu (entier). On aligne dessus
    // ce qui sera débité/stocké, pour qu'aucun demi-franc issu de l'affichage
    // client ne parvienne au solde ni au reçu. En wallet-only, la déduction est
    // le total ; en mixte, on garde la part externe entière et on complète au
    // porte-monnaie pour retomber exactement sur `attendu`.
    if (walletDeduction != null && Number(walletDeduction) > 0) {
      const partExterne = Math.round(Number(amount) || 0);
      walletDeduction = Math.max(0, attendu - partExterne);
      amount = partExterne > 0 ? partExterne : attendu;
    } else {
      amount = attendu;
    }
  }

  if (type === "boost") {
    if (!productId) {
      return res.status(400).json({
        success: false,
        error: {message: "Paramètre requis manquant pour un boost : productId"},
      });
    }

    const productSnap = await db.collection("products").doc(productId).get();
    if (!productSnap.exists) {
      return res.status(404).json({
        success: false,
        error: {message: "Produit introuvable"},
      });
    }
    const productData = productSnap.data();
    if (productData.sellerId !== userId) {
      return res.status(403).json({
        success: false,
        error: {message: "Seul le vendeur peut booster ce produit"},
      });
    }
    if (productData.isSold) {
      return res.status(400).json({
        success: false,
        error: {message: "Impossible de booster un produit déjà vendu"},
      });
    }
    // Déjà boosté et non expiré : refuser AVANT tout paiement, pour ne pas
    // faire payer un boost qui ne ferait qu'étendre l'expiration.
    if (productData.isBoosted === true &&
        productData.boostExpiresAt &&
        productData.boostExpiresAt.toDate() > new Date()) {
      return res.status(400).json({
        success: false,
        error: {message: "Ce produit est déjà boosté"},
      });
    }

    // Le prix du boost est toujours imposé par le serveur, jamais par le client
    amount = BOOST_CONFIG.PRICE_XOF;
    if (walletDeduction != null) walletDeduction = Math.min(Number(walletDeduction), amount);
  }

  if (type === "boostpack") {
    // Achat d'un lot de crédits de boost, à dépenser plus tard. Aucun produit
    // n'est requis : on ne boost rien maintenant, on remplit un solde.
    const qte = Math.floor(Number(quantity) || 0);
    if (qte < 1 || qte > BOOST_CONFIG.MAX_CREDITS_PER_PURCHASE) {
      return res.status(400).json({
        success: false,
        error: {message: `Quantité de crédits invalide (1 à ${BOOST_CONFIG.MAX_CREDITS_PER_PURCHASE})`},
      });
    }
    quantity = qte;
    // Le prix est imposé par le serveur : jamais lu depuis `amount` du client.
    amount = BOOST_CONFIG.CREDIT_PRICE_XOF * qte;
    if (walletDeduction != null) walletDeduction = Math.min(Number(walletDeduction), amount);
  }

  if (type === "pickup") {
    // Ramassage à domicile, payé par le vendeur après la vente. Le colis existe
    // déjà (créé à l'achat) ; on le retrouve par son code.
    if (!parcelCode) {
      return res.status(400).json({
        success: false,
        error: {message: "Paramètre requis manquant pour un ramassage : parcelCode"},
      });
    }
    const parcelSnap = await db.collection("parcels").doc(String(parcelCode)).get();
    if (!parcelSnap.exists) {
      return res.status(404).json({
        success: false,
        error: {message: "Colis introuvable"},
      });
    }
    const parcelData = parcelSnap.data();
    if (parcelData.sellerId !== userId) {
      return res.status(403).json({
        success: false,
        error: {message: "Seul le vendeur du colis peut demander un ramassage"},
      });
    }
    if (parcelData.pickupRequested === true) {
      return res.status(400).json({
        success: false,
        error: {message: "Un ramassage a déjà été demandé pour ce colis"},
      });
    }

    // Le contact + l'adresse du vendeur viennent du client (structure identique
    // à une adresse de livraison). L'adresse est exigée : sans elle, aucun agent
    // ne sait où aller.
    const pAddress = delivery && delivery.address ? delivery.address : null;
    if (!pAddress || !pAddress.fullName || !pAddress.street) {
      return res.status(400).json({
        success: false,
        error: {message: "Renseignez l'adresse de ramassage"},
      });
    }

    // Le tarif est imposé par le serveur, selon la sous-catégorie du produit.
    let subcategoryId = null;
    if (parcelData.productId) {
      try {
        const prodSnap = await db.collection("products")
            .doc(parcelData.productId).get();
        if (prodSnap.exists) subcategoryId = prodSnap.data().subcategoryId || null;
      } catch (_) {
        // On retombe sur le défaut de ramassage.
      }
    }
    const feeXof = await fraisRamassage(subcategoryId);

    pickupContext = {
      parcelCode: String(parcelCode),
      feeXof,
      contact: {
        name: delivery.contactName ? String(delivery.contactName).slice(0, 120) : null,
        phone: delivery.contactPhone ? String(delivery.contactPhone).slice(0, 40) : null,
      },
      address: {
        fullName: String(pAddress.fullName),
        phone: pAddress.phone ? String(pAddress.phone) : null,
        street: String(pAddress.street),
        city: pAddress.city ? String(pAddress.city) : null,
        country: pAddress.country ? String(pAddress.country) : null,
        latitude: pAddress.latitude != null ? Number(pAddress.latitude) : null,
        longitude: pAddress.longitude != null ? Number(pAddress.longitude) : null,
      },
    };

    // Montant imposé par le serveur, jamais lu depuis le client.
    amount = feeXof;
    if (walletDeduction != null) {
      walletDeduction = Math.min(Number(walletDeduction), amount);
    }
  }

  try {
    // =============================================
    // CAS 1 : Paiement 100% wallet → finalisation immédiate
    // =============================================
    if (paymentMethod === "wallet") {
      if (type === "boost") {
        const reference = "TX-BST-" + Date.now();

        await finalizeBoost({
          userId: userId,
          productId: productId,
          walletDeduction: Number(amount),
          transactionRef: reference,
        });

        return res.status(200).json({
          success: true,
          data: {
            reference: reference,
            status: "completed",
            completed: true,
          },
        });
      }

      if (type === "boostpack") {
        const reference = "TX-BSTP-" + Date.now();

        await finalizeBoostPack({
          userId: userId,
          quantity: quantity,
          walletDeduction: Number(amount),
          transactionRef: reference,
        });

        return res.status(200).json({
          success: true,
          data: {
            reference: reference,
            status: "completed",
            completed: true,
          },
        });
      }

      if (type === "pickup") {
        const reference = "TX-PKP-" + Date.now();

        await finalizePickup({
          userId: userId,
          parcelCode: pickupContext.parcelCode,
          walletDeduction: Number(amount),
          feeXof: pickupContext.feeXof,
          pickupContact: pickupContext.contact,
          pickupAddress: pickupContext.address,
          transactionRef: reference,
        });

        return res.status(200).json({
          success: true,
          data: {
            reference: reference,
            status: "completed",
            completed: true,
          },
        });
      }

      const reference = "TX-WLT-" + Date.now();

      await finalizePurchase({
        buyerId: userId,
        sellerId: sellerId,
        productId: productId,
        productPrice: productPrice ? Number(productPrice) : Number(amount),
        walletDeduction: Number(amount), // Pour le wallet-only, on débite le montant total
        transactionRef: reference,
        paymentMethod: "wallet",
        totalAmount: Number(amount),
        delivery: deliveryChoice,
      });

      return res.status(200).json({
        success: true,
        data: {
          reference: reference,
          status: "completed",
          completed: true,
        },
      });
    }

    // =============================================
    // CAS 2 : Paiement externe (tmoney/flooz/carte) ou mixte (wallet + externe)
    // → Appel GeniusPay, la finalisation se fera via confirmPayment ou webhook
    // =============================================

    // 1. Construire le corps de la requête GeniusPay
    const requestBody = {
      amount: Number(amount),
      currency: "XOF",
      // Imposée, pour ne pas laisser choisir un opérateur indisponible ici —
      // et pour prendre la moins chère qui convienne.
      payment_method: passerellePour(paymentMethod),
      description: description || (type === "purchase" ? "Achat article Ablony" : type === "boost" ? "Boost produit Ablony" : type === "boostpack" ? "Lot de boosts Ablony" : type === "pickup" ? "Ramassage à domicile Ablony" : "Recharge portefeuille Ablony"),
      success_url: "https://geniuspaywebhook-mahukqtfea-uc.a.run.app/success",
      error_url: "https://geniuspaywebhook-mahukqtfea-uc.a.run.app/cancel",
      metadata: {
        type: type || "recharge",
        productId: productId || null,
        sellerId: sellerId || null,
        buyerId: userId,
      },
    };

    // 2. Configurer le client si fourni
    if (phone || name || email) {
      requestBody.customer = {};
      if (phone) {
        requestBody.customer.phone = phone;
        requestBody.customer.country = "TG";
      }
      if (name) requestBody.customer.name = name;
      if (email) requestBody.customer.email = email;
    }

    // 3. Effectuer la requête vers l'API GeniusPay
    const response = await fetch(`${GENIUSPAY_CONFIG.BASE_URL}/payments`, {
      method: "POST",
      headers: {
        "X-API-Key": GENIUSPAY_CONFIG.API_KEY,
        "X-API-Secret": GENIUSPAY_CONFIG.API_SECRET,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    });

    const result = await response.json();

    console.log("[GeniusPay] Réponse brute complète:", JSON.stringify(result, null, 2));

    if (!response.ok || !result.success) {
      return res.status(response.status || 500).json({
        success: false,
        error: result.error || {message: "Erreur lors de l'appel à GeniusPay"},
      });
    }

    // 4. Enregistrer la transaction dans Firestore sous le statut 'pending'
    const transactionData = {
      reference: result.data.reference,
      geniusPayId: result.data.id,
      userId: userId,
      amount: Number(amount),
      paymentMethod: paymentMethod,
      status: "pending",
      type: type || "recharge",
      productId: productId || null,
      sellerId: sellerId || null,
      productPrice: productPrice ? Number(productPrice) : null,
      walletDeduction: walletDeduction ? Number(walletDeduction) : null,
      // Nombre de crédits achetés, conservé sur la transaction pour la
      // finalisation asynchrone (confirmPayment / webhook).
      quantity: type === "boostpack" ? Number(quantity) : null,
      // Conservée sur la transaction, et non gardée en mémoire : la
      // finalisation arrive par `confirmPayment` ou par le rappel de
      // GeniusPay, où le corps de la requête d'origine n'existe plus.
      delivery: deliveryChoice,
      // Idem pour le ramassage : tout ce dont la finalisation asynchrone a
      // besoin (code colis, frais, contact + adresse du vendeur).
      pickup: pickupContext,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("transactions").doc(result.data.reference).set(transactionData);

    // 5. Renvoyer la réponse à l'application
    const paymentUrl = result.data.checkout_url ||
      result.data.payment_url ||
      result.data.redirect_url ||
      result.data.url ||
      null;

    console.log("[GeniusPay] URL finale utilisée:", paymentUrl);

    return res.status(201).json({
      success: true,
      data: {
        reference: result.data.reference,
        status: result.data.status,
        paymentUrl: paymentUrl,
      },
    });
  } catch (error) {
    console.error("Erreur initiatePayment:", error);
    return res.status(500).json({
      success: false,
      error: {message: error.message || "Erreur interne du serveur lors de l'initiation du paiement"},
    });
  }
});

// ============================================================================
// 2. CONFIRMER UN PAIEMENT (appelé par le client après retour WebView)
// ============================================================================

/**
 * Endpoint appelé par l'application Flutter après que la WebView de paiement
 * a redirigé vers l'URL de succès.
 * Vérifie le statut auprès de GeniusPay, puis finalise la transaction.
 */
exports.confirmPayment = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.status(204).send("");
    return;
  }

  const {reference} = req.body;

  if (!reference) {
    return res.status(400).json({
      success: false,
      error: {message: "Paramètre requis manquant : reference"},
    });
  }

  try {
    // 1. Récupérer la transaction dans Firestore
    const txSnapshot = await db.collection("transactions").doc(reference).get();
    if (!txSnapshot.exists) {
      return res.status(404).json({
        success: false,
        error: {message: `Transaction ${reference} introuvable`},
      });
    }

    const transaction = txSnapshot.data();

    // Si déjà complétée, retourner directement succès (idempotence)
    if (transaction.status === "completed") {
      return res.status(200).json({
        success: true,
        data: {status: "completed", message: "Transaction déjà complétée"},
      });
    }

    // 2. Vérifier le statut auprès de GeniusPay
    const gpResponse = await fetch(`${GENIUSPAY_CONFIG.BASE_URL}/payments/${reference}`, {
      method: "GET",
      headers: {
        "X-API-Key": GENIUSPAY_CONFIG.API_KEY,
        "X-API-Secret": GENIUSPAY_CONFIG.API_SECRET,
        "Content-Type": "application/json",
      },
    });

    const gpResult = await gpResponse.json();
    console.log("[confirmPayment] Statut GeniusPay:", JSON.stringify(gpResult, null, 2));

    const gpStatus = gpResult.data?.status;

    // Si le paiement n'est pas confirmé par GeniusPay, on refuse
    if (gpStatus !== "completed" && gpStatus !== "success" && gpStatus !== "successful") {
      // En bac à sable, le statut peut être nul : on tolère, pour pouvoir
      // tester le parcours de bout en bout. En production, jamais — sans quoi
      // une référence bien nommée validerait un paiement qui n'a pas eu lieu.
      const isSandbox = MODE_BAC_A_SABLE && reference.startsWith("SANDBOX_");
      if (!isSandbox) {
        return res.status(400).json({
          success: false,
          error: {message: `Paiement non confirmé par GeniusPay (statut: ${gpStatus})`},
        });
      }
      console.log(`[confirmPayment] Sandbox détecté, on procède malgré le statut: ${gpStatus}`);
    }

    // 3. Finaliser selon le type de transaction
    if (transaction.type === "purchase") {
      const productPrice = Number(transaction.productPrice || transaction.amount);
      const walletDeduction = Number(transaction.walletDeduction || 0);

      await finalizePurchase({
        buyerId: transaction.userId,
        sellerId: transaction.sellerId,
        productId: transaction.productId,
        productPrice: productPrice,
        walletDeduction: walletDeduction,
        transactionRef: reference,
        paymentMethod: transaction.paymentMethod,
        totalAmount: Number(transaction.amount),
        delivery: transaction.delivery || null,
      });
    } else if (transaction.type === "boost") {
      await finalizeBoost({
        userId: transaction.userId,
        productId: transaction.productId,
        walletDeduction: Number(transaction.walletDeduction || 0),
        transactionRef: reference,
      });
    } else if (transaction.type === "boostpack") {
      await finalizeBoostPack({
        userId: transaction.userId,
        quantity: Number(transaction.quantity || 1),
        walletDeduction: Number(transaction.walletDeduction || 0),
        transactionRef: reference,
      });
    } else if (transaction.type === "pickup") {
      const pk = transaction.pickup || {};
      await finalizePickup({
        userId: transaction.userId,
        parcelCode: pk.parcelCode,
        walletDeduction: Number(transaction.walletDeduction || 0),
        feeXof: Number(pk.feeXof || transaction.amount || 0),
        pickupContact: pk.contact || null,
        pickupAddress: pk.address || null,
        transactionRef: reference,
      });
    } else {
      // Recharge de portefeuille
      await finalizeRecharge(transaction.userId, Number(transaction.amount), reference);
    }

    return res.status(200).json({
      success: true,
      data: {status: "completed"},
    });
  } catch (error) {
    console.error("Erreur confirmPayment:", error);
    return res.status(500).json({
      success: false,
      error: {message: error.message || "Erreur lors de la confirmation du paiement"},
    });
  }
});

// ============================================================================
// FONCTION UTILITAIRE : Finalisation d'une recharge
// ============================================================================

/**
 * Crédite le availableAmount de l'utilisateur (recharge de portefeuille).
 */
async function finalizeRecharge(userId, amount, transactionRef) {
  const userRef = db.collection("users").doc(userId);
  const txDocRef = db.collection("transactions").doc(transactionRef);

  await db.runTransaction(async (dbTx) => {
    // Vérifier idempotence
    const txDoc = await dbTx.get(txDocRef);
    if (txDoc.exists && txDoc.data().status === "completed") {
      console.log(`Recharge ${transactionRef} déjà complétée, ignorée.`);
      return;
    }

    const userDoc = await dbTx.get(userRef);
    if (!userDoc.exists) {
      throw new Error(`Utilisateur introuvable : ${userId}`);
    }

    const userData = userDoc.data();
    const currentWallet = userData.wallet || {};
    const currentAvailable = Number(currentWallet.availableAmount || 0);

    // Créditer le solde disponible
    dbTx.update(userRef, {
      wallet: buildWalletUpdate(currentWallet, {
        availableAmount: currentAvailable + amount,
      }),
    });

    // Mettre à jour la transaction
    dbTx.update(txDocRef, {
      status: "completed",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  console.log(`✅ Recharge réussie de ${amount} FCFA pour l'utilisateur ${userId}`);
}

// ============================================================================
// 3. WEBHOOK DE GENIUSPAY (backup serveur-à-serveur)
// ============================================================================

exports.geniusPayWebhook = onRequest(async (req, res) => {
  const signature = req.headers["x-webhook-signature"];
  const timestamp = req.headers["x-webhook-timestamp"];
  const event = req.headers["x-webhook-event"];

  if (!signature || !timestamp || !event) {
    return res.status(400).json({success: false, error: "Headers de sécurité manquants"});
  }

  const payload = req.body;
  const rawBody = req.rawBody ? req.rawBody.toString("utf8") : JSON.stringify(payload);

  // Vérifier la signature si le secret est configuré
  if (GENIUSPAY_CONFIG.WEBHOOK_SECRET && GENIUSPAY_CONFIG.WEBHOOK_SECRET !== "whsec_votre_secret_webhook") {
    const signatureData = timestamp + "." + rawBody;
    const expectedSignature = crypto
        .createHmac("sha256", GENIUSPAY_CONFIG.WEBHOOK_SECRET)
        .update(signatureData)
        .digest("hex");

    if (signature !== expectedSignature) {
      console.warn("Signature webhook invalide !");
      return res.status(401).json({success: false, error: "Signature invalide"});
    }
  }

  try {
    const transactionRef = payload.data?.reference;
    const status = payload.data?.status;

    // Ping de test
    if (!transactionRef || transactionRef.startsWith("test") || event === "ping") {
      console.log("Requête de test ou ping webhook reçu.");
      return res.status(200).json({
        success: true,
        message: "Webhook de test ou de ping reçu avec succès",
      });
    }

    // Récupérer la transaction dans Firestore
    const txSnapshot = await db.collection("transactions").doc(transactionRef).get();
    if (!txSnapshot.exists) {
      console.warn(`Transaction introuvable dans Firestore : ${transactionRef}`);
      return res.status(200).json({
        success: true,
        message: `Transaction ${transactionRef} introuvable, ignorée`,
      });
    }

    const transaction = txSnapshot.data();

    // Si la transaction est déjà traitée, on renvoie simplement 200
    if (transaction.status === "completed" || transaction.status === "failed") {
      return res.status(200).json({success: true, message: "Transaction déjà traitée"});
    }

    // ============ PAIEMENT RÉUSSI ============
    if (event === "payment.success" && status === "completed") {
      const amount = Number(transaction.amount);

      if (transaction.type === "purchase") {
        // Utiliser la fonction partagée finalizePurchase
        const productPrice = Number(transaction.productPrice || amount);
        const walletDeduction = Number(transaction.walletDeduction || 0);

        await finalizePurchase({
          buyerId: transaction.userId,
          sellerId: transaction.sellerId,
          productId: transaction.productId,
          productPrice: productPrice,
          walletDeduction: walletDeduction,
          transactionRef: transactionRef,
          paymentMethod: transaction.paymentMethod,
          totalAmount: amount,
          delivery: transaction.delivery || null,
        });
      } else if (transaction.type === "boost") {
        // Utiliser la fonction partagée finalizeBoost
        await finalizeBoost({
          userId: transaction.userId,
          productId: transaction.productId,
          walletDeduction: Number(transaction.walletDeduction || 0),
          transactionRef: transactionRef,
        });
      } else if (transaction.type === "boostpack") {
        await finalizeBoostPack({
          userId: transaction.userId,
          quantity: Number(transaction.quantity || 1),
          walletDeduction: Number(transaction.walletDeduction || 0),
          transactionRef: transactionRef,
        });
      } else if (transaction.type === "pickup") {
        const pk = transaction.pickup || {};
        await finalizePickup({
          userId: transaction.userId,
          parcelCode: pk.parcelCode,
          walletDeduction: Number(transaction.walletDeduction || 0),
          feeXof: Number(pk.feeXof || transaction.amount || 0),
          pickupContact: pk.contact || null,
          pickupAddress: pk.address || null,
          transactionRef: transactionRef,
        });
      } else {
        // Utiliser la fonction partagée finalizeRecharge
        await finalizeRecharge(transaction.userId, amount, transactionRef);
      }

    // ============ PAIEMENT ÉCHOUÉ ============
    } else if (event === "payment.failed" || status === "failed" || status === "expired") {
      await db.collection("transactions").doc(transactionRef).update({
        status: "failed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`❌ Échec de la transaction ${transactionRef}`);
    }

    return res.status(200).json({success: true});
  } catch (error) {
    console.error("Erreur traitement Webhook GeniusPay:", error);
    return res.status(500).json({success: false, error: error.message});
  }
});

// ============================================================================
// TRIGGER : NOUVEAU PRODUIT PUBLIÉ → NOTIFIER LES ABONNÉS DU VENDEUR
// ============================================================================

exports.notifyFollowersOnNewProduct = onDocumentCreated("products/{productId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const product = snapshot.data();
  const productId = event.params.productId;
  const sellerId = product.sellerId;
  if (!sellerId) return;

  const followersSnapshot = await db.collection("follows")
      .where("followedId", "==", sellerId)
      .get();

  if (followersSnapshot.empty) return;

  const sellerDoc = await db.collection("users").doc(sellerId).get();
  const sellerUsername = sellerDoc.exists ?
    (sellerDoc.data().username || "Un vendeur que vous suivez") :
    "Un vendeur que vous suivez";

  const title = "Nouvel article";
  const body = `${sellerUsername} vient de publier "${product.title || "un nouvel article"}".`;

  const batch = db.batch();
  followersSnapshot.docs.forEach((followDoc) => {
    const followerId = followDoc.data().followerId;
    if (!followerId) return;
    const notifRef = db.collection("notifications").doc(`${productId}_follow_${followerId}`);
    batch.set(notifRef, {
      userId: followerId,
      type: "new_product_from_followed",
      title,
      body,
      data: {productId, sellerId},
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();

  await Promise.all(
      followersSnapshot.docs.map((followDoc) => {
        const followerId = followDoc.data().followerId;
        if (!followerId) return Promise.resolve();
        return sendPushToUser(
            followerId,
            {title, body},
            {type: "new_product_from_followed", productId, sellerId},
        ).catch((err) => console.error(`⚠️ Push new_product vers ${followerId} échoué:`, err));
      }),
  );

  console.log(`🔔 ${followersSnapshot.size} abonné(s) notifié(s) pour le nouveau produit ${productId} du vendeur ${sellerId}`);
});

// ============================================================================
// TRIGGER : NOUVEL AVIS → RECALCUL DE LA NOTE MOYENNE DU VENDEUR
// ============================================================================

exports.onReviewCreated = onDocumentCreated("reviews/{reviewId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const review = snapshot.data();
  const sellerId = review.sellerId;
  const rating = Number(review.rating);
  if (!sellerId || !rating) return;

  const sellerRef = db.collection("users").doc(sellerId);

  await db.runTransaction(async (tx) => {
    const sellerDoc = await tx.get(sellerRef);
    if (!sellerDoc.exists) return;

    const sellerData = sellerDoc.data();
    const currentCount = Number(sellerData.reviewsCount || 0);
    const currentRating = Number(sellerData.rating || 0);
    const newCount = currentCount + 1;
    const newRating = ((currentRating * currentCount) + rating) / newCount;

    tx.update(sellerRef, {
      rating: Math.round(newRating * 10) / 10,
      reviewsCount: newCount,
    });
  });

  console.log(`⭐ Note moyenne recalculée pour le vendeur ${sellerId} (avis ${event.params.reviewId})`);
});

// ============================================================================
// CONFIRMATION DE RÉCEPTION (l'acheteur confirme depuis sa commande)
// ============================================================================

/**
 * L'acheteur confirme avoir reçu son article, ce qui débloque le paiement :
 * pendingAmount du vendeur → availableAmount.
 *
 * Il n'y a rien à scanner. La version précédente faisait scanner à l'acheteur
 * un QR affiché sur l'écran du vendeur — un geste de remise en main propre,
 * alors qu'Ablony achemine lui-même les colis : les deux personnes ne se
 * rencontrent jamais.
 *
 * Authentification requise via un ID token Firebase (header
 * `Authorization: Bearer <token>`), pour garantir que seul le vrai acheteur
 * peut déclencher le déblocage.
 *
 * **Limite connue de cette pile.** Ici, la confirmation de l'acheteur reste le
 * seul signal : il n'existe pas encore d'application agent pour scanner le
 * colis aux étapes du transport. Tant que c'est le cas, un acheteur qui ne
 * confirme jamais bloque les fonds du vendeur. La libération automatique
 * suppose une remise **constatée par un tiers** — elle arrive avec le service
 * `delivery` du nouveau backend, qui enregistre chaque scan d'agent.
 */
exports.confirmDelivery = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.status(204).send("");
    return;
  }

  const authHeader = req.headers.authorization || "";
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!idToken) {
    return res.status(401).json({success: false, error: {message: "Authentification requise"}});
  }

  let decodedToken;
  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    return res.status(401).json({success: false, error: {message: "Token invalide"}});
  }

  const buyerId = decodedToken.uid;
  const {transactionRef: transactionRefInput} = req.body;

  if (!transactionRefInput) {
    return res.status(400).json({success: false, error: {message: "Paramètre requis manquant : transactionRef"}});
  }

  try {
    // L'acheteur confirme depuis sa commande : il n'y a rien à scanner.
    // L'ancienne version faisait scanner à l'acheteur un QR affiché par le
    // vendeur — un geste de remise en main propre, qui n'a aucun sens pour un
    // colis arrivé par point relais, les deux personnes ne se rencontrant
    // jamais. L'appartenance est vérifiée plus bas via `tx.userId`.
    const transactionRef = transactionRefInput;
    const txRef = db.collection("transactions").doc(transactionRef);

    const result = await db.runTransaction(async (dbTx) => {
      const txDoc = await dbTx.get(txRef);
      if (!txDoc.exists) throw new Error("Commande introuvable");

      const tx = txDoc.data();
      if (tx.type !== "purchase") throw new Error("Cette transaction n'est pas un achat");
      if (tx.status !== "completed") throw new Error("Cet achat n'a pas encore été finalisé");
      if (tx.userId !== buyerId) throw new Error("Vous n'êtes pas l'acheteur de cette commande");

      // Lu avant toute écriture. Sans cette ligne, un acheteur qui a ouvert un
      // litige peut confirmer la réception par mégarde — et payer le vendeur
      // qu'il conteste, sans retour possible.
      await refuserSiLitige(dbTx, transactionRef);

      if (tx.deliveryConfirmed === true) {
        return {alreadyConfirmed: true, sellerId: tx.sellerId, productId: tx.productId};
      }

      const sellerRef = db.collection("users").doc(tx.sellerId);
      const sellerDoc = await dbTx.get(sellerRef);
      if (!sellerDoc.exists) throw new Error("Vendeur introuvable");

      // Lu dans la même transaction, avant toute écriture (règle Firestore).
      const parcelQuery = await dbTx.get(
          db.collection("parcels").where("transactionRef", "==", transactionRef).limit(1),
      );
      const parcelSnap = parcelQuery.empty ? null : parcelQuery.docs[0];

      const sellerWallet = sellerDoc.data().wallet || {};
      const pending = Number(sellerWallet.pendingAmount || 0);
      const available = Number(sellerWallet.availableAmount || 0);
      const amount = Number(tx.productPrice || tx.amount);

      dbTx.update(sellerRef, {
        wallet: buildWalletUpdate(sellerWallet, {
          pendingAmount: Math.max(0, pending - amount),
          availableAmount: available + amount,
        }),
      });

      dbTx.update(txRef, {
        deliveryConfirmed: true,
        deliveryConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Le reçu (lisible par le client) reflète aussi l'état de confirmation
      dbTx.update(db.collection("receipts").doc(transactionRef), {
        deliveryConfirmed: true,
      });

      // Et le colis, pour que le suivi ne reste pas bloqué sur « en attente
      // de dépôt » alors que l'article est arrivé.
      if (parcelSnap) {
        dbTx.update(parcelSnap.ref, {
          status: "delivered",
          deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return {
        alreadyConfirmed: false,
        sellerId: tx.sellerId,
        productId: tx.productId,
        amount,
        productTitle: tx.productTitle || null,
      };
    });

    if (!result.alreadyConfirmed) {
      // `notifyUser` (et non un simple push) : le vendeur doit RETROUVER
      // l'information dans sa boîte de notifications, pas seulement la voir
      // passer. Les autres chemins de libération (litige, délai écoulé) le
      // faisaient déjà ; celui-ci, non — le vendeur n'avait aucune trace que
      // son argent venait d'être débloqué.
      try {
        const titreArticle = result.productTitle ?
          ` pour "${result.productTitle}"` : "";
        await notifyUser(
            result.sellerId,
            "Paiement débloqué",
            `L'acheteur a confirmé la réception${titreArticle}. ` +
            `${result.amount} FCFA sont désormais disponibles dans votre ` +
            `porte-monnaie.`,
            {
              type: "funds_released",
              productId: result.productId,
              transactionRef,
            },
        );
      } catch (notifyError) {
        console.error(`⚠️ Notif funds_released échouée pour ${result.sellerId}:`, notifyError);
      }
    }

    console.log(`✅ Réception confirmée pour ${transactionRef} (déjà confirmée: ${result.alreadyConfirmed})`);

    return res.status(200).json({
      success: true,
      data: {alreadyConfirmed: result.alreadyConfirmed},
    });
  } catch (error) {
    console.error("Erreur confirmDelivery:", error);
    return res.status(400).json({
      success: false,
      error: {message: error.message || "Erreur lors de la confirmation de réception"},
    });
  }
});

/**
 * Supprime le compte de l'utilisateur authentifié.
 *
 * Ce n'est pas une suppression du document `users/{uid}` : products,
 * reviews, messages, transactions, etc. référencent cet uid, et le
 * détruire casserait toutes ces relations. À la place, on remplace tout ce
 * qui permettrait de ré-identifier la personne par des valeurs génériques
 * (anonymisation), puis on supprime pour de bon le compte Firebase Auth —
 * plus aucune connexion possible ensuite, même par erreur ou par bug.
 *
 * Ce qui SURVIT à l'anonymisation (volontairement) :
 * - Les compteurs d'activité (productsCount, salesCount, rating,
 *   reviewsCount, followersCount, followingCount) : pas des données
 *   personnelles, et l'historique doit rester cohérent pour les autres
 *   utilisateurs.
 * - Les montants du wallet (availableAmount/pendingAmount) : trace
 *   comptable, ce n'est pas à cette fonction de décider quoi en faire.
 * - reviews/messages/follows/fav : toujours liés à cet uid, mais l'uid
 *   seul ne permet plus de retrouver qui était la personne.
 *
 * Ce qui CHANGE en plus de l'anonymisation :
 * - Toutes les annonces du vendeur passent en `isHidden: true` — un compte
 *   supprimé ne doit plus pouvoir vendre (cf. le check dans
 *   finalizePurchase et les filtres `isHidden` de ProductRepositoryImpl).
 */
exports.deleteAccount = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.status(204).send("");
    return;
  }

  const authHeader = req.headers.authorization || "";
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!idToken) {
    return res.status(401).json({success: false, error: {message: "Authentification requise"}});
  }

  let decodedToken;
  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    return res.status(401).json({success: false, error: {message: "Token invalide"}});
  }

  const uid = decodedToken.uid;

  try {
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      return res.status(404).json({success: false, error: {message: "Compte introuvable"}});
    }
    const userData = userDoc.data();
    const anonymizedUsername = `compte_supprime_${uid.substring(0, 8)}`;

    await db.runTransaction(async (tx) => {
      tx.update(userRef, {
        email: `compte-supprime-${uid}@ablony.deleted`,
        username: anonymizedUsername,
        displayName: "Compte Supprimé",
        photoUrl: admin.firestore.FieldValue.delete(),
        phoneNumber: "0",
        city: admin.firestore.FieldValue.delete(),
        providerId: admin.firestore.FieldValue.delete(),
        marketingEmailsEnabled: false,
        isActive: false,
        fcmTokens: [],
        wallet: buildWalletUpdate(userData.wallet || {}, {
          firstName: "Supprimé",
          lastName: "Compte",
          nationality: null,
          birthDate: null,
          isActivated: false,
        }),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Libère l'ancien pseudo (redevient disponible pour un autre
      // utilisateur) et réserve le nouveau — même logique que
      // AuthRepositoryImpl.updateUserProfile côté client.
      if (userData.username) {
        tx.delete(db.collection("usernames").doc(userData.username));
      }
      tx.set(db.collection("usernames").doc(anonymizedUsername), {
        userId: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Les conversations dénormalisent nom/avatar au moment de leur création
    // (participantDetails) et ne sont jamais resynchronisées ensuite —
    // sans ce nettoyage, l'autre participant verrait encore le vrai nom/
    // avatar dans l'historique des messages malgré l'anonymisation.
    const conversationsSnapshot = await db
        .collection("conversations")
        .where("participants", "array-contains", uid)
        .get();

    let batch = db.batch();
    let opsInBatch = 0;
    for (const doc of conversationsSnapshot.docs) {
      batch.update(doc.ref, {
        [`participantDetails.${uid}.name`]: "Compte Supprimé",
        [`participantDetails.${uid}.avatar`]: admin.firestore.FieldValue.delete(),
      });
      opsInBatch++;
      if (opsInBatch >= 450) {
        await batch.commit();
        batch = db.batch();
        opsInBatch = 0;
      }
    }
    if (opsInBatch > 0) {
      await batch.commit();
    }

    // Masque toutes les annonces du vendeur supprimé : `isHidden` est déjà
    // filtré par toutes les requêtes de listing (accueil, catégorie,
    // recherche, boost — cf. ProductRepositoryImpl côté client) et bloque
    // aussi l'achat côté serveur (cf. le check dans finalizePurchase
    // ci-dessus), exactement comme pour un produit déjà vendu. Un compte
    // supprimé ne pouvant jamais être republié, pas besoin de distinguer ce
    // masquage de celui, réversible, que le vendeur déclenche lui-même.
    const productsSnapshot = await db
        .collection("products")
        .where("sellerId", "==", uid)
        .get();

    let productsBatch = db.batch();
    let productsOpsInBatch = 0;
    for (const doc of productsSnapshot.docs) {
      // Une annonce déjà vendue reste vendue : un acheteur attend son colis,
      // et l'archiver sous ses pieds lui ferait perdre la trace de sa
      // commande. Pour les autres, `status` autant que le booléen hérité.
      const dejaVendue = doc.data().status === "sold" || doc.data().isSold;
      productsBatch.update(doc.ref, {
        ...(dejaVendue ? {} : {status: "archived"}),
        isHidden: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      productsOpsInBatch++;
      if (productsOpsInBatch >= 450) {
        await productsBatch.commit();
        productsBatch = db.batch();
        productsOpsInBatch = 0;
      }
    }
    if (productsOpsInBatch > 0) {
      await productsBatch.commit();
    }

    // Dernière étape, volontairement : si tout ce qui précède a réussi, le
    // profil est déjà anonymisé avant même que l'accès ne soit révoqué. En
    // cas d'échec ici, l'utilisateur garde un accès (dégradé) à son propre
    // compte et peut simplement réessayer plus tard.
    await admin.auth().deleteUser(uid);

    console.log(`✅ Compte ${uid} supprimé et anonymisé`);
    return res.status(200).json({success: true});
  } catch (error) {
    console.error("Erreur deleteAccount:", error);
    return res.status(400).json({
      success: false,
      error: {message: error.message || "Erreur lors de la suppression du compte"},
    });
  }
});

// ============================================================================
// LOGISTIQUE — SCANS DU PERSONNEL
// ============================================================================
//
// Le code du colis est imprimé sur le carton : tout le monde peut le lire.
// Ce n'est donc pas lui qui autorise, mais **celui qui scanne**. Un acheteur
// qui photographie une étiquette n'obtient rien ; un agent qui scanne le même
// code fait avancer le colis.
//
// Le rôle est lu ici, côté serveur, dans `users/{uid}.role` — que les règles
// Firestore empêchent son titulaire de modifier. Sans cette barrière,
// n'importe qui se déclarerait agent, marquerait ses propres ventes comme
// remises et se ferait payer sans avoir rien envoyé.

/**
 * Les étapes possibles, et depuis quels états.
 *
 * C'est cette table qui fait tenir le séquestre : un colis ne peut pas être
 * « remis » sans avoir été « déposé », et c'est pour cela que le paiement
 * peut se fier à un scan.
 */
const PARCEL_TRANSITIONS = {
  dropped_off: ["awaiting_dropoff"],
  in_transit: ["dropped_off", "ready_for_pickup"],
  arrived: ["in_transit"],
  out_for_delivery: ["in_transit", "dropped_off"],
  delivered: ["ready_for_pickup", "out_for_delivery"],
  returned: ["ready_for_pickup", "in_transit", "out_for_delivery"],
  lost: ["dropped_off", "in_transit", "ready_for_pickup", "out_for_delivery"],
};

/**
 * L'état dans lequel une étape laisse le colis.
 */
const PARCEL_RESULTING_STATUS = {
  dropped_off: "dropped_off",
  in_transit: "in_transit",
  arrived: "ready_for_pickup",
  out_for_delivery: "out_for_delivery",
  delivered: "delivered",
  returned: "returned",
  lost: "lost",
};

/**
 * Prépare une réponse CORS et vérifie le jeton de l'appelant.
 *
 * Renvoie `null` après avoir répondu lui-même si l'appel n'aboutit pas :
 * l'appelant n'a plus qu'à sortir.
 *
 * @param {Object} req La requête HTTP.
 * @param {Object} res La réponse, à laquelle on ajoute les en-têtes CORS.
 * @param {Object} [options] Options.
 * @param {string} [options.method] La méthode annoncée dans la préflight.
 * @return {Promise<Object|null>} Le jeton décodé, ou `null` si l'appel a
 *   déjà reçu sa réponse.
 */
async function authenticate(req, res, {method = "POST"} = {}) {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", `${method}, OPTIONS`);
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.status(204).send("");
    return null;
  }

  const header = req.headers.authorization || "";
  const idToken = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!idToken) {
    res.status(401).json({
      success: false,
      error: {message: "Authentification requise"},
    });
    return null;
  }

  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    res.status(401).json({success: false, error: {message: "Token invalide"}});
    return null;
  }
}

/**
 * Le rôle de quelqu'un, lu en base et jamais dans le jeton.
 *
 * Firebase sait porter un rôle dans les *custom claims*, ce qui éviterait
 * cette lecture — mais un rôle retiré continuerait alors d'agir jusqu'à
 * l'expiration du jeton. À notre échelle, une lecture par scan est un prix
 * dérisoire pour une révocation immédiate.
 *
 * @param {string} uid L'identifiant de la personne.
 * @return {Promise<string>} `member`, `agent` ou `admin`.
 */
async function roleOf(uid) {
  const snap = await db.collection("users").doc(uid).get();
  return snap.exists ? (snap.data().role || "member") : "member";
}

const isStaff = (role) => role === "agent" || role === "admin";

/**
 * Écrit une notification et envoie le push correspondant.
 *
 * Les deux vont ensemble : le push se lit dans l'instant et disparaît, la
 * notification reste consultable. Une remise annoncée seulement par push
 * serait perdue pour qui avait son téléphone éteint.
 *
 * @param {string} uid Le destinataire.
 * @param {string} title Le titre, court.
 * @param {string} body Le corps du message.
 * @param {Object} data Les données jointes ; `data.type` sert au routage.
 * @return {Promise<void>}
 */
async function notifyUser(uid, title, body, data) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.collection("notifications").doc().set({
    userId: uid,
    type: data.type,
    title,
    body,
    data,
    read: false,
    createdAt: now,
  });
  // Le push est accessoire : son échec ne doit pas faire échouer le scan,
  // qui est le fait constaté.
  try {
    await sendPushToUser(uid, {title, body}, data);
  } catch (error) {
    console.error(`Push non envoyé à ${uid} :`, error.message);
  }
}

/**
 * Retrouve un colis par le code imprimé sur son étiquette.
 *
 * @param {string} code Le code, tel qu'il a été scanné ou saisi.
 * @return {Promise<Object|null>} Le document, ou `null` s'il n'existe pas.
 */
async function parcelByCode(code) {
  const id = String(code).trim().toUpperCase();
  const snap = await db.collection("parcels").doc(id).get();
  return snap.exists ? snap : null;
}

/**
 * Résout un code scanné, pour le personnel.
 *
 * La vue est volontairement réduite : de quoi acheminer le colis, rien de
 * plus. Ni prix, ni identité complète — un agent n'a pas à savoir combien
 * vaut ce qu'il transporte.
 */
exports.resolveParcel = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  const role = await roleOf(decoded.uid);
  if (!isStaff(role)) {
    return res.status(403).json({
      success: false,
      error: {message: "Cette action est réservée au personnel Ablony"},
    });
  }

  const code = req.body?.code || req.query?.code;
  if (!code) {
    return res.status(400).json({
      success: false,
      error: {message: "Paramètre requis manquant : code"},
    });
  }

  const snap = await parcelByCode(code);
  if (!snap) {
    return res.status(404).json({
      success: false,
      error: {message: "Ce colis est introuvable"},
    });
  }
  const parcel = snap.data();

  // La destination : le point relais est une adresse publique, le domicile
  // ne l'est pas — il vit dans un document à part, que seul l'acheteur peut
  // lire depuis l'application. L'agent l'obtient ici parce que c'est
  // précisément son travail de s'y rendre.
  let destination = null;

  // Le contact de l'acheteur (nom + téléphone) vit dans le document privé, pour
  // les DEUX modes : l'agent doit pouvoir le joindre qu'il livre à domicile ou
  // qu'un retrait en relais traîne. Il n'est jamais lisible du vendeur.
  const privateDoc = await snap.ref
      .collection("private")
      .doc("destination")
      .get();
  const priv = privateDoc.exists ? privateDoc.data() : null;
  let contact = null;
  if (priv && (priv.contactName || priv.contactPhone)) {
    contact = {
      name: priv.contactName || null,
      phone: priv.contactPhone || null,
    };
  }

  if (parcel.method === "relay" && parcel.relayPointId) {
    const relay = await db
        .collection("relayPoints")
        .doc(parcel.relayPointId)
        .get();
    if (relay.exists) {
      const r = relay.data();
      destination = {
        kind: "relay",
        name: r.name,
        address: r.address,
        city: r.city,
      };
    }
  } else if (priv && priv.address) {
    destination = {kind: "home", ...priv.address};
  }

  // Ramassage à domicile : si le vendeur a payé pour qu'on vienne chercher le
  // colis chez lui, l'agent a besoin de SON adresse et de SON téléphone. Rangés
  // dans un sous-document privé distinct de celui de l'acheteur.
  let pickup = null;
  if (parcel.pickupRequested === true) {
    const pickupDoc = await snap.ref
        .collection("private")
        .doc("pickup")
        .get();
    const pk = pickupDoc.exists ? pickupDoc.data() : null;
    pickup = {
      requested: true,
      feeXof: Number.isFinite(parcel.pickupFeeXof) ? parcel.pickupFeeXof : null,
      contactName: pk ? (pk.contactName || null) : null,
      contactPhone: pk ? (pk.contactPhone || null) : null,
      address: pk ? (pk.address || null) : null,
    };
  }

  const nextSteps = Object.keys(PARCEL_TRANSITIONS).filter(
      (step) => PARCEL_TRANSITIONS[step].includes(parcel.status),
  );

  return res.json({
    success: true,
    data: {
      code: parcel.code,
      status: parcel.status,
      method: parcel.method,
      productTitle: parcel.productTitle,
      destination,
      contact,
      pickup,
      nextSteps,
    },
  });
});

/**
 * Enregistre une étape constatée par un agent.
 *
 * Chaque étape est datée et attribuée à celui qui l'a scannée. C'est cet
 * enregistrement — et lui seul — qui fait d'Ablony un tiers de confiance :
 * ni l'acheteur ni le vendeur ne peuvent le produire, et aucun des deux n'a
 * donc à croire l'autre sur parole.
 */
exports.recordParcelCheckpoint = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  const role = await roleOf(decoded.uid);
  if (!isStaff(role)) {
    return res.status(403).json({
      success: false,
      error: {message: "Cette action est réservée au personnel Ablony"},
    });
  }

  const {code, kind, relayPointId, note} = req.body || {};
  if (!code || !kind) {
    return res.status(400).json({
      success: false,
      error: {message: "Paramètres requis manquants : code, kind"},
    });
  }
  if (!PARCEL_TRANSITIONS[kind]) {
    return res.status(400).json({
      success: false,
      error: {message: `Étape inconnue : ${kind}`},
    });
  }

  const parcelRef = db
      .collection("parcels")
      .doc(String(code).trim().toUpperCase());

  try {
    const result = await db.runTransaction(async (dbTx) => {
      const snap = await dbTx.get(parcelRef);
      if (!snap.exists) throw new Error("Ce colis est introuvable");

      const parcel = snap.data();
      if (!PARCEL_TRANSITIONS[kind].includes(parcel.status)) {
        throw new Error(
            `Un colis « ${parcel.status} » ne peut pas passer à « ${kind} »`,
        );
      }

      const now = admin.firestore.FieldValue.serverTimestamp();
      const resultingStatus = PARCEL_RESULTING_STATUS[kind];
      const update = {status: resultingStatus, updatedAt: now};
      if (kind === "dropped_off") {
        update.droppedOffAt = now;
        update.originRelayPointId = relayPointId || null;
      }
      if (kind === "delivered") update.deliveredAt = now;
      // Horodatage par étape, écrit sur le colis lui-même (que l'acheteur et le
      // vendeur lisent déjà) : c'est ce qui alimente la frise de suivi in-app,
      // sans exposer la sous-collection checkpoints.
      update[`stepsAt.${resultingStatus}`] = now;

      dbTx.update(parcelRef, update);
      dbTx.set(parcelRef.collection("checkpoints").doc(), {
        kind,
        agentId: decoded.uid,
        relayPointId: relayPointId || null,
        note: note || null,
        createdAt: now,
      });

      return {
        transactionRef: parcel.transactionRef,
        status: update.status,
        parcel,
      };
    });

    // Le dépôt marque la fin de l'obligation du vendeur : à partir de là, le
    // colis est sous notre garde, et un incident ne doit plus le pénaliser.
    if (kind === "dropped_off") {
      await notifyUser(
          result.parcel.buyerId,
          "Votre colis est parti",
          `« ${result.parcel.productTitle} » a été déposé et voyage vers vous.`,
          {type: "parcel_on_its_way", parcelCode: result.parcel.code},
      );
    }
    if (kind === "arrived") {
      await notifyUser(
          result.parcel.buyerId,
          "Votre colis vous attend",
          `« ${result.parcel.productTitle} » est arrivé en point relais.`,
          {type: "parcel_ready_for_pickup", parcelCode: result.parcel.code},
      );
    }
    if (kind === "delivered") {
      await notifyUser(
          result.parcel.buyerId,
          "Colis remis",
          `« ${result.parcel.productTitle} » vous a été remis. ` +
          `Un souci ? Signalez-le sans tarder.`,
          {
            type: "parcel_delivered",
            parcelCode: result.parcel.code,
            transactionRef: result.transactionRef,
          },
      );
    }

    return res.json({success: true, data: {status: result.status}});
  } catch (error) {
    return res
        .status(409)
        .json({success: false, error: {message: error.message}});
  }
});

/**
 * L'acheteur atteste avoir le colis en main, en scannant son étiquette.
 *
 * **Ce geste ne libère pas l'argent**, et c'est délibéré. Un acheteur qui
 * récupère son colis au comptoir scannerait devant l'agent, parfois à sa
 * demande, avant même d'avoir ouvert le carton — et perdrait du même coup son
 * délai pour constater que l'article ne correspond pas. La protection
 * passerait de plusieurs jours à zéro sans que personne ne s'en aperçoive
 * avant le premier litige.
 *
 * Ce que le scan apporte : une seconde attestation, indépendante de celle de
 * l'agent, datée, et qui suppose d'avoir le colis sous les yeux. En cas de
 * contestation, « l'agent a constaté la remise **et** l'acheteur a scanné le
 * carton » pèse bien plus lourd que l'un des deux seul.
 *
 * La libération, elle, reste un choix explicite : `confirmDelivery`.
 */
exports.attestParcelReceipt = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  const {code} = req.body || {};
  if (!code) {
    return res.status(400).json({
      success: false,
      error: {message: "Paramètre requis manquant : code"},
    });
  }

  const snap = await parcelByCode(code);
  if (!snap) {
    return res.status(404).json({
      success: false,
      error: {message: "Ce colis est introuvable"},
    });
  }

  const parcel = snap.data();
  // « Introuvable », et non « interdit » : un refus explicite confirmerait
  // l'existence de la vente à qui scanne un carton qui ne le concerne pas.
  if (parcel.buyerId !== decoded.uid) {
    return res.status(404).json({
      success: false,
      error: {message: "Ce colis est introuvable"},
    });
  }

  if (!parcel.buyerScannedAt) {
    await snap.ref.update({
      buyerScannedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return res.json({
    success: true,
    data: {
      code: parcel.code,
      transactionRef: parcel.transactionRef,
      productTitle: parcel.productTitle,
      status: parcel.status,
      // L'application se sert de ceci pour amener vers le bon écran : la
      // décision — « tout est conforme » ou « il y a un problème » — se prend
      // là, pas ici.
      alreadySettled: parcel.status === "returned" || Boolean(parcel.settledAt),
    },
  });
});

/**
 * Les colis qui n'avancent plus, pour l'administration.
 *
 * Sans agent pour constater une remise, rien ne se libère — l'argent reste en
 * séquestre, ce qui est sûr mais bloque le vendeur. Cette file est la porte de
 * sortie : elle montre ce qui attend une décision humaine, plutôt que de
 * laisser le silence durer.
 */
exports.stuckParcels = onRequest(async (req, res) => {
  // Deux appelants, deux méthodes : l'application mobile interroge en GET,
  // la console d'administration en POST. Les deux doivent figurer dans la
  // réponse au préliminaire CORS, sinon le navigateur refuse la requête
  // avant même qu'elle parte.
  const decoded = await authenticate(req, res, {method: "GET, POST"});
  if (!decoded) return;

  if (!isStaff(await roleOf(decoded.uid))) {
    return res.status(403).json({
      success: false,
      error: {message: "Cette action est réservée au personnel Ablony"},
    });
  }

  const now = Date.now();
  const jours = (n) => new Date(now - n * 24 * 60 * 60 * 1000);

  // Trois silences différents, trois causes différentes. Les distinguer évite
  // de traiter « le vendeur n'a rien déposé » comme « notre tournée a pris du
  // retard » : la première rembourse, la seconde s'explique.
  const [jamaisDeposes, enRoute, remisNonConfirmes] = await Promise.all([
    db.collection("parcels")
        .where("status", "==", "awaiting_dropoff")
        .where("dropoffDeadline", "<=", new Date(now))
        .limit(100).get(),
    db.collection("parcels")
        .where(
            "status",
            "in",
            ["dropped_off", "in_transit", "out_for_delivery"],
        )
        .where("createdAt", "<=", jours(7))
        .limit(100).get(),
    db.collection("parcels")
        .where("status", "==", "ready_for_pickup")
        .where("createdAt", "<=", jours(7))
        .limit(100).get(),
  ]);

  const resumer = (snap, raison) => snap.docs.map((d) => {
    const p = d.data();
    return {
      code: p.code,
      transactionRef: p.transactionRef,
      productTitle: p.productTitle,
      status: p.status,
      method: p.method,
      reason: raison,
      buyerScannedAt: p.buyerScannedAt ?
        p.buyerScannedAt.toDate().toISOString() :
        null,
      createdAt: p.createdAt ? p.createdAt.toDate().toISOString() : null,
    };
  });

  return res.json({
    success: true,
    data: {
      items: [
        ...resumer(jamaisDeposes, "never_dropped_off"),
        ...resumer(enRoute, "in_transit_too_long"),
        ...resumer(remisNonConfirmes, "waiting_at_relay"),
      ],
    },
  });
});

/**
 * Les colis actuellement en circulation, pour le suivi du personnel.
 *
 * Évite d'avoir à taper un code pour un colis déjà pris en charge : l'agent
 * le retrouve dans la liste et clique dessus. Ne montre que ce qui bouge —
 * ni les colis pas encore déposés, ni ceux déjà remis. Tri par activité
 * récente, côté serveur en mémoire (pas d'index composite pour un `in`).
 */
exports.listActiveParcels = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res, {method: "GET, POST"});
  if (!decoded) return;

  if (!isStaff(await roleOf(decoded.uid))) {
    return res.status(403).json({
      success: false,
      error: {message: "Cette action est réservée au personnel Ablony"},
    });
  }

  const snap = await db.collection("parcels")
      .where(
          "status",
          "in",
          ["dropped_off", "in_transit", "ready_for_pickup", "out_for_delivery"],
      )
      .limit(100).get();

  const items = snap.docs.map((d) => {
    const p = d.data();
    return {
      code: p.code || d.id,
      productTitle: p.productTitle || "Article",
      status: p.status,
      method: p.method || "relay",
      updatedAt: p.updatedAt ? p.updatedAt.toDate().toISOString() : null,
    };
  }).sort((a, b) => (b.updatedAt || "").localeCompare(a.updatedAt || ""));

  return res.json({success: true, data: {items}});
});

/**
 * Compteurs des files d'attente admin : le travail en attente, par catégorie,
 * pour que le personnel voie d'un coup d'œil où agir sans ouvrir chaque onglet.
 * Réservé au personnel. Utilise les agrégats `count()` — une lecture facturée
 * par compteur, pas par document, donc bon marché même à volume.
 */
exports.adminCounts = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res, {method: "GET, POST"});
  if (!decoded) return;

  if (!isStaff(await roleOf(decoded.uid))) {
    return res.status(403).json({
      success: false,
      error: {message: "Cette action est réservée au personnel Ablony"},
    });
  }

  const compter = async (q) => {
    try {
      return (await q.count().get()).data().count;
    } catch (_) {
      return 0;
    }
  };

  // Ramassages en attente : colis dont le vendeur a payé un ramassage à
  // domicile et qui n'ont pas encore été collectés (toujours `awaiting_dropoff`,
  // car la collecte les fait passer à `dropped_off`). On filtre `pickupRequested`
  // en code sur les colis en attente de dépôt — évite un index composite, et ces
  // colis sont peu nombreux. `.select` limite la lecture au seul champ utile.
  const compterRamassages = async () => {
    try {
      const snap = await db.collection("parcels")
          .where("status", "==", "awaiting_dropoff")
          .select("pickupRequested")
          .limit(300)
          .get();
      return snap.docs.filter((d) => d.data().pickupRequested === true).length;
    } catch (_) {
      return 0;
    }
  };

  const [moderation, reports, withdrawals, disputes, support, pickups] =
    await Promise.all([
      compter(
          db.collection("products").where("moderationStatus", "==", "pending"),
      ),
      compter(db.collection("reports").where("status", "==", "open")),
      compter(
          db.collection("withdrawals").where("status", "==", "requested"),
      ),
      compter(db.collection("disputes").where("status", "==", "open")),
      compter(db.collection("support").where("unreadForStaff", ">", 0)),
      compterRamassages(),
    ]);

  return res.json({
    success: true,
    data: {moderation, reports, withdrawals, disputes, support, pickups},
  });
});

/**
 * Liste les ramassages à domicile en attente : colis payés pour un ramassage,
 * pas encore collectés (`awaiting_dropoff`), avec l'adresse et le contact du
 * vendeur (lus dans le sous-document privé). C'est ce qui manquait : sans ça,
 * un ramassage n'était visible que si un agent scannait pile ce colis.
 * Réservé au personnel.
 */
exports.listPendingPickups = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res, {method: "GET, POST"});
  if (!decoded) return;

  if (!isStaff(await roleOf(decoded.uid))) {
    return res.status(403).json({
      success: false,
      error: {message: "Cette action est réservée au personnel Ablony"},
    });
  }

  const snap = await db.collection("parcels")
      .where("status", "==", "awaiting_dropoff")
      .limit(300).get();

  const demandes = snap.docs.filter((d) => d.data().pickupRequested === true);

  const items = await Promise.all(demandes.map(async (d) => {
    const p = d.data();
    let contactName = null;
    let contactPhone = null;
    let address = null;
    try {
      const priv = await d.ref.collection("private").doc("pickup").get();
      if (priv.exists) {
        const pk = priv.data();
        contactName = pk.contactName || null;
        contactPhone = pk.contactPhone || null;
        address = pk.address || null;
      }
    } catch (_) {
      // Sous-document illisible : on renvoie au moins le code.
    }
    return {
      code: p.code || d.id,
      productTitle: p.productTitle || "Article",
      feeXof: Number.isFinite(p.pickupFeeXof) ? p.pickupFeeXof : null,
      requestedAt: p.pickupRequestedAt ?
        p.pickupRequestedAt.toDate().toISOString() : null,
      contactName,
      contactPhone,
      address,
    };
  }));

  items.sort((a, b) => (a.requestedAt || "").localeCompare(b.requestedAt || ""));

  return res.json({success: true, data: {items}});
});

// ============================================================================
// FRAIS DE LIVRAISON PAR SOUS-CATÉGORIE (édition admin)
// ============================================================================
//
// Le tarif d'acheminement vient de la sous-catégorie du produit
// (`config/subcategories/items/{id}`), sinon du défaut global
// (`config/delivery`), sinon du repli code. Tout est réglable ici, à la main,
// sans redéploiement — un article encombrant coûte plus qu'un petit, même dans
// la même catégorie racine. Réservé aux administrateurs (c'est de l'argent).

/**
 * Le défaut global + toutes les sous-catégories avec leur éventuel tarif posé.
 * De quoi alimenter l'éditeur admin (recherche + saisie).
 */
exports.deliveryFees = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res, {method: "GET, POST"});
  if (!decoded) return;
  if (await roleOf(decoded.uid) !== "admin") {
    return res.status(403).json({
      success: false,
      error: {message: "Réservé aux administrateurs"},
    });
  }

  const [defSnap, subs] = await Promise.all([
    db.collection("config").doc("delivery").get(),
    db.collection("config").doc("subcategories").collection("items").get(),
  ]);
  const def = defSnap.exists ? defSnap.data() : {};

  const items = subs.docs.map((d) => {
    const x = d.data();
    return {
      id: d.id,
      name: x.name || d.id,
      parentId: x.parentId || null,
      isLeaf: !Array.isArray(x.children) || x.children.length === 0,
      relayXof: Number.isFinite(x.deliveryRelayXof) ? x.deliveryRelayXof : null,
      homeXof: Number.isFinite(x.deliveryHomeXof) ? x.deliveryHomeXof : null,
      pickupXof: Number.isFinite(x.pickupXof) ? x.pickupXof : null,
    };
  }).sort((a, b) => a.name.localeCompare(b.name));

  return res.json({
    success: true,
    data: {
      defaultRelayXof: Number.isFinite(def.defaultRelayXof) ?
        def.defaultRelayXof : DELIVERY_CONFIG.FEES_XOF.relay,
      defaultHomeXof: Number.isFinite(def.defaultHomeXof) ?
        def.defaultHomeXof : DELIVERY_CONFIG.FEES_XOF.home,
      defaultPickupXof: Number.isFinite(def.defaultPickupXof) ?
        def.defaultPickupXof : DELIVERY_CONFIG.PICKUP_FEE_XOF,
      items,
    },
  });
});

/** Règle le tarif de livraison par défaut (relais/domicile). */
exports.setDeliveryDefault = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (await roleOf(decoded.uid) !== "admin") {
    return res.status(403).json({
      success: false,
      error: {message: "Réservé aux administrateurs"},
    });
  }
  const relay = Math.round(Number(req.body && req.body.relayXof));
  const home = Math.round(Number(req.body && req.body.homeXof));
  const pickup = Math.round(Number(req.body && req.body.pickupXof));
  if (!Number.isFinite(relay) || relay < 0 ||
      !Number.isFinite(home) || home < 0 ||
      !Number.isFinite(pickup) || pickup < 0) {
    return res.status(400).json({
      success: false,
      error: {message: "Montants invalides"},
    });
  }
  await db.collection("config").doc("delivery").set({
    defaultRelayXof: relay,
    defaultHomeXof: home,
    defaultPickupXof: pickup,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  _cacheDefautLivraison = null; // invalider le cache après un changement.
  return res.json({
    success: true,
    data: {defaultRelayXof: relay, defaultHomeXof: home, defaultPickupXof: pickup},
  });
});

/**
 * Pose (ou efface, avec null) le tarif d'une sous-catégorie. Effacer un champ
 * la fait retomber sur le défaut global.
 */
exports.setSubcategoryDeliveryFee = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (await roleOf(decoded.uid) !== "admin") {
    return res.status(403).json({
      success: false,
      error: {message: "Réservé aux administrateurs"},
    });
  }
  const {subcategoryId} = req.body || {};
  if (!subcategoryId) {
    return res.status(400).json({
      success: false,
      error: {message: "subcategoryId requis"},
    });
  }
  const ref = db.collection("config").doc("subcategories")
      .collection("items").doc(String(subcategoryId));
  if (!(await ref.get()).exists) {
    return res.status(404).json({
      success: false,
      error: {message: "Sous-catégorie introuvable"},
    });
  }
  const norm = (v) => {
    if (v === null || v === undefined || v === "") {
      return admin.firestore.FieldValue.delete();
    }
    const n = Math.round(Number(v));
    return Number.isFinite(n) && n >= 0 ?
      n : admin.firestore.FieldValue.delete();
  };
  await ref.set({
    deliveryRelayXof: norm(req.body.relayXof),
    deliveryHomeXof: norm(req.body.homeXof),
    pickupXof: norm(req.body.pickupXof),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  return res.json({success: true, data: {subcategoryId}});
});

// ============================================================================
// LES DEUX DÉNOUEMENTS D'UNE VENTE
// ============================================================================
//
// Une vente se dénoue dans un sens ou dans l'autre : l'argent va à l'acheteur
// ou au vendeur, jamais entre les deux et jamais à Ablony. Trois chemins y
// mènent — la confirmation de l'acheteur, une décision d'administration, et
// la résolution d'un litige — et ils doivent produire exactement le même
// mouvement. Deux copies du même geste finissent par diverger, et une
// divergence sur un mouvement d'argent crée ou perd de l'argent.

/**
 * Refuse d'agir sur une vente dont le litige est encore ouvert.
 *
 * À appeler **avant toute écriture** de la transaction : Firestore exige que
 * les lectures précèdent les écritures. Sans ce garde-fou, un acheteur peut
 * ouvrir un litige puis confirmer la réception par mégarde, et payer le
 * vendeur qu'il conteste.
 *
 * @param {Object} dbTx La transaction Firestore.
 * @param {string} transactionRef La référence de la vente.
 * @return {Promise<void>}
 */
async function refuserSiLitige(dbTx, transactionRef) {
  const litige = await dbTx.get(
      db.collection("disputes").doc(transactionRef),
  );
  if (litige.exists && litige.data().status === "open") {
    throw new Error("Un litige est en cours d'examen sur cette commande");
  }
}

/**
 * Vérifie qu'une vente peut encore se dénouer.
 *
 * @param {Object} tx Le document de transaction.
 * @return {void}
 */
function verifierVenteDenouable(tx) {
  if (tx.type !== "purchase") {
    throw new Error("Cette transaction n'est pas un achat");
  }
  if (tx.status !== "completed") {
    throw new Error("Cet achat n'a pas été finalisé");
  }
  // Les deux dénouements s'excluent : rembourser après avoir payé le vendeur
  // ferait sortir la somme deux fois.
  if (tx.deliveryConfirmed) {
    throw new Error("Cette vente est déjà réglée au vendeur");
  }
  if (tx.refundedAt) throw new Error("Cet achat a déjà été remboursé");
}

/**
 * Rend son argent à l'acheteur et remet l'article en vente.
 *
 * @param {Object} dbTx La transaction Firestore.
 * @param {Object} txRef La référence du document de transaction.
 * @param {Object} tx Le document de transaction, déjà lu.
 * @param {Object} options Le motif et l'auteur de la décision.
 * @param {string} options.reason Le motif, qui part aux deux parties.
 * @param {string} options.par L'identifiant de qui décide.
 * @return {Promise<Object>} De quoi rédiger les notifications.
 */
async function appliquerRemboursement(dbTx, txRef, tx, {reason, par}) {
  const transactionRef = txRef.id;
  verifierVenteDenouable(tx);

  const buyerRef = db.collection("users").doc(tx.userId);
  const sellerRef = db.collection("users").doc(tx.sellerId);
  const [buyerDoc, sellerDoc] = await Promise.all([
    dbTx.get(buyerRef),
    dbTx.get(sellerRef),
  ]);
  if (!buyerDoc.exists) throw new Error("Acheteur introuvable");
  if (!sellerDoc.exists) throw new Error("Vendeur introuvable");

  const parcelQuery = await dbTx.get(
      db.collection("parcels")
          .where("transactionRef", "==", transactionRef)
          .limit(1),
  );
  const parcelSnap = parcelQuery.empty ? null : parcelQuery.docs[0];

  const amount = Number(tx.productPrice || tx.amount);
  const sellerWallet = sellerDoc.data().wallet || {};
  const buyerWallet = buyerDoc.data().wallet || {};
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Le vendeur d'abord : si son attente ne couvre pas la somme, rien ne doit
  // être crédité à l'acheteur. L'ordre inverse créerait de l'argent.
  dbTx.update(sellerRef, {
    wallet: buildWalletUpdate(sellerWallet, {
      pendingAmount: Math.max(
          0, Number(sellerWallet.pendingAmount || 0) - amount,
      ),
    }),
  });
  dbTx.update(buyerRef, {
    wallet: buildWalletUpdate(buyerWallet, {
      availableAmount: Number(buyerWallet.availableAmount || 0) + amount,
    }),
  });

  dbTx.update(txRef, {
    refundedAt: now,
    refundReason: reason,
    refundedBy: par,
    updatedAt: now,
  });

  // Une transaction à part, et non une annulation : le relevé de l'acheteur
  // doit montrer l'achat **et** son remboursement.
  dbTx.set(db.collection("transactions").doc(`${transactionRef}-RF`), {
    reference: `${transactionRef}-RF`,
    userId: tx.userId,
    amount,
    paymentMethod: "wallet",
    status: "completed",
    type: "refund",
    productId: tx.productId || null,
    sellerId: tx.sellerId || null,
    refundOf: transactionRef,
    reason,
    createdAt: now,
    updatedAt: now,
  });

  dbTx.update(db.collection("receipts").doc(transactionRef), {
    refundedAt: now,
    refundReason: reason,
  });

  if (parcelSnap) {
    dbTx.update(parcelSnap.ref, {status: "returned", settledAt: now});
  }

  // L'article redevient vendable : le remboursement dit précisément que la
  // vente n'a pas eu lieu. `status` autant que les booléens hérités — sans
  // lui l'annonce resterait « vendue » pour `computeIsListable`, donc
  // invisible pour toujours.
  if (tx.productId) {
    dbTx.update(db.collection("products").doc(tx.productId), {
      status: "active",
      isSold: false,
      soldAt: null,
      updatedAt: now,
    });
  }

  return {
    buyerId: tx.userId,
    sellerId: tx.sellerId,
    amount,
    title: tx.productTitle || "votre article",
  };
}

/**
 * Verse la somme au vendeur et clôt la vente.
 *
 * @param {Object} dbTx La transaction Firestore.
 * @param {Object} txRef La référence du document de transaction.
 * @param {Object} tx Le document de transaction, déjà lu.
 * @param {Object} options Le motif et l'auteur de la décision.
 * @param {string} options.reason Le motif, tracé sur la transaction.
 * @param {string} options.par `admin`, ou l'identifiant de qui décide.
 * @return {Promise<Object>} De quoi rédiger les notifications.
 */
async function appliquerVersement(dbTx, txRef, tx, {reason, par}) {
  const transactionRef = txRef.id;
  verifierVenteDenouable(tx);

  const sellerRef = db.collection("users").doc(tx.sellerId);
  const sellerDoc = await dbTx.get(sellerRef);
  if (!sellerDoc.exists) throw new Error("Vendeur introuvable");

  const parcelQuery = await dbTx.get(
      db.collection("parcels")
          .where("transactionRef", "==", transactionRef)
          .limit(1),
  );
  const parcelSnap = parcelQuery.empty ? null : parcelQuery.docs[0];

  const wallet = sellerDoc.data().wallet || {};
  const amount = Number(tx.productPrice || tx.amount);
  const now = admin.firestore.FieldValue.serverTimestamp();

  dbTx.update(sellerRef, {
    wallet: buildWalletUpdate(wallet, {
      pendingAmount: Math.max(0, Number(wallet.pendingAmount || 0) - amount),
      availableAmount: Number(wallet.availableAmount || 0) + amount,
    }),
  });

  // L'origine du versement est tracée : en cas de contestation ultérieure,
  // savoir que l'acheteur n'a jamais confirmé change la lecture du dossier.
  dbTx.update(txRef, {
    deliveryConfirmed: true,
    deliveryConfirmedAt: now,
    deliveryConfirmedBy: par,
    deliveryConfirmedReason: reason,
    updatedAt: now,
  });
  dbTx.update(db.collection("receipts").doc(transactionRef), {
    deliveryConfirmed: true,
  });
  if (parcelSnap) {
    dbTx.update(parcelSnap.ref, {
      status: "delivered",
      deliveredAt: now,
      settledAt: now,
    });
  }

  return {
    sellerId: tx.sellerId,
    buyerId: tx.userId,
    amount,
    title: tx.productTitle || "votre article",
  };
}

/**
 * Rend son argent à l'acheteur, et remet l'article en vente.
 *
 * Réservé à l'administration, et sans automatisme : au lancement, aucune
 * horloge ne tourne et aucun agent ne constate les remises. La décision de
 * rembourser est donc prise par quelqu'un qui a regardé le dossier — ce qui
 * est le bon niveau d'exigence quand personne ne peut prouver ce qui s'est
 * passé.
 *
 * L'argent revient **disponible** chez l'acheteur, immédiatement utilisable :
 * un remboursement est définitif. Le geler « au cas où le vendeur conteste »
 * reviendrait à punir l'acheteur d'un litige qu'il n'a pas ouvert — la
 * contestation du vendeur se règle avant la décision, pas après.
 *
 * Le remboursement s'écrit comme une transaction à part entière, de type
 * `refund` : le relevé doit montrer ce qui s'est passé, pas faire comme si
 * l'achat n'avait jamais eu lieu.
 *
 * @param {Object} req La requête ; attend `transactionRef` et `reason`.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.refundPurchase = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  if (await roleOf(decoded.uid) !== "admin") {
    return res.status(403).json({
      success: false,
      error: {message: "Cette action est réservée à l'administration"},
    });
  }

  const {transactionRef, reason} = req.body || {};
  if (!transactionRef || !reason) {
    return res.status(400).json({
      success: false,
      error: {message: "Paramètres requis manquants : transactionRef, reason"},
    });
  }

  try {
    const result = await db.runTransaction(async (dbTx) => {
      const txRef = db.collection("transactions").doc(transactionRef);
      const txDoc = await dbTx.get(txRef);
      if (!txDoc.exists) throw new Error("Commande introuvable");

      // Une vente contestée se dénoue par `resolveDispute`, qui tranche le
      // litige dans le même geste. Rembourser par cette porte-ci laisserait
      // le dossier ouvert pour toujours.
      await refuserSiLitige(dbTx, transactionRef);

      return appliquerRemboursement(dbTx, txRef, txDoc.data(), {
        reason,
        par: decoded.uid,
      });
    });

    await Promise.all([
      notifyUser(
          result.buyerId,
          "Vous avez été remboursé",
          `${result.amount} FCFA sont revenus dans votre porte-monnaie : ` +
          `${reason}`,
          {type: "refund_issued", transactionRef},
      ),
      notifyUser(
          result.sellerId,
          "Vente annulée",
          `L'acheteur a été remboursé de ${result.amount} FCFA : ${reason}`,
          {type: "sale_refunded", transactionRef},
      ),
    ]);

    return res.json({success: true, data: {amount: result.amount}});
  } catch (error) {
    return res
        .status(409)
        .json({success: false, error: {message: error.message}});
  }
});

/**
 * Verse au vendeur une vente que l'acheteur n'a jamais confirmée.
 *
 * L'autre moitié de la porte de sortie. Sans agent pour constater les remises
 * et sans horloge, la confirmation de l'acheteur est le seul signal — et un
 * acheteur qui reçoit son colis puis ne touche plus à l'application laisse le
 * vendeur attendre son argent indéfiniment. Personne n'a rien fait de mal, et
 * pourtant la somme ne bouge plus.
 *
 * Réservé à l'administration, et volontairement manuel : verser sans preuve de
 * remise est exactement ce qu'un vendeur malhonnête espère. La décision doit
 * donc être prise par quelqu'un qui a regardé le dossier — la date de scan de
 * l'acheteur, quand elle existe, tranche l'essentiel des cas.
 *
 * @param {Object} req La requête ; attend `transactionRef` et `reason`.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.releasePurchase = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  if (await roleOf(decoded.uid) !== "admin") {
    return res.status(403).json({
      success: false,
      error: {message: "Cette action est réservée à l'administration"},
    });
  }

  const {transactionRef, reason} = req.body || {};
  if (!transactionRef || !reason) {
    return res.status(400).json({
      success: false,
      error: {message: "Paramètres requis manquants : transactionRef, reason"},
    });
  }

  try {
    const result = await db.runTransaction(async (dbTx) => {
      const txRef = db.collection("transactions").doc(transactionRef);
      const txDoc = await dbTx.get(txRef);
      if (!txDoc.exists) throw new Error("Commande introuvable");

      await refuserSiLitige(dbTx, transactionRef);

      return appliquerVersement(dbTx, txRef, txDoc.data(), {
        reason,
        par: "admin",
      });
    });

    await notifyUser(
        result.sellerId,
        "Paiement débloqué",
        `${result.amount} FCFA sont désormais disponibles dans votre ` +
        `porte-monnaie.`,
        {type: "funds_released", transactionRef},
    );

    return res.json({success: true, data: {amount: result.amount}});
  } catch (error) {
    return res
        .status(409)
        .json({success: false, error: {message: error.message}});
  }
});

// ============================================================================
// MODÈLE D'UNE ANNONCE — état, modération, visibilité
// ============================================================================
//
// Trois champs remplacent les trois booléens `isSold` / `isReserved` /
// `isHidden`, qui permettaient huit combinaisons dont plusieurs n'ont aucun
// sens — vendu *et* réservé, masqué *et* vendu — sans que rien ne les
// empêche.
//
//   status            le cycle de vie, une seule valeur à la fois
//   moderationStatus  ce que la modération décide, orthogonal au précédent
//   isListable        calculé ici, et interrogé par toutes les listes
//
// Les trois booléens sont **conservés** en écriture le temps que la nouvelle
// version de l'application soit adoptée : une version ancienne encore
// installée continue de fonctionner.

const PRODUCT_STATUSES = ["active", "reserved", "sold", "hidden", "archived"];
const MODERATION_STATUSES = ["pending", "approved", "rejected"];

/**
 * Déduit le cycle de vie depuis les trois booléens historiques.
 *
 * L'ordre des tests porte la priorité : une annonce vendue reste vendue même
 * si elle est aussi marquée masquée — c'est la combinaison absurde que le
 * nouveau modèle rend impossible, mais qui existe peut-être en base.
 *
 * @param {Object} data Le document produit.
 * @return {string} Une valeur de PRODUCT_STATUSES.
 */
function statusFromLegacy(data) {
  if (data.isSold === true) return "sold";
  if (data.isReserved === true) return "reserved";
  if (data.isHidden === true) return "hidden";
  return "active";
}

/**
 * Les trois booléens correspondant à un statut, pour les versions anciennes.
 *
 * `archived` se présente comme masqué : c'est le plus proche que l'ancien
 * modèle sache exprimer, et cela garde l'annonce hors des listes.
 *
 * @param {string} status Une valeur de PRODUCT_STATUSES.
 * @return {Object} Les trois booléens.
 */
function legacyFromStatus(status) {
  return {
    isSold: status === "sold",
    isReserved: status === "reserved",
    isHidden: status === "hidden" || status === "archived",
  };
}

/**
 * Une annonce doit-elle apparaître dans les listes de vente ?
 *
 * Calculé ici et jamais écrit à la main. C'est une duplication assumée : un
 * seul écrivain la maintient, et elle est lue par *toutes* les requêtes de
 * liste, qui passent ainsi de trois égalités à une. Le jour où elle dérive,
 * un script la recalcule depuis ses trois sources.
 *
 * @param {Object} product Le document produit.
 * @param {string} sellerAccountStatus L'état du compte vendeur.
 * @return {boolean} Vrai si l'annonce est visible à la vente.
 */
function computeIsListable(product, sellerAccountStatus) {
  const brut = product.status || statusFromLegacy(product);
  const brutModeration = product.moderationStatus || "pending";

  // Une valeur inconnue ne doit jamais rendre une annonce visible : on la
  // traite comme le cas le plus restrictif plutôt que de laisser passer.
  const status = PRODUCT_STATUSES.includes(brut) ? brut : "hidden";
  const moderation = MODERATION_STATUSES.includes(brutModeration) ?
    brutModeration : "rejected";

  return status === "active" &&
    moderation !== "rejected" &&
    (sellerAccountStatus || "active") === "active";
}

/**
 * L'état du compte d'un vendeur, avec un repli sûr.
 *
 * Un vendeur introuvable rend `banned` plutôt qu'`active` : mieux vaut
 * masquer une annonce à tort que laisser en vente celle d'un compte dont on
 * ne sait rien.
 *
 * @param {string} sellerId L'identifiant du vendeur.
 * @return {Promise<string>} `active`, `suspended` ou `banned`.
 */
async function sellerAccountStatus(sellerId) {
  if (!sellerId) return "banned";
  const snap = await db.collection("users").doc(sellerId).get();
  if (!snap.exists) return "banned";
  return snap.data().accountStatus || "active";
}

/**
 * Rattrape un écrivain qui n'a basculé que les booléens hérités.
 *
 * Depuis la reprise, **toutes** les annonces portent `status` — donc
 * `statusFromLegacy` ne s'applique plus jamais, et une écriture qui ne touche
 * que `isSold` est purement et simplement ignorée. C'est ce qui laissait une
 * annonce vendue visible dans les listes.
 *
 * Corriger chaque écrivain ne suffit pas : l'application installée sur les
 * téléphones reste l'ancienne pendant des semaines, et c'est elle qui écrit.
 * On rapproche donc les deux formes ici, chez l'unique écrivain de `status`.
 *
 * Seul un booléen qui **change** dans cette écriture exprime une intention :
 * ceux que le déclencheur vient lui-même de réécrire ne doivent rien relancer.
 *
 * @param {Object} avant L'état précédent, absent à la création.
 * @param {Object} apres L'état courant.
 * @param {string} courant Le `status` retenu jusqu'ici.
 * @return {?string} Le `status` corrigé, ou null s'il n'y a rien à faire.
 */
function statusDepuisBasculeHeritee(avant, apres, courant) {
  if (!avant) return null;
  const bascule = (c) => Boolean(avant[c]) !== Boolean(apres[c]);

  // La vente l'emporte sur tout le reste : masquer une annonce vendue ne la
  // remet pas en vente, et l'ordre des tests le garantit.
  if (bascule("isSold")) {
    if (apres.isSold && courant !== "sold") return "sold";
    if (!apres.isSold && courant === "sold") return "active";
  }
  if (courant === "sold") return null;

  if (bascule("isHidden")) {
    if (apres.isHidden && courant !== "archived") return "hidden";
    if (!apres.isHidden && (courant === "hidden" || courant === "archived")) {
      return "active";
    }
  }
  if (bascule("isReserved")) {
    if (apres.isReserved && courant === "active") return "reserved";
    if (!apres.isReserved && courant === "reserved") return "active";
  }
  return null;
}

/**
 * Le vendeur a-t-il vraiment retouché son annonce ?
 *
 * Distinguer une correction d'une écriture technique : le déclencheur lui-même
 * réécrit `isListable` et les mots-clés, et ces écritures-là ne doivent pas
 * faire repartir l'annonce en file.
 *
 * @param {Object} avant L'état précédent, absent à la création.
 * @param {Object} apres L'état courant.
 * @return {boolean} Vrai si un champ visible par l'acheteur a changé.
 */
function contenuChange(avant, apres) {
  if (!avant) return false;
  const champs = ["title", "description", "price", "categoryId",
    "subcategoryId", "condition"];
  for (const c of champs) {
    if (JSON.stringify(avant[c] ?? null) !== JSON.stringify(apres[c] ?? null)) {
      return true;
    }
  }
  return JSON.stringify(avant.imageUrls || []) !==
      JSON.stringify(apres.imageUrls || []) ||
    JSON.stringify(avant.attributes || {}) !==
      JSON.stringify(apres.attributes || {});
}

/**
 * Tient `isListable` à jour à chaque écriture sur une annonce.
 *
 * Côté serveur et non côté client : un client pourrait mentir, et une annonce
 * écrite hors de l'application n'aurait pas le champ.
 */
exports.onProductWritten = onDocumentWritten(
    "products/{productId}",
    async (event) => {
      const after = event.data?.after;
      if (!after?.exists) return;

      const produit = after.data();
      const avantProduit = event.data?.before?.data();
      const statusBrut = produit.status || statusFromLegacy(produit);
      const status =
        statusDepuisBasculeHeritee(avantProduit, produit, statusBrut) ||
        statusBrut;

      // Une annonce renvoyée pour correction repart d'elle-même en file dès
      // que le vendeur y touche. Sans cela il corrigerait dans le vide :
      // l'annonce resterait retirée, et personne ne la regarderait à nouveau.
      //
      // Seulement pour une correction. Une contrefaçon retirée ne se remet pas
      // en ligne en changeant le titre — la décision serait cosmétique.
      const corrigee = produit.moderationStatus === "rejected" &&
        produit.reviewDecision === "correction" &&
        contenuChange(avantProduit, produit);

      const moderation = corrigee ?
        "pending" :
        (produit.moderationStatus || "pending");
      const attendu = computeIsListable(
          {...produit, status, moderationStatus: moderation},
          await sellerAccountStatus(produit.sellerId),
      );

      // Les mots-clés sont recalculés ici et non dans un second déclencheur :
      // deux fonctions sur le même document s'écriraient l'une l'autre en
      // boucle. Recalculés seulement si ce qui les nourrit a changé.
      const sourceChangee = !avantProduit ||
        avantProduit.title !== produit.title ||
        avantProduit.categoryId !== produit.categoryId ||
        avantProduit.subcategoryId !== produit.subcategoryId ||
        JSON.stringify(avantProduit.attributes || {}) !==
          JSON.stringify(produit.attributes || {});

      const tokens = (sourceChangee || !produit.searchTokens) ?
        await searchTokens(produit) :
        produit.searchTokens;

      const aJour = produit.status === status &&
        produit.moderationStatus === moderation &&
        produit.isListable === attendu &&
        memeTableau(produit.searchTokens, tokens);

      // Sans cette sortie, l'écriture ci-dessous redéclencherait la fonction
      // indéfiniment.
      if (aJour) return;

      await after.ref.update({
        status,
        moderationStatus: moderation,
        isListable: attendu,
        searchTokens: tokens,
        ...legacyFromStatus(status),
        // `rejectedAt` remis à zéro : c'est l'horloge de la purge à dix jours,
        // et une annonce corrigée n'est plus en sursis. Le motif précédent
        // reste, lui — il dit au modérateur ce qui avait coincé.
        ...(corrigee ? {
          rejectedAt: null,
          resubmittedAt: admin.firestore.FieldValue.serverTimestamp(),
        } : {}),
      });
    },
);

/**
 * Recalcule la visibilité de toutes les annonces d'un vendeur.
 *
 * Appelée à la suspension, à sa levée et au bannissement. Quelques écritures
 * par vendeur — négligeable, et c'est ce qui rend la suspension immédiate.
 *
 * @param {string} sellerId L'identifiant du vendeur.
 * @return {Promise<number>} Le nombre d'annonces mises à jour.
 */
async function recomputeListableForSeller(sellerId) {
  const etat = await sellerAccountStatus(sellerId);
  const annonces = await db.collection("products")
      .where("sellerId", "==", sellerId)
      .where("status", "in", ["active", "reserved", "hidden"])
      .get();

  let touchees = 0;
  // Par lots de 500 : c'est la limite d'une écriture groupée Firestore.
  for (let i = 0; i < annonces.docs.length; i += 500) {
    const lot = db.batch();
    let n = 0;
    for (const doc of annonces.docs.slice(i, i + 500)) {
      const attendu = computeIsListable(doc.data(), etat);
      if (doc.data().isListable === attendu) continue;
      lot.update(doc.ref, {isListable: attendu});
      n += 1;
    }
    if (n > 0) {
      await lot.commit();
      touchees += n;
    }
  }
  return touchees;
}

/**
 * Répercute un changement d'état de compte sur les annonces du vendeur.
 *
 * C'est ce qui rend la suspension immédiate : `applySuspension` n'a qu'à
 * poser `accountStatus`, les annonces sortent des listes toutes seules. Et
 * la levée de suspension les y ramène sans que personne ait à y penser.
 */
exports.onUserAccountStatusChanged = onDocumentWritten(
    "users/{userId}",
    async (event) => {
      const avant = event.data?.before?.data();
      const apres = event.data?.after?.data();
      if (!apres) return;

      const etatAvant = avant?.accountStatus || "active";
      const etatApres = apres.accountStatus || "active";
      if (etatAvant === etatApres) return;

      const touchees = await recomputeListableForSeller(event.params.userId);
      console.log(
          `accountStatus ${etatAvant} → ${etatApres} pour ` +
      `${event.params.userId} : ${touchees} annonce(s) mise(s) à jour`,
      );
    },
);

// ============================================================================
// RECHERCHE — index de mots-clés
// ============================================================================
//
// La recherche téléchargeait **toutes** les annonces disponibles puis
// filtrait en mémoire. Aucune limite, aucun index. À six mille annonces — la
// cible annoncée —, le quota Firestore gratuit était épuisé après huit
// recherches par jour, et l'écran gelait plusieurs secondes.
//
// Le principe : un tableau de mots-clés sur chaque annonce, interrogé par
// `array-contains-any`. Pas de moteur externe — Algolia donnerait une
// meilleure pertinence, mais ajoute un service à exploiter, une clé, une
// synchronisation et un coût mensuel, pour un catalogue où l'on cherche
// « robe wax » ou « nike 42 ».

/**
 * Attributs qui ne méritent pas d'être cherchés en texte.
 *
 * L'état de l'article est un **filtre** de l'écran de recherche, pas un
 * terme : l'indexer remplissait chaque annonce de « neuf », « avec »,
 * « etiquette », « etat » — des mots si courants qu'une requête les
 * contenant ramènerait la moitié du catalogue.
 */
const ATTRIBUTS_NON_INDEXES = new Set(["condition"]);

/** Firestore limite `array-contains-any` à 30 valeurs ; 40 mots suffisent. */
const MAX_SEARCH_TOKENS = 120;

/** Cache des définitions d'attributs, réutilisé par les instances chaudes. */
const cacheAttributs = new Map();

/**
 * Les ligatures que la normalisation Unicode ne décompose pas.
 *
 * NFD sépare une lettre de son accent, mais ne sait rien de « œ » ni de
 * « ß » : sans cette table, « Cœur » s'indexe « ur » et « Straße » « stra ».
 * Elle doit rester identique à `_sansAccent` côté Flutter
 * (product_repository_impl.dart) et à la copie du script de reprise.
 */
const LIGATURES = {"œ": "oe", "æ": "ae", "ß": "ss", "ø": "o", "đ": "d"};

/**
 * Mots trop courants pour discriminer quoi que ce soit.
 *
 * `array-contains-any` remonte les annonces portant **au moins un** des mots :
 * une requête contenant « avec » ramènerait la moitié du catalogue, et les
 * vingt résultats de la page seraient pris au hasard parmi eux.
 */
const MOTS_VIDES = new Set([
  "le", "la", "les", "un", "une", "des", "du", "de", "et", "ou",
  "pour", "sans", "avec", "dans", "sur", "par", "aux", "au", "en",
  "ce", "cet", "cette", "mon", "ma", "mes", "son", "sa", "ses",
]);

/**
 * Découpe un texte en mots-clés normalisés.
 *
 * Deux formes par mot, et la seconde compte : « H&M » découpé donne « h » et
 * « m », écartés pour leur longueur — la marque devenait introuvable. La
 * forme compacte, « hm », la rattrape, comme « t-shirt » → « tshirt ».
 *
 * @param {string} texte Le texte à découper.
 * @return {string[]} Les mots retenus, sans doublon.
 */
function tokeniser(texte) {
  let brut = String(texte || "").toLowerCase();
  for (const [de, vers] of Object.entries(LIGATURES)) {
    brut = brut.split(de).join(vers);
  }
  brut = brut.normalize("NFD").replace(/[̀-ͯ]/g, "");

  const sortie = new Set();
  for (const mot of brut.split(/\s+/)) {
    for (const part of mot.split(/[^a-z0-9]+/)) {
      if (part.length >= 2 && !MOTS_VIDES.has(part)) sortie.add(part);
    }
    const compact = mot.replace(/[^a-z0-9]+/g, "");
    if (compact.length >= 2 && !MOTS_VIDES.has(compact)) sortie.add(compact);
  }
  return [...sortie];
}

/**
 * Le libellé d'une valeur d'attribut.
 *
 * Les valeurs sont stockées comme **indices** dans la liste de l'attribut :
 * `{brand: 3}` désigne la quatrième marque. Indexer la valeur brute
 * produirait le mot-clé « 3 », qui ne sert à personne.
 *
 * @param {string} attributeId L'identifiant de l'attribut.
 * @param {*} valeur L'indice, ou déjà un libellé.
 * @return {Promise<string>} Le libellé, ou une chaîne vide.
 */
async function libelleAttribut(attributeId, valeur) {
  if (valeur === null || valeur === undefined) return "";
  if (typeof valeur !== "number") return String(valeur);

  if (!cacheAttributs.has(attributeId)) {
    const snap = await db.collection("config").doc("attributes")
        .collection("items").doc(attributeId).get();
    cacheAttributs.set(
        attributeId, snap.exists ? snap.data().values || [] : [],
    );
  }
  const valeurs = cacheAttributs.get(attributeId);
  return valeurs[valeur] || "";
}

/**
 * Le nom d'une catégorie ou d'une sous-catégorie.
 *
 * @param {string} racine `categories` ou `subcategories`.
 * @param {string} id L'identifiant.
 * @return {Promise<string>} Le nom, ou une chaîne vide.
 */
async function nomCategorie(racine, id) {
  if (!id) return "";
  const cle = `${racine}/${id}`;
  if (!cacheAttributs.has(cle)) {
    const snap = await db.collection("config").doc(racine)
        .collection("items").doc(id).get();
    cacheAttributs.set(cle, snap.exists ? snap.data().name || "" : "");
  }
  return cacheAttributs.get(cle);
}

/**
 * Les mots-clés d'une annonce.
 *
 * La description est volontairement exclue : elle amène beaucoup de bruit
 * pour peu de trouvailles, et elle gonfle le tableau au-delà de la limite.
 *
 * @param {Object} produit Le document produit.
 * @return {Promise<string[]>} Les mots-clés, sans doublon.
 */
async function searchTokens(produit) {
  const morceaux = [produit.title || ""];

  for (const [id, valeur] of Object.entries(produit.attributes || {})) {
    if (ATTRIBUTS_NON_INDEXES.has(id)) continue;
    morceaux.push(await libelleAttribut(id, valeur));
  }
  morceaux.push(await nomCategorie("categories", produit.categoryId));
  morceaux.push(await nomCategorie("subcategories", produit.subcategoryId));

  const mots = [...new Set(tokeniser(morceaux.join(" ")))];
  return avecPrefixes(mots).slice(0, MAX_SEARCH_TOKENS);
}

/**
 * Étend des mots avec leurs préfixes, pour la recherche à la frappe :
 * « rob » doit trouver « robe ». Les mots entiers sont placés d'abord, puis
 * les préfixes (2 à 10 caractères) — ainsi, si le plafond tronque, ce sont des
 * préfixes qu'on perd, jamais les mots complets (garants des correspondances
 * exactes). Doit rester identique à la copie du script de reprise.
 */
function avecPrefixes(mots) {
  const sortie = new Set(mots);
  for (const mot of mots) {
    const max = Math.min(mot.length, 10);
    for (let i = 2; i < max; i++) sortie.add(mot.slice(0, i));
  }
  return [...sortie];
}

/**
 * Deux tableaux portent-ils les mêmes valeurs ?
 *
 * @param {Array} a Premier tableau.
 * @param {Array} b Second tableau.
 * @return {boolean} Vrai si identiques, ordre compris.
 */
function memeTableau(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) {
    return false;
  }
  return a.every((v, i) => v === b[i]);
}

// ============================================================================
// RETRAITS
// ============================================================================
//
// Le versement se fait à la main : quelques virements mobile money par
// semaine prennent quelques minutes, et automatiser un mouvement d'argent
// avant d'avoir vu passer les cent premiers est une mauvaise idée.
//
// Ce que le code apporte, et qui est difficile à tenir à la main : retenir la
// somme **dès la demande** pour qu'elle ne puisse pas être dépensée deux
// fois, garder la trace de qui a demandé quoi et vers quel numéro, et rendre
// l'argent proprement si le versement est refusé.
//
// Quand la clé du prestataire arrivera, `settleWithdrawal` l'appellera au
// lieu d'attendre un clic, avec un état `processing` entre `requested` et
// `paid`. Le modèle de données ne bougera pas.

// ── Frais de retrait ──────────────────────────────────────────────────────
//
// Un retrait vous coûte de l'argent : l'opérateur mobile money prélève sur
// chaque transfert, et quelqu'un passe du temps à l'effectuer. Les frais
// couvrent ce coût — ils ne sont pas une commission sur la vente.
//
// La distinction compte pour le vendeur : « frais de transfert » s'accepte,
// « commission » au moment où l'on touche son argent s'accepte mal. C'est
// aussi pourquoi Vinted ne prélève rien au vendeur et facture l'acheteur.
//
// La forme « fixe + pourcentage » suit celle des opérateurs, et fait que le
// petit retrait répété coûte plus cher que le gros — ce qui va dans votre
// sens : moins de virements à faire à la main.
//
//   2 000 F →  120 F  (6,0 %)
//  10 000 F →  200 F  (2,0 %)
//  50 000 F →  600 F  (1,2 %)
// 200 000 F → 2 100 F (1,1 %)   ← plafonné
//
// **À confirmer** contre les tarifs réels de T-Money et Flooz : au-delà d'un
// certain montant, leurs frais plafonnent, et un pourcentage nu vous ferait
// facturer plus que votre coût.
const WITHDRAWAL_FEE_FIXED_XOF = 100;
const WITHDRAWAL_FEE_RATE = 0.01;
const WITHDRAWAL_FEE_CAP_XOF = 2100;

/** En dessous, les frais pèsent trop lourd dans le montant retiré. */
const WITHDRAWAL_MIN_XOF = 2000;

/**
 * Les frais d'un retrait, arrondis au franc.
 *
 * Le XOF n'a pas de décimale : arrondir à l'entier supérieur évite de perdre
 * un franc à chaque opération, et rend le calcul reproductible côté client.
 *
 * @param {number} montant Le montant demandé, en FCFA.
 * @return {number} Les frais, en FCFA.
 */
function withdrawalFee(montant) {
  const brut = WITHDRAWAL_FEE_FIXED_XOF +
    Math.ceil(montant * WITHDRAWAL_FEE_RATE);
  return Math.min(brut, WITHDRAWAL_FEE_CAP_XOF);
}

/** Un retrait tranché ne se retranche pas. */
const WITHDRAWAL_SETTLED = ["paid", "rejected"];

const WITHDRAWAL_METHODS = ["tmoney", "flooz", "bank"];

/**
 * Masque une destination pour l'affichage côté vendeur.
 *
 * Il connaît son propre numéro ; le masquer lui évite surtout de le voir en
 * clair sur un écran qu'on lit par-dessus l'épaule. L'administration, elle,
 * a besoin du numéro entier — c'est là qu'elle envoie l'argent.
 *
 * @param {string} destination Le numéro ou le compte.
 * @return {string} La forme masquée.
 */
function maskDestination(destination) {
  const brut = String(destination || "").trim();
  if (brut.length <= 4) return brut;
  const debut = brut.slice(0, Math.min(4, brut.length - 4));
  return `${debut}${"•".repeat(Math.max(0, brut.length - 8))}${brut.slice(-4)}`;
}

/**
 * Le vendeur demande un retrait.
 *
 * La somme quitte son solde disponible **dans la même transaction** que la
 * création de la demande : sans cela, deux demandes lancées coup sur coup
 * retireraient deux fois le même argent.
 *
 * @param {Object} req La requête ; attend amountXof, method, destination.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.requestWithdrawal = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  const {amountXof, method, destination} = req.body || {};
  const montant = Number(amountXof);

  if (!Number.isInteger(montant) || montant <= 0) {
    return res.status(400).json({
      success: false,
      error: {code: "withdrawal.amount_invalid", message: "Montant invalide"},
    });
  }
  if (montant < WITHDRAWAL_MIN_XOF) {
    return res.status(400).json({
      success: false,
      error: {
        code: "withdrawal.below_minimum",
        message: `Le minimum est de ${WITHDRAWAL_MIN_XOF} FCFA`,
      },
    });
  }
  if (!WITHDRAWAL_METHODS.includes(method)) {
    return res.status(400).json({
      success: false,
      error: {code: "withdrawal.method_invalid", message: "Moyen inconnu"},
    });
  }
  if (!destination || String(destination).trim().length < 6) {
    return res.status(400).json({
      success: false,
      error: {
        code: "withdrawal.destination_invalid",
        message: "Destination invalide",
      },
    });
  }

  const reference = `WD-${Date.now()}-${crypto.randomBytes(3).toString("hex")}`
      .toUpperCase();

  try {
    const resultat = await db.runTransaction(async (dbTx) => {
      const userRef = db.collection("users").doc(decoded.uid);
      const userDoc = await dbTx.get(userRef);
      if (!userDoc.exists) throw new Error("Compte introuvable");

      const data = userDoc.data();
      const wallet = data.wallet || {};

      // Les informations d'identité du porte-monnaie servent au virement :
      // sans elles, on ne sait pas au nom de qui envoyer.
      if (!wallet.isActivated) {
        throw new Error("Activez votre porte-monnaie pour pouvoir retirer");
      }
      const disponible = Number(wallet.availableAmount || 0);
      if (disponible < montant) {
        throw new Error("Votre solde disponible ne couvre pas ce montant");
      }

      dbTx.update(userRef, {
        wallet: buildWalletUpdate(wallet, {
          availableAmount: disponible - montant,
        }),
      });

      // Les frais sont **déduits** du montant demandé, et non ajoutés par
      // dessus : le vendeur qui demande tout son solde doit pouvoir le faire.
      const frais = withdrawalFee(montant);
      const net = montant - frais;

      const now = admin.firestore.FieldValue.serverTimestamp();
      const withdrawalRef = db.collection("withdrawals").doc(reference);
      dbTx.set(withdrawalRef, {
        id: reference,
        userId: decoded.uid,
        username: data.username || null,
        holderName: [wallet.firstName, wallet.lastName]
            .filter(Boolean).join(" ") || null,
        amountXof: montant,
        feeXof: frais,
        // Ce que l'administration doit réellement envoyer.
        netAmountXof: net,
        method,
        destination: String(destination).trim(),
        destinationMasked: maskDestination(destination),
        status: "requested",
        createdAt: now,
        updatedAt: now,
      });

      // Une transaction à part entière : le relevé du porte-monnaie doit
      // montrer le retrait dès la demande, pas seulement au versement.
      dbTx.set(db.collection("transactions").doc(reference), {
        reference,
        userId: decoded.uid,
        amount: montant,
        feeXof: frais,
        netAmountXof: net,
        paymentMethod: method,
        status: "pending",
        type: "withdrawal",
        withdrawalId: reference,
        createdAt: now,
        updatedAt: now,
      });

      return {reference, montant, frais, net};
    });

    await notifyUser(
        decoded.uid,
        "Demande de retrait enregistrée",
        `Vous recevrez ${resultat.net} FCFA (frais de transfert : ` +
        `${resultat.frais} FCFA). Vous serez prévenu du versement.`,
        {type: "withdrawal_requested", withdrawalId: resultat.reference},
    );

    return res.json({
      success: true,
      data: {
        id: resultat.reference,
        status: "requested",
        amountXof: resultat.montant,
        feeXof: resultat.frais,
        netAmountXof: resultat.net,
      },
    });
  } catch (error) {
    return res.status(409).json({
      success: false,
      error: {code: "withdrawal.refused", message: error.message},
    });
  }
});

/**
 * La file des demandes en attente, pour l'administration.
 *
 * Le numéro de destination est renvoyé **en clair** : c'est là qu'on envoie
 * l'argent. C'est aussi pourquoi cette route est réservée aux
 * administrateurs, et non aux modérateurs.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.listWithdrawals = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  if (await roleOf(decoded.uid) !== "admin") {
    return res.status(403).json({
      success: false,
      error: {
        code: "forbidden",
        message: "Cette action est réservée à l'administration",
      },
    });
  }

  const limite = Math.min(Number(req.body?.limit) || 50, 100);
  const snap = await db.collection("withdrawals")
      .where("status", "==", "requested")
      .orderBy("createdAt", "asc")
      .limit(limite)
      .get();

  return res.json({
    success: true,
    data: {
      items: snap.docs.map((d) => {
        const w = d.data();
        return {
          id: w.id,
          userId: w.userId,
          username: w.username,
          holderName: w.holderName,
          // Le brut est ce qui a quitté le solde du vendeur ; le net est ce
          // qu'il faut réellement envoyer. Confondre les deux, c'est offrir
          // les frais à chaque virement.
          amountXof: w.amountXof,
          feeXof: w.feeXof || 0,
          netAmountXof: w.netAmountXof != null ?
            w.netAmountXof : w.amountXof,
          method: w.method,
          destination: w.destination,
          status: w.status,
          createdAt: w.createdAt ?
            w.createdAt.toDate().toISOString() : null,
        };
      }),
    },
  });
});

/**
 * Tranche une demande : versée, ou refusée.
 *
 * Un refus **rend la somme** au solde disponible, dans la même transaction
 * que le changement de statut. Séparés, un plantage entre les deux laisserait
 * de l'argent nulle part.
 *
 * @param {Object} req La requête ; attend withdrawalId, outcome, reason.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.settleWithdrawal = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  if (await roleOf(decoded.uid) !== "admin") {
    return res.status(403).json({
      success: false,
      error: {
        code: "forbidden",
        message: "Cette action est réservée à l'administration",
      },
    });
  }

  const {withdrawalId, outcome, reason} = req.body || {};
  if (!withdrawalId || !["paid", "rejected"].includes(outcome)) {
    return res.status(400).json({
      success: false,
      error: {
        code: "withdrawal.params_invalid",
        message: "Paramètres requis : withdrawalId, outcome",
      },
    });
  }
  if (outcome === "rejected" && (!reason || String(reason).trim().length < 5)) {
    // Un refus sans motif n'appelle qu'un message au support.
    return res.status(400).json({
      success: false,
      error: {
        code: "withdrawal.reason_required",
        message: "Un motif est requis pour refuser",
      },
    });
  }

  try {
    const resultat = await db.runTransaction(async (dbTx) => {
      const withdrawalRef = db.collection("withdrawals").doc(withdrawalId);
      const snap = await dbTx.get(withdrawalRef);
      if (!snap.exists) throw new Error("Demande introuvable");

      const w = snap.data();
      if (WITHDRAWAL_SETTLED.includes(w.status)) {
        throw new Error("Cette demande a déjà été traitée");
      }

      const userRef = db.collection("users").doc(w.userId);
      const userDoc = await dbTx.get(userRef);
      if (!userDoc.exists) throw new Error("Vendeur introuvable");

      const now = admin.firestore.FieldValue.serverTimestamp();
      dbTx.update(withdrawalRef, {
        status: outcome,
        reason: reason || null,
        settledBy: decoded.uid,
        settledAt: now,
        updatedAt: now,
      });
      dbTx.update(db.collection("transactions").doc(withdrawalId), {
        status: outcome === "paid" ? "completed" : "cancelled",
        updatedAt: now,
      });

      if (outcome === "rejected") {
        // On rend le **brut** : rien n'a été envoyé, donc aucun frais n'a
        // été engagé.
        const wallet = userDoc.data().wallet || {};
        dbTx.update(userRef, {
          wallet: buildWalletUpdate(wallet, {
            availableAmount:
              Number(wallet.availableAmount || 0) + Number(w.amountXof),
          }),
        });
        // Une seconde transaction, pour que le relevé montre le retour de la
        // somme et non un retrait qui s'évapore.
        dbTx.set(db.collection("transactions").doc(`${withdrawalId}-RF`), {
          reference: `${withdrawalId}-RF`,
          userId: w.userId,
          amount: Number(w.amountXof),
          paymentMethod: "wallet",
          status: "completed",
          type: "withdrawal_refund",
          withdrawalId,
          reason: reason || null,
          createdAt: now,
          updatedAt: now,
        });
      }

      return {
        userId: w.userId,
        amountXof: Number(w.amountXof),
        netAmountXof: Number(w.netAmountXof != null ?
          w.netAmountXof : w.amountXof),
      };
    });

    await notifyUser(
        resultat.userId,
        outcome === "paid" ? "Retrait versé" : "Retrait refusé",
        outcome === "paid" ?
          `${resultat.netAmountXof} FCFA ont été envoyés vers votre compte.` :
          `Votre demande de ${resultat.amountXof} FCFA a été refusée : ` +
          `${reason}. Le montant est revenu sur votre solde.`,
        {type: `withdrawal_${outcome}`, withdrawalId},
    );

    return res.json({
      success: true,
      data: {
        status: outcome,
        amountXof: resultat.amountXof,
        refunded: outcome === "rejected",
      },
    });
  } catch (error) {
    return res.status(409).json({
      success: false,
      error: {code: "withdrawal.not_pending", message: error.message},
    });
  }
});

// ============================================================================
// MODÉRATION ET SANCTIONS
// ============================================================================
//
// On modère des **annonces**, pas des signalements : douze personnes qui
// dénoncent la même contrefaçon posent une question et appellent une réponse.
//
// Deux degrés de gravité, et la distinction porte tout le dispositif :
//
//   correction  photo floue, mauvaise catégorie — l'annonce est retirée,
//               le vendeur peut republier corrigé, **aucun avertissement**
//   violation   contrefaçon, produit interdit, fraude — avertissement
//
// Sans cette distinction, un vendeur maladroit serait traité comme un
// fraudeur, et il faudrait neuf annonces problématiques pour arrêter un
// contrefacteur. Avec elle, deux suffisent.

const MODERATION_CLAIM_MINUTES = 5;
const WARNINGS_BEFORE_SUSPENSION = 2;
const SUSPENSIONS_BEFORE_BAN = 3;
const SUSPENSION_DAYS = 10;

const CORRECTION_REASONS = [
  "blurry_photos", "wrong_category", "missing_description", "wrong_price",
];
const VIOLATION_REASONS = [
  "counterfeit", "prohibited_item", "inappropriate", "fraud",
  "off_platform_sale",
];

const isModerator = (role) => role === "moderator" || role === "admin";

/**
 * Refuse l'appel si le rôle ne suffit pas.
 *
 * @param {Object} res La réponse.
 * @param {string} role Le rôle de l'appelant.
 * @param {boolean} adminSeulement Vrai si `admin` est exigé.
 * @return {boolean} Vrai si l'appel a été refusé.
 */
function refuseRole(res, role, adminSeulement) {
  const autorise = adminSeulement ? role === "admin" : isModerator(role);
  if (autorise) return false;
  res.status(403).json({
    success: false,
    error: {
      code: "forbidden",
      message: adminSeulement ?
        "Cette action est réservée à l'administration" :
        "Cette action est réservée au personnel Ablony",
    },
  });
  return true;
}

/**
 * La réservation d'une annonce est-elle encore valable ?
 *
 * Elle expire au bout de quelques minutes : sans expiration, un onglet fermé
 * bloquerait une annonce pour toujours.
 *
 * @param {Object} produit Le document produit.
 * @return {boolean} Vrai si quelqu'un la travaille en ce moment.
 */
function claimEnCours(produit) {
  if (!produit.claimedAt) return false;
  const age = Date.now() - produit.claimedAt.toDate().getTime();
  return age < MODERATION_CLAIM_MINUTES * 60 * 1000;
}

/**
 * Met en forme une annonce pour la file de modération.
 *
 * L'historique de sanctions du vendeur est **sur la ligne**, pas derrière un
 * lien : c'est ce qui permet de décider sans ouvrir une seconde page.
 *
 * @param {Object} doc Le document produit.
 * @param {Object} vendeur Le document du vendeur.
 * @param {Object} signalements {count, reasons}.
 * @return {Object} La ligne.
 */
function ligneModeration(doc, vendeur, signalements) {
  const p = doc.data();
  const images = p.imageUrls || [];
  return {
    productId: doc.id,
    sellerId: p.sellerId,
    sellerUsername: vendeur?.username || null,
    title: p.title || "",
    priceXof: Math.round(Number(p.price || 0)),
    categoryId: p.categoryId || null,
    imageUrl: images[0] || null,
    imageUrls: images,
    description: p.description || "",
    attributes: p.attributes || {},
    moderationStatus: p.moderationStatus || "pending",
    reportCount: signalements.count,
    reportReasons: signalements.reasons,
    sellerWarnings: Number(vendeur?.warningCount || 0),
    sellerSuspensions: Number(vendeur?.suspensionCount || 0),
    isNewSeller: Number(vendeur?.productsCount || 0) < 3,
    claimedBy: claimEnCours(p) ? p.claimedBy : null,
    claimedByName: claimEnCours(p) ? p.claimedByName : null,
    createdAt: p.createdAt ? p.createdAt.toDate().toISOString() : null,
    // Une annonce qui revient après correction n'est pas une nouvelle : le
    // modérateur doit savoir ce qui avait coincé, sinon il la relit à
    // l'aveugle et peut redemander ce qui vient d'être fait.
    resubmittedAt: p.resubmittedAt ?
      p.resubmittedAt.toDate().toISOString() :
      null,
    previousReason: p.resubmittedAt ? p.reviewReason || null : null,
  };
}

/**
 * Charge les vendeurs et les signalements d'un lot d'annonces.
 *
 * Deux requêtes groupées plutôt qu'une par ligne : à cinquante annonces, la
 * différence est l'essentiel du temps de réponse de la file.
 *
 * @param {Array} docs Les documents produits.
 * @return {Promise<{vendeurs: Map, signalements: Map}>} Les deux index.
 */
async function contexteModeration(docs) {
  const idsVendeurs = [...new Set(docs.map((d) => d.data().sellerId))];
  const vendeurs = new Map();
  for (let i = 0; i < idsVendeurs.length; i += 10) {
    const lot = idsVendeurs.slice(i, i + 10);
    const snap = await db.collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", lot).get();
    for (const d of snap.docs) vendeurs.set(d.id, d.data());
  }

  const signalements = new Map();
  const idsAnnonces = docs.map((d) => d.id);
  for (let i = 0; i < idsAnnonces.length; i += 10) {
    const lot = idsAnnonces.slice(i, i + 10);
    const snap = await db.collection("reports")
        .where("productId", "in", lot)
        .where("status", "==", "open").get();
    for (const d of snap.docs) {
      const r = d.data();
      const e = signalements.get(r.productId) ||
        {count: 0, reasons: new Set()};
      e.count += 1;
      if (r.reason) e.reasons.add(r.reason);
      signalements.set(r.productId, e);
    }
  }
  return {vendeurs, signalements};
}

/**
 * Les annonces à examiner.
 *
 * Les signalées d'abord, puis les nouveaux vendeurs, puis par ancienneté. Ce
 * n'est pas une question de volume — trois modérateurs suffisent largement —
 * mais de priorité : le risque doit être vu en premier.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.moderationQueue = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), false)) return;

  const limite = Math.min(Number(req.body?.limit) || 50, 100);

  const snap = await db.collection("products")
      .where("moderationStatus", "==", "pending")
      .orderBy("createdAt", "asc")
      .limit(limite)
      .get();

  if (snap.empty) return res.json({success: true, data: {items: []}});

  const {vendeurs, signalements} = await contexteModeration(snap.docs);
  const items = snap.docs.map((d) => {
    const s = signalements.get(d.id);
    return ligneModeration(d, vendeurs.get(d.data().sellerId), {
      count: s?.count || 0,
      reasons: s ? [...s.reasons].sort() : [],
    });
  });

  // Le tri se fait ici et non en base : Firestore ne sait pas ordonner sur un
  // nombre de signalements qui vit dans une autre collection.
  items.sort((a, b) => {
    if (a.reportCount !== b.reportCount) return b.reportCount - a.reportCount;
    if (a.isNewSeller !== b.isNewSeller) return a.isNewSeller ? -1 : 1;
    return String(a.createdAt).localeCompare(String(b.createdAt));
  });

  return res.json({success: true, data: {items}});
});

/**
 * Les annonces signalées, groupées par annonce.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.reportsQueue = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), false)) return;

  const signalements = await db.collection("reports")
      .where("status", "==", "open")
      .orderBy("createdAt", "asc")
      .limit(300)
      .get();

  if (signalements.empty) return res.json({success: true, data: {items: []}});

  const parAnnonce = new Map();
  for (const d of signalements.docs) {
    const r = d.data();
    const e = parAnnonce.get(r.productId) ||
      {count: 0, reasons: new Set(), premier: r.createdAt};
    e.count += 1;
    if (r.reason) e.reasons.add(r.reason);
    parAnnonce.set(r.productId, e);
  }

  const ids = [...parAnnonce.keys()].slice(0, 50);
  const docs = [];
  for (let i = 0; i < ids.length; i += 10) {
    const snap = await db.collection("products")
        .where(admin.firestore.FieldPath.documentId(), "in",
            ids.slice(i, i + 10))
        .get();
    docs.push(...snap.docs);
  }

  const {vendeurs} = await contexteModeration(docs);
  const items = docs.map((d) => {
    const e = parAnnonce.get(d.id);
    return ligneModeration(d, vendeurs.get(d.data().sellerId), {
      count: e.count,
      reasons: [...e.reasons].sort(),
    });
  });
  items.sort((a, b) => b.reportCount - a.reportCount);

  return res.json({success: true, data: {items}});
});

/**
 * Réserve une annonce, pour que deux modérateurs ne la traitent pas en même
 * temps.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.claimItem = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), false)) return;

  const {productId} = req.body || {};
  if (!productId) {
    return res.status(400).json({
      success: false,
      error: {code: "params_invalid", message: "productId requis"},
    });
  }

  try {
    const jusqua = await db.runTransaction(async (dbTx) => {
      const ref = db.collection("products").doc(productId);
      const snap = await dbTx.get(ref);
      if (!snap.exists) throw new Error("Annonce introuvable");

      const p = snap.data();
      if (claimEnCours(p) && p.claimedBy !== decoded.uid) {
        throw new Error(
            `Déjà en cours d'examen par ${p.claimedByName || "un collègue"}`);
      }

      const nom = (await db.collection("users").doc(decoded.uid).get())
          .data()?.username || "un modérateur";
      dbTx.update(ref, {
        claimedBy: decoded.uid,
        claimedByName: nom,
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return new Date(Date.now() + MODERATION_CLAIM_MINUTES * 60 * 1000);
    });

    return res.json({
      success: true,
      data: {claimedUntil: jusqua.toISOString()},
    });
  } catch (error) {
    return res.status(409).json({
      success: false,
      error: {code: "moderation.claimed_by_other", message: error.message},
    });
  }
});

/**
 * Libère une réservation.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.releaseClaim = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), false)) return;

  const {productId} = req.body || {};
  if (!productId) {
    return res.status(400).json({
      success: false,
      error: {code: "params_invalid", message: "productId requis"},
    });
  }
  await db.collection("products").doc(productId).update({
    claimedBy: null, claimedByName: null, claimedAt: null,
  });
  return res.json({success: true, data: {released: true}});
});

/**
 * Applique une suspension, et bannit si le seuil est atteint.
 *
 * Poser `accountStatus` suffit : le déclencheur `onUserAccountStatusChanged`
 * fait sortir les annonces du vendeur des listes, et la levée les y ramène.
 *
 * @param {Object} dbTx La transaction Firestore en cours.
 * @param {string} userId Le vendeur.
 * @param {Object} data Son document.
 * @param {string} reason Le motif.
 * @param {string} moderatorId Qui a décidé.
 * @return {Object} {suspended, banned}.
 */
function appliquerSuspension(dbTx, userId, data, reason, moderatorId) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const suspensions = Number(data.suspensionCount || 0) + 1;
  const fin = new Date(Date.now() + SUSPENSION_DAYS * 24 * 60 * 60 * 1000);

  dbTx.set(db.collection("suspensions").doc(), {
    userId, reason, moderatorId,
    startedAt: now,
    endsAt: admin.firestore.Timestamp.fromDate(fin),
    // Écrit dès maintenant, à null : une égalité Firestore ne retrouve jamais
    // un document où le champ est absent. Sans cette ligne, la levée
    // automatique ne trouverait aucune suspension à clore.
    liftedAt: null,
    createdAt: now,
  });

  // Le bannissement n'est **pas** automatique : il exige un solde nul et
  // aucune vente en cours, ce qu'on ne peut pas vérifier ici sans lire le
  // porte-monnaie et les ventes. La troisième suspension le signale ; un
  // administrateur tranche.
  const aBannir = suspensions >= SUSPENSIONS_BEFORE_BAN;

  dbTx.update(db.collection("users").doc(userId), {
    accountStatus: "suspended",
    suspendedUntil: admin.firestore.Timestamp.fromDate(fin),
    suspensionCount: suspensions,
    warningCount: 0,
    banRecommended: aBannir,
    updatedAt: now,
  });

  return {suspended: true, banRecommended: aBannir, endsAt: fin};
}

/**
 * La décision d'un modérateur sur une annonce.
 *
 * C'est la fonction centrale de l'application d'administration. Chaque
 * décision écrit qui a décidé, quand et pourquoi : avec trois modérateurs et
 * une échelle de sanctions automatique, une erreur de degré suspend quelqu'un
 * à tort — sans trace, on ne peut ni la corriger ni repérer celui qui la
 * répète.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.reviewProduct = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), false)) return;

  const {productId, decision, reason, note} = req.body || {};
  const decisions = ["approve", "correction", "violation"];
  if (!productId || !decisions.includes(decision)) {
    return res.status(400).json({
      success: false,
      error: {
        code: "params_invalid",
        message: "Paramètres requis : productId, decision",
      },
    });
  }
  if (decision !== "approve") {
    const motifs = decision === "correction" ?
      CORRECTION_REASONS : VIOLATION_REASONS;
    if (!motifs.includes(reason)) {
      return res.status(400).json({
        success: false,
        error: {code: "reason_invalid", message: `Motif inconnu : ${reason}`},
      });
    }
    // Sans explication, le vendeur republiera la même chose.
    if (!note || String(note).trim().length < 10) {
      return res.status(400).json({
        success: false,
        error: {
          code: "note_required",
          message: "Une explication d'au moins 10 caractères est requise",
        },
      });
    }
  }

  try {
    const resultat = await db.runTransaction(async (dbTx) => {
      const ref = db.collection("products").doc(productId);
      const snap = await dbTx.get(ref);
      if (!snap.exists) throw new Error("Annonce introuvable");

      const p = snap.data();
      if ((p.moderationStatus || "pending") !== "pending") {
        throw new Error("Cette annonce a déjà été examinée");
      }
      if (claimEnCours(p) && p.claimedBy !== decoded.uid) {
        throw new Error(
            `En cours d'examen par ${p.claimedByName || "un collègue"}`);
      }

      const vendeurRef = db.collection("users").doc(p.sellerId);
      const vendeurDoc = await dbTx.get(vendeurRef);

      // Les signalements ouverts se closent avec la décision : douze
      // personnes, une réponse.
      const ouverts = await dbTx.get(
          db.collection("reports")
              .where("productId", "==", productId)
              .where("status", "==", "open"));

      const now = admin.firestore.FieldValue.serverTimestamp();
      const approuve = decision === "approve";

      dbTx.update(ref, {
        moderationStatus: approuve ? "approved" : "rejected",
        reviewedBy: decoded.uid,
        reviewedAt: now,
        reviewDecision: decision,
        reviewReason: reason || null,
        reviewNote: note || null,
        rejectedAt: approuve ? null : now,
        claimedBy: null, claimedByName: null, claimedAt: null,
        updatedAt: now,
      });

      for (const d of ouverts.docs) {
        dbTx.update(d.ref, {
          status: approuve ? "dismissed" : "reviewed",
          resolvedBy: decoded.uid,
          resolvedAt: now,
          resolutionNote: note || null,
        });
      }

      let sanction = {warningIssued: false, suspended: false};
      let avertissements = Number(vendeurDoc.data()?.warningCount || 0);

      if (decision === "violation" && vendeurDoc.exists) {
        dbTx.set(db.collection("warnings").doc(), {
          userId: p.sellerId, productId, productTitle: p.title || null,
          reason, note, severity: "violation",
          moderatorId: decoded.uid, createdAt: now,
        });
        avertissements += 1;
        sanction.warningIssued = true;

        if (avertissements >= WARNINGS_BEFORE_SUSPENSION) {
          sanction = {
            ...sanction,
            ...appliquerSuspension(
                dbTx, p.sellerId, vendeurDoc.data(), reason, decoded.uid),
          };
          avertissements = 0;
        } else {
          dbTx.update(vendeurRef, {warningCount: avertissements});
        }
      }

      return {
        sellerId: p.sellerId,
        title: p.title || "votre annonce",
        approuve, sanction, avertissements,
        reportsClosed: ouverts.size,
      };
    });

    // Une approbation ne dit rien au vendeur : il n'a pas à savoir qu'on l'a
    // regardé. Un rejet, si — avec le motif, sans quoi il republiera pareil.
    if (!resultat.approuve) {
      // Une demande de correction n'est pas une sanction, et le message doit
      // le dire : ce qu'on attend, c'est une retouche, pas des excuses. Le
      // vendeur doit savoir qu'il peut agir, et que l'annonce repartira.
      const correction = decision === "correction";
      const suite = resultat.sanction.suspended ?
        ` Votre compte est suspendu ${SUSPENSION_DAYS} jours.` :
        resultat.sanction.warningIssued ?
          " Un avertissement a été inscrit." :
          " Corrigez-la et elle repart en ligne.";
      // Le modérateur ponctue souvent sa note ; ajouter un point sans regarder
      // donne « refaites-les de jour.. » dans la poche du vendeur.
      const texte = String(note || "").trim();
      const fin = /[.!?…]$/.test(texte) ? "" : ".";

      await notifyUser(
          resultat.sellerId,
          correction ? "Annonce à corriger" : "Annonce retirée",
          `« ${resultat.title} » : ${texte}${fin}${suite}`,
          {
            type: "product_rejected",
            productId,
            reason,
            // L'application s'en sert pour ouvrir le formulaire de
            // modification plutôt que la simple fiche.
            decision,
          },
      );
    }

    return res.json({
      success: true,
      data: {
        moderationStatus: resultat.approuve ? "approved" : "rejected",
        warningIssued: resultat.sanction.warningIssued,
        sellerSuspended: Boolean(resultat.sanction.suspended),
        banRecommended: Boolean(resultat.sanction.banRecommended),
        sellerWarnings: resultat.avertissements,
        reportsClosed: resultat.reportsClosed,
      },
    });
  } catch (error) {
    return res.status(409).json({
      success: false,
      error: {code: "moderation.already_reviewed", message: error.message},
    });
  }
});

/**
 * L'historique d'un vendeur : avertissements et suspensions.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.sellerHistory = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), false)) return;

  const {sellerId} = req.body || {};
  if (!sellerId) {
    return res.status(400).json({
      success: false,
      error: {code: "params_invalid", message: "sellerId requis"},
    });
  }

  const [u, w, s] = await Promise.all([
    db.collection("users").doc(sellerId).get(),
    db.collection("warnings").where("userId", "==", sellerId).limit(50).get(),
    db.collection("suspensions")
        .where("userId", "==", sellerId).limit(20).get(),
  ]);
  if (!u.exists) {
    return res.status(404).json({
      success: false,
      error: {code: "not_found", message: "Vendeur introuvable"},
    });
  }

  const d = u.data();
  const date = (t) => t ? t.toDate().toISOString() : null;
  return res.json({
    success: true,
    data: {
      username: d.username || null,
      accountStatus: d.accountStatus || "active",
      suspendedUntil: date(d.suspendedUntil),
      banRecommended: Boolean(d.banRecommended),
      warnings: w.docs.map((x) => ({
        reason: x.data().reason, note: x.data().note,
        productTitle: x.data().productTitle,
        createdAt: date(x.data().createdAt),
      })).sort((a, b) =>
        String(b.createdAt).localeCompare(String(a.createdAt))),
      suspensions: s.docs.map((x) => ({
        reason: x.data().reason,
        startedAt: date(x.data().startedAt), endsAt: date(x.data().endsAt),
      })).sort((a, b) =>
        String(b.startedAt).localeCompare(String(a.startedAt))),
    },
  });
});

// ============================================================================
// LITIGES
// ============================================================================
//
// L'acheteur signale, l'administration tranche. Aucun automatisme : aucun
// algorithme ne peut décider si une robe correspond à sa photo, et à ce volume
// un humain qui regarde les photos est plus juste — et moins cher — qu'une
// règle qui se trompera dans les deux sens.
//
// L'identifiant du document **est** la référence de transaction : une vente,
// un litige. L'unicité est ainsi garantie par Firestore, sans vérification à
// relire.

const DISPUTE_REASONS = [
  // Motifs acheteur.
  "not_received", "not_as_described", "damaged",
  // Motifs vendeur (l'acheteur ne confirme pas / réclame sans motif).
  "buyer_not_confirming", "buyer_no_valid_reason",
  // Commun.
  "other",
];
const DISPUTE_DESCRIPTION_MIN = 30;
const DISPUTE_MAX_PHOTOS = 4;

/**
 * Ouvre un litige sur une vente.
 *
 * Ouvrable par l'acheteur **et** par le vendeur : celui-ci aussi peut
 * contester, par exemple face à un acheteur qui réclame sans motif.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.openDispute = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;

  const {transactionRef, reason, description, photoUrls} = req.body || {};

  if (!transactionRef || !DISPUTE_REASONS.includes(reason)) {
    return res.status(400).json({
      success: false,
      error: {
        code: "params_invalid",
        message: "transactionRef et un motif valide sont requis",
      },
    });
  }

  const texte = String(description || "").trim();
  if (texte.length < DISPUTE_DESCRIPTION_MIN) {
    // « ça va pas » ne permet de trancher ni dans un sens ni dans l'autre.
    return res.status(400).json({
      success: false,
      error: {
        code: "description_too_short",
        message: `Décrivez le problème en ${DISPUTE_DESCRIPTION_MIN} ` +
          `caractères au moins`,
      },
    });
  }

  const photos = Array.isArray(photoUrls) ?
    photoUrls
        .filter((u) => typeof u === "string")
        .slice(0, DISPUTE_MAX_PHOTOS) :
    [];

  try {
    const resultat = await db.runTransaction(async (dbTx) => {
      const txRef = db.collection("transactions").doc(transactionRef);
      const litigeRef = db.collection("disputes").doc(transactionRef);
      const [txDoc, litigeDoc] = await Promise.all([
        dbTx.get(txRef),
        dbTx.get(litigeRef),
      ]);

      // Un tiers reçoit « introuvable », pas « interdit » : dire « interdit »
      // confirmerait l'existence de la vente à qui n'a rien à y voir.
      if (!txDoc.exists) throw new Error("Commande introuvable");
      const tx = txDoc.data();
      const partie = tx.userId === decoded.uid || tx.sellerId === decoded.uid;
      if (!partie) throw new Error("Commande introuvable");

      if (tx.type !== "purchase") {
        throw new Error("Cette transaction n'est pas un achat");
      }
      if (tx.status !== "completed") {
        throw new Error("Cet achat n'a pas été finalisé");
      }
      // Après confirmation ou remboursement, il n'y a plus rien à geler.
      if (tx.deliveryConfirmed) {
        throw new Error("Cette vente est déjà réglée au vendeur");
      }
      if (tx.refundedAt) throw new Error("Cet achat a déjà été remboursé");

      if (litigeDoc.exists && litigeDoc.data().status === "open") {
        throw new Error("Un litige est déjà ouvert sur cette commande");
      }
      if (litigeDoc.exists) {
        // Rouvrir n'apporte rien : on répond dans le même fil.
        throw new Error("Cette commande a déjà été tranchée");
      }

      dbTx.set(litigeRef, {
        transactionRef,
        buyerId: tx.userId,
        sellerId: tx.sellerId,
        openedBy: decoded.uid,
        productId: tx.productId || null,
        productTitle: tx.productTitle || null,
        amountXof: Math.round(Number(tx.productPrice || tx.amount || 0)),
        reason,
        description: texte,
        photoUrls: photos,
        status: "open",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        buyerId: tx.userId,
        sellerId: tx.sellerId,
        title: tx.productTitle || "cette commande",
      };
    });

    // L'autre partie est prévenue : un litige ouvert dans son dos, découvert
    // au moment de la décision, est vécu comme une condamnation sans procès.
    const autre = decoded.uid === resultat.buyerId ?
      resultat.sellerId :
      resultat.buyerId;
    await notifyUser(
        autre,
        "Litige ouvert",
        `Un litige a été ouvert sur « ${resultat.title} ». ` +
        `L'administration l'examine.`,
        {type: "dispute_opened", transactionRef},
    );

    return res.json({success: true, data: {status: "open", transactionRef}});
  } catch (error) {
    const introuvable = error.message === "Commande introuvable";
    return res.status(introuvable ? 404 : 409).json({
      success: false,
      error: {
        code: introuvable ? "not_found" : "dispute.invalid",
        message: error.message,
      },
    });
  }
});

/**
 * La file des litiges ouverts, pour l'administration.
 *
 * Le scan de l'acheteur est joint à chaque ligne : il tranche l'essentiel des
 * dossiers « jamais reçu », et l'aller chercher dossier par dossier ferait de
 * la file un travail de fouille.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.listDisputes = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), true)) return;

  const limite = Math.min(Number(req.body?.limit) || 50, 200);

  // Les plus anciens d'abord : c'est celui qui attend depuis le plus
  // longtemps qui a le plus besoin d'une réponse.
  const snap = await db.collection("disputes")
      .where("status", "==", "open")
      .orderBy("createdAt", "asc")
      .limit(limite)
      .get();

  if (snap.empty) return res.json({success: true, data: {items: []}});

  const refs = snap.docs.map((d) => d.id);
  const colis = new Map();
  // Par lots de trente : c'est la limite d'un `in` Firestore.
  for (let i = 0; i < refs.length; i += 30) {
    const lot = await db.collection("parcels")
        .where("transactionRef", "in", refs.slice(i, i + 30))
        .get();
    for (const d of lot.docs) colis.set(d.data().transactionRef, d.data());
  }

  const utilisateurs = new Map();
  const ids = [...new Set(snap.docs.flatMap(
      (d) => [d.data().buyerId, d.data().sellerId],
  ))].filter(Boolean);
  for (let i = 0; i < ids.length; i += 30) {
    const lot = await db.getAll(
        ...ids.slice(i, i + 30).map((u) => db.collection("users").doc(u)),
    );
    for (const d of lot) if (d.exists) utilisateurs.set(d.id, d.data());
  }

  const items = snap.docs.map((d) => {
    const l = d.data();
    const c = colis.get(l.transactionRef) || null;
    return {
      transactionRef: l.transactionRef,
      buyerId: l.buyerId,
      buyerUsername: utilisateurs.get(l.buyerId)?.username || null,
      sellerId: l.sellerId,
      sellerUsername: utilisateurs.get(l.sellerId)?.username || null,
      openedBy: l.openedBy,
      openedBySide: l.openedBy === l.buyerId ? "buyer" : "seller",
      productId: l.productId || null,
      productTitle: l.productTitle || null,
      amountXof: Number(l.amountXof || 0),
      reason: l.reason,
      description: l.description || "",
      photoUrls: l.photoUrls || [],
      parcelCode: c?.code || null,
      parcelStatus: c?.status || null,
      // Ce point tranche l'essentiel des dossiers « jamais reçu ».
      buyerScannedAt: c?.buyerScannedAt ?
        c.buyerScannedAt.toDate().toISOString() :
        null,
      createdAt: l.createdAt ? l.createdAt.toDate().toISOString() : null,
    };
  });

  return res.json({success: true, data: {items}});
});

/**
 * Tranche un litige : l'argent va à l'acheteur, ou au vendeur.
 *
 * Jamais entre les deux, et jamais à Ablony. Le mouvement d'argent est celui
 * des deux fonctions existantes, appelé ici plutôt que recopié.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.resolveDispute = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), true)) return;

  const {transactionRef, outcome, note} = req.body || {};
  const issues = ["refunded", "released"];
  const motif = String(note || "").trim();

  if (!transactionRef || !issues.includes(outcome) || !motif) {
    return res.status(400).json({
      success: false,
      error: {
        code: "params_invalid",
        message: "transactionRef, outcome (refunded|released) et note requis",
      },
    });
  }

  try {
    const resultat = await db.runTransaction(async (dbTx) => {
      const litigeRef = db.collection("disputes").doc(transactionRef);
      const txRef = db.collection("transactions").doc(transactionRef);
      const [litigeDoc, txDoc] = await Promise.all([
        dbTx.get(litigeRef),
        dbTx.get(txRef),
      ]);

      if (!litigeDoc.exists) throw new Error("Litige introuvable");
      if (litigeDoc.data().status !== "open") {
        throw new Error("Ce litige a déjà été tranché");
      }
      if (!txDoc.exists) throw new Error("Commande introuvable");

      const argent = outcome === "refunded" ?
        await appliquerRemboursement(dbTx, txRef, txDoc.data(), {
          reason: motif, par: decoded.uid,
        }) :
        await appliquerVersement(dbTx, txRef, txDoc.data(), {
          reason: motif, par: decoded.uid,
        });

      dbTx.update(litigeRef, {
        status: outcome,
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        resolvedBy: decoded.uid,
        resolutionNote: motif,
      });

      return {...argent, outcome};
    });

    // Les deux parties, avec le motif : une décision sans motif se vit comme
    // un arbitraire, et c'est le motif qui évite le second litige.
    const rembourse = resultat.outcome === "refunded";
    await Promise.all([
      notifyUser(
          resultat.buyerId,
          rembourse ? "Litige tranché : vous êtes remboursé" :
            "Litige tranché en faveur du vendeur",
          `« ${resultat.title} » — ${motif}`,
          {type: "dispute_resolved", transactionRef, outcome},
      ),
      notifyUser(
          resultat.sellerId,
          rembourse ? "Litige tranché : l'acheteur est remboursé" :
            "Litige tranché en votre faveur",
          `« ${resultat.title} » — ${motif}`,
          {type: "dispute_resolved", transactionRef, outcome},
      ),
    ]);

    return res.json({
      success: true,
      data: {status: outcome, amountXof: resultat.amount},
    });
  } catch (error) {
    return res.status(409).json({
      success: false,
      error: {code: "dispute.invalid", message: error.message},
    });
  }
});

// ============================================================================
// LA TÂCHE PLANIFIÉE
// ============================================================================
//
// Avant elle, rien n'expirait tout seul : une vente attendait indéfiniment la
// confirmation de l'acheteur, un colis jamais déposé ne remboursait personne,
// une suspension de dix jours ne se levait pas au onzième. L'exploitation
// quotidienne dépendait d'un humain qui n'oublie jamais.
//
// Une seule fonction pour quatre traitements : un déclencheur à surveiller, un
// journal à lire, un bilan qui dit d'un coup d'œil ce qui s'est passé.
//
// Trois exigences traversent tout ce qui suit :
//
//   Idempotence   Cloud Scheduler peut déclencher deux fois. Un remboursement
//                 ne doit pas partir deux fois, une suspension ne doit pas se
//                 lever deux fois.
//   Une limite    Une requête sans `limit()` sur une collection qui a grossi,
//                 c'est une fonction qui dépasse son temps d'exécution et
//                 recommence le même travail à chaque heure sans le finir.
//   Le litige     Un litige ouvert gèle tout. Sans ce contrôle, un acheteur
//                 qui signale un problème se fait payer son vendeur sous le
//                 nez trois jours plus tard.

const PURGE_REJECTED_DAYS = 10;
const RELEASE_AFTER_DELIVERY_DAYS = 3;
/** Rappels au vendeur quand il reste 3 jours, puis 1 jour, pour déposer. */
const DROPOFF_REMINDER_DAYS = [3, 1];

const JOUR_MS = 24 * 60 * 60 * 1000;
const ilYA = (jours) => new Date(Date.now() - jours * JOUR_MS);
const dans = (jours) => new Date(Date.now() + jours * JOUR_MS);

/**
 * Archive les annonces rejetées depuis dix jours.
 *
 * Archiver, jamais supprimer : une annonce effacée emporte avec elle la trace
 * de ce qui a été décidé, et les reçus qui la citent pointent dans le vide.
 *
 * @return {Promise<number>} Le nombre d'annonces archivées.
 */
async function purgerAnnoncesRejetees() {
  const snap = await db.collection("products")
      .where("moderationStatus", "==", "rejected")
      .where("rejectedAt", "<=", ilYA(PURGE_REJECTED_DAYS))
      .limit(200)
      .get();

  let n = 0;
  const lot = db.batch();
  for (const doc of snap.docs) {
    // Une annonce rejetée **après** avoir été vendue ne s'archive pas sous les
    // pieds d'un acheteur qui attend son colis. Filtré ici : Firestore
    // n'accepte pas un `!=` à côté d'une comparaison de dates.
    if (doc.data().status === "sold") continue;
    if (doc.data().status === "archived") continue;
    lot.update(doc.ref, {
      status: "archived",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    n += 1;
  }
  if (n > 0) await lot.commit();
  return n;
}

/**
 * Lève les suspensions arrivées à terme.
 *
 * Poser `accountStatus` ne suffit pas : c'est `recomputeListableForSeller` qui
 * ramène les annonces dans les listes. Sans lui, la suspension est levée sur
 * le papier et le vendeur reste invisible.
 *
 * @return {Promise<number>} Le nombre de comptes réactivés.
 */
async function leverSuspensionsEchues() {
  const snap = await db.collection("users")
      .where("accountStatus", "==", "suspended")
      .where("suspendedUntil", "<=", new Date())
      .limit(100)
      .get();

  let n = 0;
  for (const doc of snap.docs) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    await doc.ref.update({
      accountStatus: "active",
      suspendedUntil: null,
      updatedAt: now,
    });

    // La suspension en cours est close. Relue plutôt que devinée : rien ne
    // garantit qu'il n'y en ait qu'une.
    const suspensions = await db.collection("suspensions")
        .where("userId", "==", doc.id)
        .limit(10)
        .get();
    for (const s of suspensions.docs) {
      // Filtré ici plutôt qu'en requête : les suspensions écrites avant que
      // `liftedAt` existe n'ont pas le champ, et aucune égalité ne les
      // retrouverait.
      if (s.data().liftedAt) continue;
      await s.ref.update({liftedAt: now});
    }

    await recomputeListableForSeller(doc.id);
    await notifyUser(
        doc.id,
        "Votre compte est de nouveau actif",
        "Votre suspension est levée. Vos annonces sont revenues en ligne.",
        {type: "suspension_lifted"},
    );
    n += 1;
  }
  return n;
}

/**
 * Relance, puis rembourse, les colis jamais déposés.
 *
 * Une seule requête pour les deux : les colis en retard et ceux qui approchent
 * de l'échéance sont les mêmes, triés par date limite. Les plus urgents
 * viennent donc en premier, ce qui compte quand la limite est atteinte.
 *
 * Rembourser sans avoir relancé, c'est sanctionner une distraction. D'où les
 * deux rappels, et le compteur qui évite de renvoyer le même toutes les heures.
 *
 * @return {Promise<Object>} {rappels, rembourses}.
 */
async function rembourserDepotsNonFaits() {
  const maintenant = new Date();
  const snap = await db.collection("parcels")
      .where("status", "==", "awaiting_dropoff")
      .where("dropoffDeadline", "<=", dans(DROPOFF_REMINDER_DAYS[0]))
      .orderBy("dropoffDeadline", "asc")
      .limit(100)
      .get();

  let rappels = 0;
  let rembourses = 0;

  for (const doc of snap.docs) {
    const colis = doc.data();
    const limite = colis.dropoffDeadline?.toDate?.();
    if (!limite) continue;

    if (limite > maintenant) {
      // Pas encore en retard : relancer, une fois par palier.
      const restants = (limite - maintenant) / JOUR_MS;
      const attendus = DROPOFF_REMINDER_DAYS
          .filter((seuil) => restants <= seuil).length;
      if (attendus > Number(colis.remindersSent || 0)) {
        const jours = Math.max(1, Math.ceil(restants));
        await notifyUser(
            colis.sellerId,
            "Déposez votre colis",
            `Il vous reste ${jours} jour${jours > 1 ? "s" : ""} pour déposer ` +
            `« ${colis.productTitle || "votre article"} ». Passé ce délai, ` +
            `l'acheteur est remboursé.`,
            {type: "dropoff_reminder", parcelCode: colis.code},
        );
        await doc.ref.update({remindersSent: attendus});
        rappels += 1;
      }
      continue;
    }

    // En retard : l'acheteur n'a pas à attendre indéfiniment un colis qui
    // n'est jamais parti.
    try {
      const resultat = await db.runTransaction(async (dbTx) => {
        const txRef = db.collection("transactions").doc(colis.transactionRef);
        const txDoc = await dbTx.get(txRef);
        if (!txDoc.exists) throw new Error("Commande introuvable");
        await refuserSiLitige(dbTx, colis.transactionRef);
        return appliquerRemboursement(dbTx, txRef, txDoc.data(), {
          reason: "Le vendeur n'a pas déposé le colis dans le délai imparti",
          par: "system",
        });
      });

      await Promise.all([
        notifyUser(
            resultat.buyerId,
            "Vous avez été remboursé",
            `${resultat.amount} FCFA sont revenus dans votre porte-monnaie : ` +
            `le colis n'a jamais été déposé.`,
            {type: "refund_issued", transactionRef: colis.transactionRef},
        ),
        notifyUser(
            resultat.sellerId,
            "Vente annulée",
            `« ${resultat.title} » n'a pas été déposé dans le délai. ` +
            `L'acheteur a été remboursé et l'article est de nouveau en vente.`,
            {type: "sale_refunded", transactionRef: colis.transactionRef},
        ),
      ]);
      rembourses += 1;
    } catch (e) {
      // Déjà remboursé, déjà réglé, litige ouvert : autant de raisons
      // légitimes de ne rien faire. On note et on continue — une erreur sur
      // un colis ne doit pas arrêter les quatre-vingt-dix-neuf autres.
      console.warn(`dépôt non fait ${colis.code} : ${e.message}`);
    }
  }

  return {rappels, rembourses};
}

/**
 * Libère les fonds trois jours après une remise constatée.
 *
 * Le traitement le plus délicat de la fonction, et le seul qui demande une
 * justification : payer le vendeur alors que l'acheteur n'a rien confirmé
 * n'est défendable que parce que **la remise a été constatée par un agent**,
 * pas déclarée par le vendeur. Sans ce constat, il faudrait choisir entre
 * pénaliser un vendeur honnête dont l'acheteur ne confirme jamais et payer un
 * vendeur qui n'a rien envoyé. Le scan du colis tranche.
 *
 * @return {Promise<number>} Le nombre de ventes libérées.
 */
async function libererRemisesConfirmees() {
  const snap = await db.collection("parcels")
      .where("status", "==", "delivered")
      .where("deliveredAt", "<=", ilYA(RELEASE_AFTER_DELIVERY_DAYS))
      .limit(100)
      .get();

  let n = 0;
  for (const doc of snap.docs) {
    const colis = doc.data();
    // `settledAt` est absent des colis créés avant ce champ, et une égalité
    // Firestore ne retrouve jamais un document où le champ manque. Filtré ici.
    if (colis.settledAt) continue;

    try {
      const resultat = await db.runTransaction(async (dbTx) => {
        const txRef = db.collection("transactions").doc(colis.transactionRef);
        const txDoc = await dbTx.get(txRef);
        if (!txDoc.exists) throw new Error("Commande introuvable");
        // Impératif. Sans cette ligne, un acheteur qui signale un problème se
        // fait payer son vendeur sous le nez trois jours plus tard.
        await refuserSiLitige(dbTx, colis.transactionRef);
        return appliquerVersement(dbTx, txRef, txDoc.data(), {
          reason: "Délai de contestation écoulé après remise constatée",
          par: "system",
        });
      });

      await notifyUser(
          resultat.sellerId,
          "Paiement débloqué",
          `${resultat.amount} FCFA sont désormais disponibles dans votre ` +
          `porte-monnaie : la remise a été constatée il y a ` +
          `${RELEASE_AFTER_DELIVERY_DAYS} jours.`,
          {type: "funds_released", transactionRef: colis.transactionRef},
      );
      n += 1;
    } catch (e) {
      console.warn(`libération ${colis.code} : ${e.message}`);
    }
  }
  return n;
}

/**
 * Le traitement horaire.
 *
 * Toutes les heures et non toutes les minutes : aucun de ces traitements n'est
 * urgent à la minute, et une exécution horaire coûte 720 déclenchements par
 * mois — rien.
 */

/**
 * Rattrape les paiements que le webhook n'a pas confirmés.
 *
 * Le webhook est le chemin normal, mais il peut manquer à l'appel : passerelle
 * qui ne notifie pas, incident réseau, fonction indisponible une minute. Sans
 * ce rattrapage, l'argent a quitté le compte de l'acheteur et l'application
 * reste persuadée qu'il n'a pas payé — la pire des situations, parce que
 * personne ne s'en aperçoit avant une réclamation.
 *
 * On interroge donc GeniusPay pour chaque transaction restée en attente, et on
 * finalise celles qu'il déclare payées. Les finalisations étant idempotentes,
 * un webhook arrivé entre-temps ne produit pas de double crédit.
 *
 * On ne remonte pas au-delà de 48 h : une transaction plus ancienne est expirée
 * côté passerelle, l'interroger ne ferait que consommer des appels.
 */
async function reconcilierPaiementsEnAttente() {
  const maintenant = Date.now();
  const debut = new Date(maintenant - 48 * 60 * 60 * 1000);
  // Laisser un peu de temps au webhook avant de doubler son travail.
  const fin = new Date(maintenant - 5 * 60 * 1000);

  const enAttente = await db.collection("transactions")
      .where("status", "==", "pending")
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(debut))
      .where("createdAt", "<=", admin.firestore.Timestamp.fromDate(fin))
      .limit(50)
      .get();

  let finalisees = 0;

  for (const doc of enAttente.docs) {
    const tx = doc.data();
    try {
      const reponse = await fetch(
          `${GENIUSPAY_CONFIG.BASE_URL}/payments/${doc.id}/status`,
          {headers: {
            "X-API-Key": GENIUSPAY_CONFIG.API_KEY,
            "X-API-Secret": GENIUSPAY_CONFIG.API_SECRET,
          }},
      );
      const corps = await reponse.json();
      const statut = corps.data?.status;

      if (statut !== "completed" && statut !== "success" &&
          statut !== "successful") {
        continue;
      }

      if (tx.type === "purchase") {
        await finalizePurchase({
          buyerId: tx.userId,
          sellerId: tx.sellerId,
          productId: tx.productId,
          productPrice: Number(tx.productPrice || tx.amount),
          walletDeduction: Number(tx.walletDeduction || 0),
          transactionRef: doc.id,
          paymentMethod: tx.paymentMethod,
          totalAmount: Number(tx.amount),
          delivery: tx.delivery || null,
        });
      } else if (tx.type === "boost") {
        await finalizeBoost({
          userId: tx.userId,
          productId: tx.productId,
          walletDeduction: Number(tx.walletDeduction || 0),
          transactionRef: doc.id,
        });
      } else if (tx.type === "boostpack") {
        await finalizeBoostPack({
          userId: tx.userId,
          quantity: Number(tx.quantity || 1),
          walletDeduction: Number(tx.walletDeduction || 0),
          transactionRef: doc.id,
        });
      } else if (tx.type === "pickup") {
        const pk = tx.pickup || {};
        await finalizePickup({
          userId: tx.userId,
          parcelCode: pk.parcelCode,
          walletDeduction: Number(tx.walletDeduction || 0),
          feeXof: Number(pk.feeXof || tx.amount || 0),
          pickupContact: pk.contact || null,
          pickupAddress: pk.address || null,
          transactionRef: doc.id,
        });
      } else {
        await finalizeRecharge(tx.userId, Number(tx.amount), doc.id);
      }

      finalisees += 1;
      console.log(`Rattrapage : ${doc.id} (${tx.type}) finalisée`);
    } catch (e) {
      // Un échec sur une transaction ne doit pas priver les suivantes du
      // rattrapage : la prochaine exécution réessaiera.
      console.error(`Rattrapage ${doc.id} :`, e.message);
    }
  }

  return finalisees;
}

exports.hourlyTasks = onSchedule("every 1 hours", async () => {
  const debut = Date.now();
  const bilan = {};
  const erreurs = [];

  // Chacun dans son coin : l'échec de l'un ne doit pas priver les trois
  // autres de leur exécution. Une suspension non levée parce qu'un
  // remboursement a échoué serait une seconde panne créée par la première.
  const traitements = [
    ["archivees", purgerAnnoncesRejetees],
    ["suspensionsLevees", leverSuspensionsEchues],
    ["depots", rembourserDepotsNonFaits],
    ["liberes", libererRemisesConfirmees],
    ["paiementsRattrapes", reconcilierPaiementsEnAttente],
  ];

  for (const [nom, fn] of traitements) {
    try {
      bilan[nom] = await fn();
    } catch (e) {
      bilan[nom] = null;
      erreurs.push(`${nom}: ${e.message}`);
      console.error(`hourlyTasks ${nom}`, e);
    }
  }

  // Cinq lignes qui permettent de répondre à « pourquoi ce remboursement
  // est-il parti ? » trois semaines plus tard.
  await db.collection("scheduledRuns").add({
    ranAt: admin.firestore.FieldValue.serverTimestamp(),
    durationMs: Date.now() - debut,
    bilan,
    erreurs,
  });

  console.log("hourlyTasks", JSON.stringify(bilan), erreurs);
});

/**
 * Ferme définitivement un compte.
 *
 * Réservé à l'administration, pas aux modérateurs : un modérateur avertit et
 * suspend ; couper définitivement un accès est d'un autre ordre.
 *
 * Deux garde-fous, et ils ne sont pas administratifs. Bannir quelqu'un dont le
 * porte-monnaie n'est pas vide, c'est garder son argent — quoi qu'il ait fait,
 * cet argent est le sien. Bannir quelqu'un qui a une vente en cours, c'est
 * laisser un acheteur qui n'a rien fait de mal sans colis et sans recours.
 *
 * Le compte n'est jamais supprimé : `accountStatus = "banned"`. Les ventes
 * passées, les reçus et les traces de modération doivent survivre.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
exports.banUser = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), true)) return;

  const {userId, reason} = req.body || {};
  const motif = String(reason || "").trim();
  if (!userId || !motif) {
    return res.status(400).json({
      success: false,
      error: {code: "params_invalid", message: "userId et reason requis"},
    });
  }
  if (userId === decoded.uid) {
    return res.status(400).json({
      success: false,
      error: {code: "self_ban", message: "On ne se bannit pas soi-même"},
    });
  }

  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  if (!userDoc.exists) {
    return res.status(404).json({
      success: false,
      error: {code: "not_found", message: "Compte introuvable"},
    });
  }

  const data = userDoc.data();
  if (data.accountStatus === "banned") {
    return res.status(409).json({
      success: false,
      error: {code: "already_banned", message: "Ce compte est déjà fermé"},
    });
  }

  // ── Premier garde-fou : le porte-monnaie ──────────────────────────────
  const wallet = data.wallet || {};
  const disponible = Number(wallet.availableAmount || 0);
  const attente = Number(wallet.pendingAmount || 0);

  // ── Second garde-fou : les ventes en cours ───────────────────────────
  // Payées, ni confirmées ni remboursées : quelqu'un attend un colis.
  const ventes = await db.collection("transactions")
      .where("sellerId", "==", userId)
      .where("status", "==", "completed")
      .limit(200)
      .get();
  const enCours = ventes.docs.filter((d) => {
    const t = d.data();
    return t.type === "purchase" && !t.deliveryConfirmed && !t.refundedAt;
  });

  if (disponible > 0 || attente > 0 || enCours.length > 0) {
    const obstacles = [];
    if (disponible > 0) obstacles.push(`${disponible} FCFA disponibles`);
    if (attente > 0) obstacles.push(`${attente} FCFA en attente`);
    if (enCours.length > 0) {
      obstacles.push(`${enCours.length} vente(s) en cours`);
    }
    return res.status(409).json({
      success: false,
      error: {
        code: "ban.blocked",
        message: `Fermeture impossible : ${obstacles.join(", ")}. ` +
          `Dénouez ces ventes et videz le porte-monnaie d'abord — ` +
          `en attendant, prolongez la suspension.`,
        details: {
          availableAmount: disponible,
          pendingAmount: attente,
          openSales: enCours.length,
        },
      },
    });
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  await userRef.update({
    accountStatus: "banned",
    bannedAt: now,
    bannedBy: decoded.uid,
    banReason: motif,
    banRecommended: false,
    suspendedUntil: null,
    updatedAt: now,
  });

  // Les annonces sortent des listes. `onUserAccountStatusChanged` le fait
  // aussi ; l'appeler ici rend l'effet immédiat plutôt que « bientôt ».
  await recomputeListableForSeller(userId);

  // Les jetons déjà émis restent valides jusqu'à une heure. Sans révocation,
  // un compte fermé continue d'agir pendant tout ce temps.
  try {
    await admin.auth().revokeRefreshTokens(userId);
  } catch (e) {
    console.warn(`révocation des sessions ${userId} : ${e.message}`);
  }

  await notifyUser(
      userId,
      "Votre compte a été fermé",
      motif,
      {type: "account_banned"},
  );

  return res.json({
    success: true,
    data: {accountStatus: "banned", userId},
  });
});

/**
 * Pose `status: "open"` sur un signalement qui n'en porte pas.
 *
 * La file de modération interroge `status == "open"`, et une égalité Firestore
 * ne retrouve jamais un document où le champ est absent : un signalement écrit
 * sans lui serait déposé, stocké, et jamais lu.
 *
 * Le poser ici plutôt que de l'exiger dans les règles fait fonctionner les
 * **deux** versions de l'application — celle qu'on vient de publier et celle
 * qui reste installée. C'est la seule façon de durcir sans casser.
 */
exports.onReportCreated = onDocumentCreated(
    "reports/{reportId}",
    async (event) => {
      const doc = event.data;
      if (!doc?.exists) return;
      if (doc.data().status) return;
      await doc.ref.update({status: "open"});
    },
);

/**
 * Attribue — ou retire — le badge « star » à un membre.
 *
 * Réservé à l'administration, et **manuel par nature** : la star n'est jamais
 * automatique. On peut désigner le membre par son pseudo ou par son
 * identifiant.
 *
 * `isStar` n'est modifiable que par ce chemin : les règles Firestore le gèlent
 * sur toute écriture client, comme le rôle et le badge fondateur.
 *
 * @param {Object} req La requête.
 * @param {Object} res La réponse.
 * @return {Promise<void>}
 */
// ============================================================================
// BADGE FONDATEUR
// ============================================================================

/** Où se règle l'ouverture de la fenêtre des fondateurs. */
const REGLAGES_BADGES = () => db.collection("config").doc("badges");

/**
 * Pose le badge « fondateur » à la création d'un compte, selon un réglage tenu
 * côté serveur.
 *
 * Pourquoi ici et pas dans l'application : c'était le client qui écrivait
 * `isFounder: true` à l'inscription. Deux conséquences, toutes deux mauvaises.
 * D'abord, fermer la fenêtre demandait de modifier le code **et** que chacun
 * mette son application à jour — une version ancienne aurait continué d'en
 * distribuer indéfiniment. Ensuite, rien n'empêchait un client modifié de se
 * l'attribuer quand il voulait.
 *
 * Ce déclencheur fait autorité : il écrase ce que le client a écrit. Fermer la
 * fenêtre prend effet **immédiatement**, pour toutes les versions installées.
 *
 * En cas de doute — réglage absent ou illisible — on n'attribue rien. Un badge
 * donné à tort se retire à la main ; c'est le sens le moins coûteux à corriger.
 */
exports.onUserCreated = onDocumentCreated("users/{userId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  let ouverte = false;
  try {
    const reglages = await REGLAGES_BADGES().get();
    ouverte = reglages.exists && reglages.data().foundersOpen === true;
  } catch (error) {
    console.error("Réglages badges illisibles, aucun fondateur attribué:", error);
  }

  const dejaPose = snap.data().isFounder === true;
  if (dejaPose === ouverte) return; // rien à corriger

  await snap.ref.update({isFounder: ouverte});
  console.log(
    `Badge fondateur ${ouverte ? "attribué" : "retiré"} à ${event.params.userId}`,
  );
});

/**
 * Ouvre ou ferme la fenêtre des fondateurs. Réservé à l'administration.
 *
 * Il n'y a **pas** de fermeture automatique, ni de date, ni de quota : la
 * décision est un choix de lancement, pas une règle qu'on puisse deviner à
 * l'avance. Elle se prend à la main, et le changement est immédiat.
 */
exports.setFoundersOpen = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), true)) return;

  const {open} = req.body || {};
  if (typeof open !== "boolean") {
    return res.status(400).json({
      success: false,
      error: {code: "params_invalid", message: "open (booléen) est requis"},
    });
  }

  await REGLAGES_BADGES().set({
    foundersOpen: open,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: decoded.uid,
  }, {merge: true});

  console.log(`Fenêtre fondateurs ${open ? "ouverte" : "fermée"} par ${decoded.uid}`);
  return res.status(200).json({success: true, data: {foundersOpen: open}});
});

/**
 * Crédite un porte-monnaie à la main, quand un paiement a échoué à se
 * confirmer.
 *
 * Il arrive qu'une passerelle encaisse sans jamais nous prévenir. Sans ce
 * chemin, la seule issue était d'envoyer l'argent par mobile money, hors du
 * système : aucune trace, aucun solde juste, et un litige impossible à
 * reconstituer six mois plus tard.
 *
 * Tout est enregistré : qui a crédité, quand, pourquoi, et en regard de quelle
 * transaction bloquée. Un geste commercial doit être aussi traçable qu'un
 * paiement — c'est même là que la trace compte le plus, puisque c'est un humain
 * qui décide.
 *
 * Réservé à l'administration, et plafonné : une erreur de frappe ne doit pas
 * pouvoir créditer un million.
 */
const CREDIT_MANUEL_MAX_XOF = 500000;

exports.creditManuel = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), true)) return;

  const {userId, username, amountXof, reason, relatedReference} = req.body || {};
  const montant = Math.round(Number(amountXof));

  if (!Number.isFinite(montant) || montant <= 0 ||
      montant > CREDIT_MANUEL_MAX_XOF) {
    return res.status(400).json({
      success: false,
      error: {
        code: "params_invalid",
        message: `Montant invalide (1 à ${CREDIT_MANUEL_MAX_XOF} FCFA)`,
      },
    });
  }
  if (!reason || String(reason).trim().length < 5) {
    return res.status(400).json({
      success: false,
      error: {
        code: "params_invalid",
        message: "Un motif d'au moins 5 caractères est requis",
      },
    });
  }
  if (!userId && !username) {
    return res.status(400).json({
      success: false,
      error: {code: "params_invalid", message: "userId ou username requis"},
    });
  }

  // Résoudre le pseudo si besoin.
  let uid = userId;
  if (!uid) {
    const nom = String(username).trim();
    const doc = await db.collection("usernames").doc(nom).get();
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: {code: "not_found", message: `Aucun membre « ${nom} »`},
      });
    }
    uid = doc.data().userId;
  }

  const reference = "TX-MAN-" + Date.now();
  const userRef = db.collection("users").doc(uid);

  try {
    let pseudo = null;

    await db.runTransaction(async (dbTx) => {
      const userDoc = await dbTx.get(userRef);
      if (!userDoc.exists) throw new Error("Membre introuvable");

      const donnees = userDoc.data();
      pseudo = donnees.username || null;
      const portefeuille = donnees.wallet || {};
      const disponible = Number(portefeuille.availableAmount || 0);

      dbTx.update(userRef, {
        wallet: buildWalletUpdate(portefeuille, {
          availableAmount: disponible + montant,
        }),
      });

      // La trace. Le type `recharge` la fait apparaître au relevé du membre
      // comme une entrée d'argent — ce qu'elle est — tandis que les champs
      // `manual`, `adminId` et `reason` disent, pour nous, d'où elle vient.
      dbTx.set(db.collection("transactions").doc(reference), {
        reference: reference,
        userId: uid,
        amount: montant,
        paymentMethod: "manual",
        status: "completed",
        type: "recharge",
        manual: true,
        adminId: decoded.uid,
        reason: String(reason).trim(),
        relatedReference: relatedReference || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(
        `Crédit manuel : ${montant} FCFA à ${uid} par ${decoded.uid} — ${reason}`,
    );
    return res.status(200).json({
      success: true,
      data: {userId: uid, username: pseudo, amountXof: montant, reference},
    });
  } catch (error) {
    console.error("Erreur creditManuel:", error);
    return res.status(500).json({
      success: false,
      error: {code: "failed", message: error.message},
    });
  }
});

exports.setUserStar = onRequest(async (req, res) => {
  const decoded = await authenticate(req, res);
  if (!decoded) return;
  if (refuseRole(res, await roleOf(decoded.uid), true)) return;

  const {userId, username, star} = req.body || {};
  if (typeof star !== "boolean" || (!userId && !username)) {
    return res.status(400).json({
      success: false,
      error: {
        code: "params_invalid",
        message: "star (booléen) et userId ou username sont requis",
      },
    });
  }

  // Résoudre le pseudo en identifiant si besoin : la collection `usernames`
  // fait exactement ce lien.
  let uid = userId;
  if (!uid) {
    const nom = String(username).trim();
    const doc = await db.collection("usernames").doc(nom).get();
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: {code: "not_found", message: `Aucun membre « ${nom} »`},
      });
    }
    uid = doc.data().userId;
  }

  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();
  if (!userDoc.exists) {
    return res.status(404).json({
      success: false,
      error: {code: "not_found", message: "Membre introuvable"},
    });
  }

  await userRef.update({
    isStar: star,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return res.json({
    success: true,
    data: {
      userId: uid,
      username: userDoc.data().username || null,
      isStar: star,
    },
  });
});
