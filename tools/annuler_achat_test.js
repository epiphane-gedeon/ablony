/**
 * Efface les traces d'un achat de test et remet l'annonce en vente.
 *
 * Ce qui est supprimé : la transaction, son reçu, son colis et les
 * notifications qu'elle a produites.
 *
 * Ce qui est **remis en état plutôt que supprimé** : l'annonce. Elle existait
 * avant l'achat et n'en fait pas partie ; la détruire ferait perdre un travail
 * de saisie qu'on peut vouloir réutiliser pour le prochain essai. Elle repasse
 * simplement en vente.
 *
 * Ce qui n'est **pas** touché : les conversations. Un échange entre deux
 * personnes n'est pas une conséquence de l'achat, même s'il porte sur le même
 * article.
 *
 *   node tools/annuler_achat_test.js <reference>              (simulation)
 *   node tools/annuler_achat_test.js <reference> --appliquer
 */
const admin = require("firebase-admin");
const path = require("path");

const APPLIQUER = process.argv.includes("--appliquer");
const REFERENCE = process.argv.find((a) => a.startsWith("TX-"));

if (!REFERENCE) {
  console.error("Indiquez la référence de la transaction (TX-…).");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(
    require(path.join(__dirname, "service-account.json")),
  ),
});
const db = admin.firestore();

async function main() {
  console.log(APPLIQUER ? "▶ APPLICATION\n" : "▶ SIMULATION (rien ne sera écrit)\n");

  const txRef = db.collection("transactions").doc(REFERENCE);
  const tx = await txRef.get();
  if (!tx.exists) {
    console.error(`Transaction ${REFERENCE} introuvable.`);
    process.exit(1);
  }
  const productId = tx.data().productId;

  // ── À supprimer ───────────────────────────────────────────────────────
  const aSupprimer = [txRef];

  const recu = db.collection("receipts").doc(REFERENCE);
  if ((await recu.get()).exists) aSupprimer.push(recu);

  const colis = await db.collection("parcels")
      .where("transactionRef", "==", REFERENCE).get();
  colis.forEach((d) => aSupprimer.push(d.ref));

  const notifs = await db.collection("notifications").get();
  notifs.forEach((d) => {
    if (d.id.startsWith(REFERENCE)) aSupprimer.push(d.ref);
  });

  for (const ref of aSupprimer) {
    console.log(`  supprimer  ${ref.parent.id}/${ref.id}`);
    if (APPLIQUER) await ref.delete();
  }

  // ── À remettre en vente ───────────────────────────────────────────────
  if (productId) {
    const prod = db.collection("products").doc(productId);
    const snap = await prod.get();
    if (snap.exists && snap.data().isSold === true) {
      console.log(`\n  remettre en vente  products/${productId}` +
        ` ("${snap.data().title}")`);
      if (APPLIQUER) {
        await prod.update({
          status: "active",
          isSold: false,
          soldAt: admin.firestore.FieldValue.delete(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  }

  console.log(`\n  ${aSupprimer.length} document(s) ` +
    `${APPLIQUER ? "supprimés" : "à supprimer"}`);
  if (!APPLIQUER) console.log("\nRelancez avec --appliquer pour écrire.");
  process.exit(0);
}

main().catch((e) => {
  console.error("Échec :", e.message);
  process.exit(1);
});
