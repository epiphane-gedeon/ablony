/**
 * Reprise : recopie la vignette de l'annonce sur les reçus qui n'en ont pas.
 *
 * `productImage` n'a été ajouté au reçu qu'à partir du 16 septembre 2026. Les
 * commandes antérieures s'affichent donc sans image dans « Ventes et achats »,
 * et une liste de vignettes grises se reconnaît mal.
 *
 * Recopiée plutôt que lue à l'affichage : ce serait une lecture d'annonce par
 * ligne, pour une image qui de toute façon ne change plus une fois l'article
 * vendu. Et l'annonce peut disparaître, pas le reçu.
 *
 * Idempotent : relancé, il ne trouve plus rien.
 *
 *   node functions/scripts/backfill_receipt_image.js [--dry-run]
 */

const admin = require("firebase-admin");
const serviceAccount = require("../../tools/service-account.json");

admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
const db = admin.firestore();

const ESSAI = process.argv.includes("--dry-run");

(async () => {
  const snap = await db.collection("receipts").get();
  const aFaire = [];
  let sansAnnonce = 0;

  for (const doc of snap.docs) {
    const r = doc.data();
    if (r.productImage) continue;
    if (!r.productId) {
      sansAnnonce += 1;
      continue;
    }
    const p = await db.collection("products").doc(r.productId).get();
    const image = p.exists ? (p.data().imageUrls || [])[0] : null;
    if (!image) {
      sansAnnonce += 1;
      continue;
    }
    aFaire.push({ref: doc.ref, id: doc.id, image, titre: r.productTitle || ""});
  }

  console.log(`${snap.size} reçus · ${aFaire.length} à compléter` +
    (sansAnnonce ? ` · ${sansAnnonce} sans image retrouvable` : ""));

  if (ESSAI) {
    for (const f of aFaire.slice(0, 5)) {
      console.log(`  ${f.id}  ${f.titre.slice(0, 40)}`);
    }
    console.log("\n--dry-run : rien n'a été écrit.");
    process.exit(0);
  }
  if (aFaire.length === 0) process.exit(0);

  for (let i = 0; i < aFaire.length; i += 500) {
    const lot = db.batch();
    for (const f of aFaire.slice(i, i + 500)) {
      lot.update(f.ref, {productImage: f.image});
    }
    await lot.commit();
  }
  console.log(`\n${aFaire.length} reçu(s) complété(s).`);
  process.exit(0);
})();
