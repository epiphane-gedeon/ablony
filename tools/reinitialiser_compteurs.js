/**
 * Remet à zéro les compteurs des comptes après un nettoyage de la base.
 *
 * Ces champs sont **dénormalisés** : ils recopient sur le compte un nombre
 * calculé ailleurs (annonces, ventes, avis, abonnés, avertissements). Une fois
 * les collections vidées, ils décrivent des choses qui n'existent plus — un
 * vendeur noté 3,6 sur 5 avis dont aucun n'est consultable.
 *
 * Ce qui n'est PAS touché par défaut :
 *   wallet       — les soldes, laissés en place à la demande
 *   boostCredits — c'est aussi un solde : des boosts achetés d'avance
 *   identité     — pseudo, e-mail, pays, rôle, badges fondateur et star
 *
 * L'option `--soldes` remet en plus les porte-monnaie et les crédits de boost
 * à zéro. À garder pour le jour de la mise en production : de l'argent de test
 * encore présent au passage en clés live deviendrait de vraies demandes de
 * retrait, à payer pour de bon.
 *
 *   node tools/reinitialiser_compteurs.js              (simulation)
 *   node tools/reinitialiser_compteurs.js --appliquer
 *   node tools/reinitialiser_compteurs.js --appliquer --soldes
 */
const admin = require("firebase-admin");
const path = require("path");

const APPLIQUER = process.argv.includes("--appliquer");
const SOLDES = process.argv.includes("--soldes");

/// Les compteurs recopiés depuis d'autres collections.
const COMPTEURS = {
  productsCount: 0,
  salesCount: 0,
  rating: 0,
  reviewsCount: 0,
  followersCount: 0,
  followingCount: 0,
  warningCount: 0,
};

admin.initializeApp({
  credential: admin.credential.cert(
    require(path.join(__dirname, "service-account.json")),
  ),
});
const db = admin.firestore();

async function main() {
  console.log(APPLIQUER ? "▶ APPLICATION" : "▶ SIMULATION (rien ne sera écrit)");
  console.log(SOLDES
    ? "   soldes et crédits de boost : REMIS À ZÉRO\n"
    : "   soldes et crédits de boost : conservés\n");

  const comptes = await db.collection("users").get();
  let touches = 0;

  for (const doc of comptes.docs) {
    const donnees = doc.data();
    const maj = {};

    for (const [champ, zero] of Object.entries(COMPTEURS)) {
      if (Number(donnees[champ] || 0) !== zero) maj[champ] = zero;
    }

    if (SOLDES) {
      const w = donnees.wallet;
      if (w && (Number(w.availableAmount || 0) !== 0 ||
                Number(w.pendingAmount || 0) !== 0)) {
        // On remet les montants à zéro sans écraser le reste du
        // porte-monnaie : l'identité déclarée (nom, date de naissance) et
        // l'activation ont été saisies par la personne, pas produites par les
        // tests.
        maj.wallet = {...w, availableAmount: 0, pendingAmount: 0};
      }
      if (Number(donnees.boostCredits || 0) !== 0) maj.boostCredits = 0;
    }

    if (Object.keys(maj).length === 0) continue;

    const resume = Object.entries(maj)
      .map(([k, v]) => (k === "wallet" ? "wallet(soldes)" : k))
      .join(", ");
    console.log(`  ${(donnees.username || doc.id).padEnd(20)} → ${resume}`);
    if (APPLIQUER) await doc.ref.update(maj);
    touches++;
  }

  console.log(`\n  ${touches} compte(s) ${APPLIQUER ? "mis à jour" : "à mettre à jour"}`);
  if (!APPLIQUER) console.log("\nRelancez avec --appliquer pour écrire.");
  process.exit(0);
}

main().catch((e) => {
  console.error("Échec :", e.message);
  process.exit(1);
});
