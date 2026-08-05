const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const crypto = require("crypto");

// Initialiser Firebase Admin
admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10 });

// Configuration de GeniusPay
// Ces clés seront lues depuis les variables d'environnement
const GENIUSPAY_CONFIG = {
  API_KEY: process.env.GENIUSPAY_API_KEY || "pk_sandbox_votre_cle_publique",
  API_SECRET: process.env.GENIUSPAY_API_SECRET || "sk_sandbox_votre_cle_secrete",
  WEBHOOK_SECRET: process.env.GENIUSPAY_WEBHOOK_SECRET || "whsec_votre_secret_webhook",
  BASE_URL: "https://pay.genius.ci/api/v1/merchant"
};

// Configuration du boost de produit (prix fixe, imposé côté serveur —
// jamais celui envoyé par le client — et durée du boost).
// Garder en phase avec BOOST_PRICE_XOF côté client (lib/features/product/...).
const BOOST_CONFIG = {
  PRICE_XOF: 500,
  DURATION_HOURS: 48
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
 * @returns {Object} Objet wallet complet prêt pour un `update({wallet: ...})`
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
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
  transactionRef, paymentMethod, totalAmount
}) {
  const buyerRef = db.collection("users").doc(buyerId);
  const sellerRef = db.collection("users").doc(sellerId);
  const productRef = db.collection("products").doc(productId);
  const txDocRef = db.collection("transactions").doc(transactionRef);

  const result = await db.runTransaction(async (dbTx) => {
    // ── PHASE LECTURES (toutes les lectures d'abord, règle Firestore) ──────
    const txDoc      = await dbTx.get(txDocRef);
    const buyerDoc   = await dbTx.get(buyerRef);
    const sellerDoc  = await dbTx.get(sellerRef);
    const productDoc = await dbTx.get(productRef);

    // Vérifier idempotence
    if (txDoc.exists && txDoc.data().status === "completed") {
      console.log(`Transaction ${transactionRef} déjà complétée, ignorée.`);
      return { alreadyCompleted: true };
    }

    // Vérifier l'existence des documents
    if (!buyerDoc.exists) throw new Error("Acheteur introuvable");
    if (!sellerDoc.exists) throw new Error("Vendeur introuvable");

    // Lire les données nécessaires
    const buyerData     = buyerDoc.data();
    const buyerWallet   = buyerData.wallet || {};
    const buyerAvailable = Number(buyerWallet.availableAmount || 0);

    const sellerData   = sellerDoc.data();
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
          availableAmount: buyerAvailable - walletDeduction
        })
      });
    }

    // 2. Créditer le pendingAmount du vendeur (TOUJOURS, quel que soit le moyen de paiement)
    dbTx.update(sellerRef, {
      wallet: buildWalletUpdate(sellerWallet, {
        pendingAmount: sellerPending + productPrice
      })
    });

    // 3. Marquer le produit comme vendu
    dbTx.update(productRef, {
      isSold: true,
      soldAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 4. Créer ou mettre à jour la transaction comme complétée
    if (txDoc.exists) {
      // Transaction déjà créée (par initiatePayment), on la met à jour
      dbTx.update(txDocRef, {
        status: "completed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    return {
      alreadyCompleted: false,
      productTitle: productDoc.exists ? (productDoc.data().title || "Produit") : "Produit"
    };
  });

  console.log(`✅ Achat finalisé : acheteur=${buyerId}, vendeur=${sellerId}, produit=${productId}, prix=${productPrice}, walletDéduit=${walletDeduction}, ref=${transactionRef}`);

  // Notifications + reçu : best-effort, ne doit jamais faire échouer le paiement déjà finalisé
  if (!result.alreadyCompleted) {
    try {
      await notifyPurchase({
        buyerId, sellerId, productId,
        productTitle: result.productTitle,
        productPrice, totalAmount, paymentMethod,
        transactionRef
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
async function finalizeBoost({ userId, productId, walletDeduction, transactionRef }) {
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
          availableAmount: userAvailable - walletDeduction
        })
      });
    }

    // 2. Marquer le produit comme boosté
    const boostExpiresAt = new Date(Date.now() + BOOST_CONFIG.DURATION_HOURS * 60 * 60 * 1000);
    dbTx.update(productRef, {
      isBoosted: true,
      boostExpiresAt: admin.firestore.Timestamp.fromDate(boostExpiresAt),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 3. Créer ou mettre à jour la transaction comme complétée
    if (txDoc.exists) {
      dbTx.update(txDocRef, {
        status: "completed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

  console.log(`✅ Boost finalisé : utilisateur=${userId}, produit=${productId}, ref=${transactionRef}`);
}

// ============================================================================
// NOTIFICATIONS + REÇU (déclenchés après un achat finalisé)
// ============================================================================

/**
 * Envoie une notification push à un utilisateur via ses tokens FCM enregistrés
 * (users/{uid}.fcmTokens). Nettoie automatiquement les tokens expirés/invalides.
 */
async function sendPushToUser(uid, { title, body }, data) {
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) return;

  const tokens = userDoc.data().fcmTokens || [];
  if (tokens.length === 0) return;

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data || {}).map(([k, v]) => [k, String(v)])
    )
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
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens)
    });
  }
}

/**
 * Crée le reçu, les notifications in-app (acheteur + vendeur) et envoie les push
 * correspondants suite à un achat finalisé. Les IDs sont dérivés de transactionRef
 * pour rester idempotents en cas de rejeu (webhook + confirmPayment par exemple).
 */
async function notifyPurchase({
  buyerId, sellerId, productId, productTitle, productPrice,
  totalAmount, paymentMethod, transactionRef
}) {
  const receiptRef = db.collection("receipts").doc(transactionRef);
  const sellerNotifRef = db.collection("notifications").doc(`${transactionRef}_seller`);
  const buyerNotifRef = db.collection("notifications").doc(`${transactionRef}_buyer`);
  // Le QR affiché au vendeur ne contient que cet id opaque, jamais la
  // transactionRef directement : indirection nécessaire pour la remise en
  // main propre, cf. collection "qrcodes" ci-dessous.
  const qrCodeRef = db.collection("qrcodes").doc();

  const now = admin.firestore.FieldValue.serverTimestamp();

  await qrCodeRef.set({
    transactionRef,
    sellerId,
    buyerId,
    createdAt: now
  });

  await receiptRef.set({
    transactionRef,
    buyerId,
    sellerId,
    productId,
    productTitle,
    productPrice,
    totalAmount,
    paymentMethod,
    deliveryConfirmed: false,
    qrCodeId: qrCodeRef.id,
    createdAt: now
  });

  await sellerNotifRef.set({
    userId: sellerId,
    type: "purchase_received",
    title: "Nouvelle vente !",
    body: `Votre article "${productTitle}" vient d'être vendu pour ${productPrice} FCFA.`,
    data: { productId, transactionRef, buyerId },
    read: false,
    createdAt: now
  });

  await buyerNotifRef.set({
    userId: buyerId,
    type: "purchase_confirmed",
    title: "Achat confirmé",
    body: `Vous avez acheté "${productTitle}". Votre reçu est disponible.`,
    data: { productId, transactionRef, receiptId: transactionRef, sellerId },
    read: false,
    createdAt: now
  });

  await Promise.all([
    sendPushToUser(
      sellerId,
      {
        title: "Nouvelle vente !",
        body: `Votre article "${productTitle}" vient d'être vendu pour ${productPrice} FCFA.`
      },
      { type: "purchase_received", productId, transactionRef }
    ),
    sendPushToUser(
      buyerId,
      {
        title: "Achat confirmé",
        body: `Vous avez acheté "${productTitle}". Votre reçu est disponible.`
      },
      { type: "purchase_confirmed", productId, transactionRef, receiptId: transactionRef }
    )
  ]);

  console.log(`🔔 Notifications + reçu envoyés pour ${transactionRef}`);
}

// ============================================================================
// 1. INITIER UN PAIEMENT
// ============================================================================

exports.initiatePayment = onRequest(async (req, res) => {
  // Configuration CORS
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.status(204).send("");
    return;
  }

  let { amount, paymentMethod, phone, userId, email, name, description, type, productId, sellerId, productPrice, walletDeduction } = req.body;

  if (!amount || !paymentMethod || !userId) {
    return res.status(400).json({
      success: false,
      error: { message: "Paramètres requis manquants : amount, paymentMethod, userId" }
    });
  }

  if (type === "purchase" && (!productId || !sellerId)) {
    return res.status(400).json({
      success: false,
      error: { message: "Paramètres requis manquants pour un achat : productId, sellerId" }
    });
  }

  if (type === "boost") {
    if (!productId) {
      return res.status(400).json({
        success: false,
        error: { message: "Paramètre requis manquant pour un boost : productId" }
      });
    }

    const productSnap = await db.collection("products").doc(productId).get();
    if (!productSnap.exists) {
      return res.status(404).json({
        success: false,
        error: { message: "Produit introuvable" }
      });
    }
    const productData = productSnap.data();
    if (productData.sellerId !== userId) {
      return res.status(403).json({
        success: false,
        error: { message: "Seul le vendeur peut booster ce produit" }
      });
    }
    if (productData.isSold) {
      return res.status(400).json({
        success: false,
        error: { message: "Impossible de booster un produit déjà vendu" }
      });
    }

    // Le prix du boost est toujours imposé par le serveur, jamais par le client
    amount = BOOST_CONFIG.PRICE_XOF;
    if (walletDeduction != null) walletDeduction = Math.min(Number(walletDeduction), amount);
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
          transactionRef: reference
        });

        return res.status(200).json({
          success: true,
          data: {
            reference: reference,
            status: "completed",
            completed: true
          }
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
        totalAmount: Number(amount)
      });

      return res.status(200).json({
        success: true,
        data: {
          reference: reference,
          status: "completed",
          completed: true
        }
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
      description: description || (type === "purchase" ? "Achat article Ablony" : type === "boost" ? "Boost produit Ablony" : "Recharge portefeuille Ablony"),
      success_url: "https://geniuspaywebhook-mahukqtfea-uc.a.run.app/success",
      error_url: "https://geniuspaywebhook-mahukqtfea-uc.a.run.app/cancel",
      metadata: {
        type: type || "recharge",
        productId: productId || null,
        sellerId: sellerId || null,
        buyerId: userId
      }
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
        "Content-Type": "application/json"
      },
      body: JSON.stringify(requestBody)
    });

    const result = await response.json();

    console.log("[GeniusPay] Réponse brute complète:", JSON.stringify(result, null, 2));

    if (!response.ok || !result.success) {
      return res.status(response.status || 500).json({
        success: false,
        error: result.error || { message: "Erreur lors de l'appel à GeniusPay" }
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
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection("transactions").doc(result.data.reference).set(transactionData);

    // 5. Renvoyer la réponse à l'application
    const paymentUrl = result.data.checkout_url
      || result.data.payment_url
      || result.data.redirect_url
      || result.data.url
      || null;

    console.log("[GeniusPay] URL finale utilisée:", paymentUrl);

    return res.status(201).json({
      success: true,
      data: {
        reference: result.data.reference,
        status: result.data.status,
        paymentUrl: paymentUrl,
      }
    });

  } catch (error) {
    console.error("Erreur initiatePayment:", error);
    return res.status(500).json({
      success: false,
      error: { message: error.message || "Erreur interne du serveur lors de l'initiation du paiement" }
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

  const { reference } = req.body;

  if (!reference) {
    return res.status(400).json({
      success: false,
      error: { message: "Paramètre requis manquant : reference" }
    });
  }

  try {
    // 1. Récupérer la transaction dans Firestore
    const txSnapshot = await db.collection("transactions").doc(reference).get();
    if (!txSnapshot.exists) {
      return res.status(404).json({
        success: false,
        error: { message: `Transaction ${reference} introuvable` }
      });
    }

    const transaction = txSnapshot.data();

    // Si déjà complétée, retourner directement succès (idempotence)
    if (transaction.status === "completed") {
      return res.status(200).json({
        success: true,
        data: { status: "completed", message: "Transaction déjà complétée" }
      });
    }

    // 2. Vérifier le statut auprès de GeniusPay
    const gpResponse = await fetch(`${GENIUSPAY_CONFIG.BASE_URL}/payments/${reference}`, {
      method: "GET",
      headers: {
        "X-API-Key": GENIUSPAY_CONFIG.API_KEY,
        "X-API-Secret": GENIUSPAY_CONFIG.API_SECRET,
        "Content-Type": "application/json"
      }
    });

    const gpResult = await gpResponse.json();
    console.log("[confirmPayment] Statut GeniusPay:", JSON.stringify(gpResult, null, 2));

    const gpStatus = gpResult.data?.status;

    // Si le paiement n'est pas confirmé par GeniusPay, on refuse
    if (gpStatus !== "completed" && gpStatus !== "success" && gpStatus !== "successful") {
      // En sandbox, on peut être plus permissif (le statut peut être null)
      const isSandbox = reference.startsWith("SANDBOX_");
      if (!isSandbox) {
        return res.status(400).json({
          success: false,
          error: { message: `Paiement non confirmé par GeniusPay (statut: ${gpStatus})` }
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
        totalAmount: Number(transaction.amount)
      });

    } else if (transaction.type === "boost") {
      await finalizeBoost({
        userId: transaction.userId,
        productId: transaction.productId,
        walletDeduction: Number(transaction.walletDeduction || 0),
        transactionRef: reference
      });

    } else {
      // Recharge de portefeuille
      await finalizeRecharge(transaction.userId, Number(transaction.amount), reference);
    }

    return res.status(200).json({
      success: true,
      data: { status: "completed" }
    });

  } catch (error) {
    console.error("Erreur confirmPayment:", error);
    return res.status(500).json({
      success: false,
      error: { message: error.message || "Erreur lors de la confirmation du paiement" }
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
        availableAmount: currentAvailable + amount
      })
    });

    // Mettre à jour la transaction
    dbTx.update(txDocRef, {
      status: "completed",
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
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
    return res.status(400).json({ success: false, error: "Headers de sécurité manquants" });
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
      return res.status(401).json({ success: false, error: "Signature invalide" });
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
        message: "Webhook de test ou de ping reçu avec succès"
      });
    }

    // Récupérer la transaction dans Firestore
    const txSnapshot = await db.collection("transactions").doc(transactionRef).get();
    if (!txSnapshot.exists) {
      console.warn(`Transaction introuvable dans Firestore : ${transactionRef}`);
      return res.status(200).json({
        success: true,
        message: `Transaction ${transactionRef} introuvable, ignorée`
      });
    }

    const transaction = txSnapshot.data();

    // Si la transaction est déjà traitée, on renvoie simplement 200
    if (transaction.status === "completed" || transaction.status === "failed") {
      return res.status(200).json({ success: true, message: "Transaction déjà traitée" });
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
          totalAmount: amount
        });

      } else if (transaction.type === "boost") {
        // Utiliser la fonction partagée finalizeBoost
        await finalizeBoost({
          userId: transaction.userId,
          productId: transaction.productId,
          walletDeduction: Number(transaction.walletDeduction || 0),
          transactionRef: transactionRef
        });

      } else {
        // Utiliser la fonction partagée finalizeRecharge
        await finalizeRecharge(transaction.userId, amount, transactionRef);
      }

    // ============ PAIEMENT ÉCHOUÉ ============
    } else if (event === "payment.failed" || status === "failed" || status === "expired") {
      await db.collection("transactions").doc(transactionRef).update({
        status: "failed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      console.log(`❌ Échec de la transaction ${transactionRef}`);
    }

    return res.status(200).json({ success: true });

  } catch (error) {
    console.error("Erreur traitement Webhook GeniusPay:", error);
    return res.status(500).json({ success: false, error: error.message });
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
  const sellerUsername = sellerDoc.exists
    ? (sellerDoc.data().username || "Un vendeur que vous suivez")
    : "Un vendeur que vous suivez";

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
      data: { productId, sellerId },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });
  await batch.commit();

  await Promise.all(
    followersSnapshot.docs.map((followDoc) => {
      const followerId = followDoc.data().followerId;
      if (!followerId) return Promise.resolve();
      return sendPushToUser(
        followerId,
        { title, body },
        { type: "new_product_from_followed", productId, sellerId }
      ).catch((err) => console.error(`⚠️ Push new_product vers ${followerId} échoué:`, err));
    })
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
      reviewsCount: newCount
    });
  });

  console.log(`⭐ Note moyenne recalculée pour le vendeur ${sellerId} (avis ${event.params.reviewId})`);
});

// ============================================================================
// CONFIRMATION DE RÉCEPTION (QR code scanné par l'acheteur)
// ============================================================================

/**
 * L'acheteur scanne le QR code affiché par le vendeur pour confirmer la
 * réception de l'article. Débloque le paiement : pendingAmount du vendeur
 * → availableAmount. Authentification requise via un ID token Firebase
 * (header Authorization: Bearer <token>), pour garantir que seul le vrai
 * acheteur de la transaction peut déclencher le déblocage des fonds.
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
    return res.status(401).json({ success: false, error: { message: "Authentification requise" } });
  }

  let decodedToken;
  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    return res.status(401).json({ success: false, error: { message: "Token invalide" } });
  }

  const buyerId = decodedToken.uid;
  const { qrCodeId, transactionRef: transactionRefInput } = req.body;

  if (!qrCodeId && !transactionRefInput) {
    return res.status(400).json({ success: false, error: { message: "Paramètre requis manquant : qrCodeId ou transactionRef" } });
  }

  try {
    // Deux façons d'identifier la commande à confirmer : le QR scanné (qui ne
    // contient que l'id de la collection "qrcodes", jamais la transactionRef
    // directement) ou, en secours, la référence du reçu saisie manuellement
    // par l'acheteur. Dans les deux cas, l'appartenance à l'acheteur est
    // vérifiée plus bas via tx.userId dans la transaction Firestore.
    let transactionRef = transactionRefInput;
    if (qrCodeId) {
      const qrDoc = await db.collection("qrcodes").doc(qrCodeId).get();
      if (!qrDoc.exists) {
        return res.status(404).json({ success: false, error: { message: "Code QR invalide ou expiré" } });
      }
      const qrData = qrDoc.data();
      if (qrData.buyerId !== buyerId) {
        return res.status(403).json({ success: false, error: { message: "Ce code QR ne correspond pas à votre achat" } });
      }
      transactionRef = qrData.transactionRef;
    }

    const txRef = db.collection("transactions").doc(transactionRef);

    const result = await db.runTransaction(async (dbTx) => {
      const txDoc = await dbTx.get(txRef);
      if (!txDoc.exists) throw new Error("Commande introuvable");

      const tx = txDoc.data();
      if (tx.type !== "purchase") throw new Error("Cette transaction n'est pas un achat");
      if (tx.status !== "completed") throw new Error("Cet achat n'a pas encore été finalisé");
      if (tx.userId !== buyerId) throw new Error("Vous n'êtes pas l'acheteur de cette commande");

      if (tx.deliveryConfirmed === true) {
        return { alreadyConfirmed: true, sellerId: tx.sellerId, productId: tx.productId };
      }

      const sellerRef = db.collection("users").doc(tx.sellerId);
      const sellerDoc = await dbTx.get(sellerRef);
      if (!sellerDoc.exists) throw new Error("Vendeur introuvable");

      const sellerWallet = sellerDoc.data().wallet || {};
      const pending = Number(sellerWallet.pendingAmount || 0);
      const available = Number(sellerWallet.availableAmount || 0);
      const amount = Number(tx.productPrice || tx.amount);

      dbTx.update(sellerRef, {
        wallet: buildWalletUpdate(sellerWallet, {
          pendingAmount: Math.max(0, pending - amount),
          availableAmount: available + amount
        })
      });

      dbTx.update(txRef, {
        deliveryConfirmed: true,
        deliveryConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Le reçu (lisible par le client) reflète aussi l'état de confirmation
      dbTx.update(db.collection("receipts").doc(transactionRef), {
        deliveryConfirmed: true
      });

      return {
        alreadyConfirmed: false,
        sellerId: tx.sellerId,
        productId: tx.productId
      };
    });

    if (!result.alreadyConfirmed) {
      try {
        await sendPushToUser(
          result.sellerId,
          {
            title: "Paiement débloqué",
            body: "L'acheteur a confirmé la réception. Les fonds sont maintenant disponibles dans votre porte-monnaie."
          },
          { type: "delivery_confirmed", productId: result.productId, transactionRef }
        );
      } catch (notifyError) {
        console.error(`⚠️ Push delivery_confirmed échoué pour ${result.sellerId}:`, notifyError);
      }
    }

    console.log(`✅ Réception confirmée pour ${transactionRef} (déjà confirmée: ${result.alreadyConfirmed})`);

    return res.status(200).json({
      success: true,
      data: { alreadyConfirmed: result.alreadyConfirmed }
    });
  } catch (error) {
    console.error("Erreur confirmDelivery:", error);
    return res.status(400).json({
      success: false,
      error: { message: error.message || "Erreur lors de la confirmation de réception" }
    });
  }
});
