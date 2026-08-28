// Script ponctuel : ajoute isReserved/isHidden (défaut false) sur les
// documents `products` créés avant l'introduction de ces champs.
//
// Pourquoi c'était cassé : toutes les requêtes de listing (getProducts,
// getProductsByCategory, searchProducts, getActiveBoostedProducts) filtrent
// désormais `.where('isReserved', isEqualTo: false).where('isHidden',
// isEqualTo: false)`. Un filtre d'égalité Firestore ne matche JAMAIS un
// document où le champ est absent — seulement les documents où il vaut
// explicitement `false`. Les produits créés avant ce changement de schéma
// n'ont pas ces champs en base et disparaissaient donc silencieusement de
// tous les listings, alors qu'ils ne sont ni vendus, ni réservés, ni
// masqués.
//
// N'écrase jamais une valeur existante : seuls les champs manquants sont
// complétés.
//
// Usage : node functions/scripts/backfill_product_visibility.js

const admin = require("firebase-admin");
const serviceAccount = require("../../tools/service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function main() {
  const snapshot = await db.collection("products").get();
  console.log(`Produits trouvés : ${snapshot.size}`);

  let batch = db.batch();
  let opsInBatch = 0;
  let fixedCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const patch = {};
    if (data.isReserved === undefined) patch.isReserved = false;
    if (data.isHidden === undefined) patch.isHidden = false;

    if (Object.keys(patch).length > 0) {
      batch.update(doc.ref, patch);
      opsInBatch++;
      fixedCount++;
      if (opsInBatch >= 450) {
        await batch.commit();
        batch = db.batch();
        opsInBatch = 0;
      }
    }
  }

  if (opsInBatch > 0) {
    await batch.commit();
  }

  console.log(`✅ ${fixedCount} produit(s) corrigé(s) (isReserved/isHidden ajoutés).`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Échec du backfill:", error);
    process.exit(1);
  });
