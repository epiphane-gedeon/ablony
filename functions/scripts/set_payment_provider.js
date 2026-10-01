#!/usr/bin/env node
/**
 * Bascule le fournisseur de paiement actif.
 *
 *   node functions/scripts/set_payment_provider.js nyole
 *   node functions/scripts/set_payment_provider.js geniuspay
 *   node functions/scripts/set_payment_provider.js            (affiche l'état)
 *
 * C'est le levier de retour arrière décrit dans
 * docs/produit/25-integration-nyole.md : il ne touche qu'un champ, et les
 * paiements déjà lancés chez l'autre fournisseur restent confirmables (chaque
 * transaction porte sa provenance). Le serveur met jusqu'à 60 s à le voir,
 * le temps que son cache expire.
 *
 * L'onglet admin viendra plus tard ; ce script évite d'attendre pour tester.
 */

const path = require("path");
const admin = require(path.join(__dirname, "..", "node_modules", "firebase-admin"));

const VALIDES = ["geniuspay", "nyole"];
const voulu = process.argv[2];

if (voulu && !VALIDES.includes(voulu)) {
  console.error(`Fournisseur inconnu : ${voulu}. Attendu : ${VALIDES.join(" | ")}`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(
      require(path.join(__dirname, "..", "..", "tools", "service-account.json")),
  ),
});

const ref = admin.firestore().doc("config/app");

(async () => {
  const avant = await ref.get();
  const actuel = (avant.data() || {}).paymentProvider || "geniuspay (par défaut)";

  if (!voulu) {
    console.log(`Fournisseur actuel : ${actuel}`);
    process.exit(0);
  }

  await ref.set({
    paymentProvider: voulu,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  console.log(`Fournisseur : ${actuel} → ${voulu}`);
  console.log("Le serveur le prendra en compte d'ici 60 s (cache).");
  process.exit(0);
})().catch((e) => {
  console.error("Échec :", e.message);
  process.exit(1);
});
