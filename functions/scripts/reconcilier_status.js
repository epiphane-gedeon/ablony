/**
 * Rapproche `status` des booléens hérités.
 *
 * Depuis la reprise, toutes les annonces portent `status` — et `status` est
 * ce que lisent les listes, la fiche produit et `computeIsListable`. Une
 * écriture qui n'a basculé que `isSold`, `isReserved` ou `isHidden` n'a donc
 * rien changé : l'annonce est restée visible et affichée « en vente ».
 *
 * `onProductWritten` rattrape désormais ce cas à chaque écriture. Ce script
 * répare ce qui s'est écrit **avant** — il n'y a pas d'écriture rétroactive.
 *
 * Idempotent : relancé, il ne trouve plus rien.
 *
 *   node functions/scripts/reconcilier_status.js [--dry-run]
 */

const admin = require("firebase-admin");
const serviceAccount = require("../../tools/service-account.json");

admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
const db = admin.firestore();

const ESSAI = process.argv.includes("--dry-run");

/**
 * Le `status` que les booléens décrivent.
 *
 * L'ordre porte la priorité : vendu l'emporte sur masqué, qui l'emporte sur
 * réservé. C'est la même priorité que `statusFromLegacy`.
 *
 * @param {Object} p Le document produit.
 * @return {string} La valeur attendue de `status`.
 */
function attendu(p) {
  if (p.isSold) return "sold";
  // `archived` est un `hidden` terminal : ne pas le ramener à `hidden`.
  if (p.isHidden) return p.status === "archived" ? "archived" : "hidden";
  if (p.isReserved) return "reserved";
  // Une annonce sans booléen levé est en vente — sauf si elle est archivée,
  // état que les booléens ne savent pas exprimer.
  return p.status === "archived" ? "archived" : "active";
}

(async () => {
  const snap = await db.collection("products").get();
  const aCorriger = [];

  for (const doc of snap.docs) {
    const p = doc.data();
    // Une annonce sans `status` est encore lisible par `statusFromLegacy` :
    // le déclencheur s'en charge, rien à forcer ici.
    if (!p.status) continue;
    const cible = attendu(p);
    if (cible !== p.status) {
      aCorriger.push({id: doc.id, ref: doc.ref, de: p.status, vers: cible,
        titre: p.title || "(sans titre)"});
    }
  }

  console.log(`${snap.size} annonces · ${aCorriger.length} à corriger\n`);
  for (const c of aCorriger) {
    console.log(`  ${c.id}  ${c.de} → ${c.vers}   ${c.titre.slice(0, 50)}`);
  }

  if (ESSAI) {
    console.log("\n--dry-run : rien n'a été écrit.");
    process.exit(0);
  }
  if (aCorriger.length === 0) process.exit(0);

  // Par lots de 500, la limite d'une écriture groupée. Le déclencheur
  // recalculera `isListable` derrière chaque écriture.
  for (let i = 0; i < aCorriger.length; i += 500) {
    const lot = db.batch();
    for (const c of aCorriger.slice(i, i + 500)) {
      lot.update(c.ref, {status: c.vers});
    }
    await lot.commit();
  }
  console.log(`\n${aCorriger.length} annonce(s) corrigée(s).`);
  process.exit(0);
})();
