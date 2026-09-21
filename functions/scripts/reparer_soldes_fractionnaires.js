/**
 * Répare les soldes de porte-monnaie devenus fractionnaires.
 *
 * Le XOF n'a pas de décimales. Un frais de protection non arrondi (ex : demi-
 * franc) avait pu débiter un `availableAmount` en 2522,5 et le figer en double.
 * Ce script arrondit à l'entier le plus proche tout `availableAmount` /
 * `pendingAmount` non entier. Idempotent : relançable sans effet.
 *
 *   node functions/scripts/reparer_soldes_fractionnaires.js            # scan (dry-run)
 *   node functions/scripts/reparer_soldes_fractionnaires.js --apply    # écrit
 */

const admin = require("firebase-admin");
const serviceAccount = require("../../tools/service-account.json");

admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
const db = admin.firestore();

const APPLIQUER = process.argv.includes("--apply");

function estFractionnaire(x) {
  return typeof x === "number" && Number.isFinite(x) && !Number.isInteger(x);
}

(async () => {
  const snap = await db.collection("users").get();
  const aReparer = [];

  for (const doc of snap.docs) {
    const w = doc.data().wallet || {};
    const dispo = Number(w.availableAmount);
    const attente = Number(w.pendingAmount);
    if (estFractionnaire(dispo) || estFractionnaire(attente)) {
      aReparer.push({
        id: doc.id,
        username: doc.data().username || "?",
        dispoAvant: w.availableAmount,
        dispoApres: Math.round(dispo || 0),
        attenteAvant: w.pendingAmount,
        attenteApres: Math.round(attente || 0),
      });
    }
  }

  console.log(`${snap.size} comptes scannés · ${aReparer.length} solde(s) fractionnaire(s)\n`);
  for (const r of aReparer) {
    console.log(`  ${r.username} (${r.id})`);
    if (estFractionnaire(Number(r.dispoAvant))) {
      console.log(`     available : ${r.dispoAvant} → ${r.dispoApres}`);
    }
    if (estFractionnaire(Number(r.attenteAvant))) {
      console.log(`     pending   : ${r.attenteAvant} → ${r.attenteApres}`);
    }
  }

  if (aReparer.length === 0) {
    console.log("Rien à réparer.");
    process.exit(0);
  }
  if (!APPLIQUER) {
    console.log("\n--dry-run : rien n'a été écrit. Relancer avec --apply pour corriger.");
    process.exit(0);
  }

  const batch = db.batch();
  for (const r of aReparer) {
    batch.update(db.collection("users").doc(r.id), {
      "wallet.availableAmount": r.dispoApres,
      "wallet.pendingAmount": r.attenteApres,
    });
  }
  await batch.commit();
  console.log(`\n✅ ${aReparer.length} solde(s) arrondi(s).`);
  process.exit(0);
})().catch((e) => {
  console.error("Erreur:", e);
  process.exit(1);
});
