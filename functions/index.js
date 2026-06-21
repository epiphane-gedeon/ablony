const { setGlobalOptions } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
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

/**
 * 2. Initier un paiement / recharge GeniusPay
 */
exports.initiatePayment = onRequest(async (req, res) => {
  // Configuration CORS
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    res.status(204).send("");
    return;
  }

  const { amount, paymentMethod, phone, userId, email, name, description } = req.body;

  if (!amount || !paymentMethod || !userId) {
    return res.status(400).json({
      success: false,
      error: { message: "Paramètres requis manquants : amount, paymentMethod, userId" }
    });
  }

  try {
    // 1. Construire le corps de la requête GeniusPay (sans données sensibles comme l'UID utilisateur dans metadata)
    const requestBody = {
      amount: Number(amount),
      currency: "XOF",
      description: description || "Recharge portefeuille Ablony",
      metadata: {
        type: "recharge"
      }
    };

    // 2. Configurer le client si fourni (en omettant payment_method pour utiliser la page de checkout)
    if (phone || name || email) {
      requestBody.customer = {};
      if (phone) {
        requestBody.customer.phone = phone;
        requestBody.customer.country = "TG"; // Par défaut Togo
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

    // LOG DE DEBUG : voir exactement ce que GeniusPay renvoie
    console.log("[GeniusPay] Réponse brute complète:", JSON.stringify(result, null, 2));
    console.log("[GeniusPay] Champs URL:", {
      checkout_url: result.data?.checkout_url,
      payment_url: result.data?.payment_url,
      redirect_url: result.data?.redirect_url,
      url: result.data?.url,
    });

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
      type: "recharge",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection("transactions").doc(result.data.reference).set(transactionData);

    // 5. Renvoyer la réponse à l'application
    // On tente tous les champs URL possibles que GeniusPay peut renvoyer
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
        rawData: result.data // Temporaire pour debug, à retirer après validation
      }
    });

  } catch (error) {
    console.error("Erreur initiatePayment:", error);
    return res.status(500).json({
      success: false,
      error: { message: "Erreur interne du serveur lors de l'initiation du paiement" }
    });
  }
});

/**
 * 3. Webhook de GeniusPay
 */
exports.geniusPayWebhook = onRequest(async (req, res) => {
  const signature = req.headers["x-webhook-signature"];
  const timestamp = req.headers["x-webhook-timestamp"];
  const event = req.headers["x-webhook-event"];

  if (!signature || !timestamp || !event) {
    return res.status(400).json({ success: false, error: "Headers de sécurité manquants" });
  }

  const payload = req.body;
  // Utiliser req.rawBody s'il est présent pour garantir la chaîne brute exacte envoyée par le serveur
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

    // Si c'est un ping de test ou si aucune référence n'est fournie (ex: bouton de test du dashboard)
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
      // Renvoyer 200 OK pour acquitter la réception même si la transaction n'existe pas localement
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

    // Traiter les événements
    if (event === "payment.success" && status === "completed") {
      const userId = transaction.userId;
      const amount = Number(transaction.amount);

      // Créditer le solde de l'utilisateur dans une transaction atomique Firestore
      const userRef = db.collection("users").doc(userId);

      await db.runTransaction(async (dbTx) => {
        const userDoc = await dbTx.get(userRef);
        if (!userDoc.exists) {
          throw new Error(`Utilisateur introuvable : ${userId}`);
        }

        const userData = userDoc.data();
        const currentWallet = userData.wallet || {};
        const currentAvailable = Number(currentWallet.availableAmount || 0);

        // Mettre à jour le solde disponible
        dbTx.update(userRef, {
          "wallet.availableAmount": currentAvailable + amount,
          "wallet.updatedAt": admin.firestore.FieldValue.serverTimestamp()
        });

        // Mettre à jour la transaction
        dbTx.update(db.collection("transactions").doc(transactionRef), {
          status: "completed",
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      console.log(`✅ Recharge réussie de ${amount} FCFA pour l'utilisateur ${userId}`);

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
