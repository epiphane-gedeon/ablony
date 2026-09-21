/**
 * Reprise : passe tous les comptes existants en fondateurs.
 *
 * Tient la promesse faite aux premiers inscrits (« badge Fondateur »). Ne
 * touche que `isFounder`, et seulement s'il n'est pas déjà vrai — idempotent,
 * relançable sans effet.
 *
 *   node functions/scripts/backfill_founders.js [--dry-run]
 */

const admin = require("firebase-admin");
const serviceAccount = require("../../tools/service-account.json");

admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
const db = admin.firestore();

const ESSAI = process.argv.includes("--dry-run");

(async () => {
  const snap = await db.collection("users").get();
  const aFaire = snap.docs.filter((d) => d.data().isFounder !== true);

  console.log(`${snap.size} comptes · ${aFaire.length} à passer fondateurs`);

  if (ESSAI) {
    console.log("\n--dry-run : rien n'a été écrit.");
    process.exit(0);
  }
  if (aFaire.length === 0) process.exit(0);

  const now = admin.firestore.FieldValue.serverTimestamp();
  for (let i = 0; i < aFaire.length; i += 500) {
    const lot = db.batch();
    for (const doc of aFaire.slice(i, i + 500)) {
      lot.update(doc.ref, {isFounder: true, updatedAt: now});
    }
    await lot.commit();
  }
  console.log(`\n${aFaire.length} compte(s) passé(s) fondateurs.`);
  process.exit(0);
})();
