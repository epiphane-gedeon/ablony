/**
 * Reprise : pose `status`, `moderationStatus` et `isListable` sur toutes les
 * annonces existantes.
 *
 * À lancer **avant** de publier la version de l'application qui interroge
 * `isListable` — sinon les listes reviennent vides pour tout le monde.
 *
 * Idempotent : relançable sans dommage. Les annonces déjà reprises sont
 * sautées, ce qui permet de le relancer après une interruption.
 *
 *   node functions/scripts/backfill_product_status.js [--dry-run]
 */

const admin = require("firebase-admin");
const serviceAccount = require("../../tools/service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

const ESSAI = process.argv.includes("--dry-run");
const LOT = 400;

/**
 * Déduit le cycle de vie depuis les trois booléens historiques.
 *
 * L'ordre porte la priorité : une annonce marquée vendue *et* masquée — ce
 * que l'ancien modèle n'empêchait pas — reste vendue.
 *
 * @param {Object} d Le document produit.
 * @return {string} active, reserved, sold ou hidden.
 */
function statusFromLegacy(d) {
  if (d.isSold === true) return "sold";
  if (d.isReserved === true) return "reserved";
  if (d.isHidden === true) return "hidden";
  return "active";
}

/**
 * Parcourt la collection et écrit les trois champs.
 *
 * @return {Promise<void>}
 */
async function reprendre() {
  // Les comptes suspendus ou bannis d'abord : leurs annonces ne doivent pas
  // devenir visibles, même un instant.
  const comptes = new Map();
  const utilisateurs = await db.collection("users")
      .where("accountStatus", "in", ["suspended", "banned"])
      .get()
  // Le champ `accountStatus` n'existe pas encore : l'absence est normale.
      .catch(() => ({docs: []}));
  for (const u of utilisateurs.docs) comptes.set(u.id, u.data().accountStatus);
  console.log(`${comptes.size} compte(s) suspendu(s) ou banni(s)`);

  let dernier = null;
  let vues = 0;
  let ecrites = 0;
  const bilan = {active: 0, reserved: 0, sold: 0, hidden: 0};

  for (;;) {
    let q = db.collection("products").orderBy("__name__").limit(LOT);
    if (dernier) q = q.startAfter(dernier);
    const page = await q.get();
    if (page.empty) break;

    const lot = db.batch();
    let n = 0;

    for (const doc of page.docs) {
      vues += 1;
      const d = doc.data();

      // Déjà repris : on saute, ce qui rend le script relançable.
      const dejaRepris = d.status && d.moderationStatus &&
        d.isListable !== undefined;
      if (dejaRepris) continue;

      const status = d.status || statusFromLegacy(d);
      const moderation = d.moderationStatus || "pending";
      const etatVendeur = comptes.get(d.sellerId) || "active";
      const isListable = status === "active" &&
        moderation !== "rejected" &&
        etatVendeur === "active";

      bilan[status] = (bilan[status] || 0) + 1;
      n += 1;
      if (!ESSAI) {
        lot.update(doc.ref, {status, moderationStatus: moderation, isListable});
      }
    }

    if (n > 0 && !ESSAI) await lot.commit();
    ecrites += n;
    dernier = page.docs[page.docs.length - 1];
    console.log(`  ${vues} vues, ${ecrites} reprises`);
    if (page.size < LOT) break;
  }

  console.log(`\n${ESSAI ? "[essai] " : ""}${vues} annonce(s) parcourue(s), ` +
    `${ecrites} reprise(s)`);
  console.log("Répartition :", bilan);
}

reprendre()
    .then(() => process.exit(0))
    .catch((e) => {
      console.error(e);
      process.exit(1);
    });
