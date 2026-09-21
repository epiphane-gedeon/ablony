/**
 * Reprise : renseigne `usernameLower` (copie minuscule du username) sur tous
 * les comptes, pour que la recherche de membres soit insensible à la casse.
 * Idempotent : ne réécrit que si absent ou différent.
 *   node functions/scripts/backfill_username_lower.js [--dry-run]
 */
const admin = require("firebase-admin");
const sa = require("../../tools/service-account.json");
admin.initializeApp({credential: admin.credential.cert(sa)});
const db = admin.firestore();
const ESSAI = process.argv.includes("--dry-run");
(async () => {
  const snap = await db.collection("users").get();
  const aFaire = snap.docs.filter((d) => {
    const u = d.data();
    return typeof u.username === "string" &&
      u.usernameLower !== u.username.toLowerCase();
  });
  console.log(`${snap.size} comptes · ${aFaire.length} à renseigner`);
  if (ESSAI) { console.log("--dry-run : rien écrit."); process.exit(0); }
  const batch = db.batch();
  aFaire.forEach((d) =>
    batch.update(d.ref, {usernameLower: d.data().username.toLowerCase()}));
  if (aFaire.length) await batch.commit();
  console.log(`✅ ${aFaire.length} mis à jour.`);
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
