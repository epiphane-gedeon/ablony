#!/usr/bin/env node
/**
 * Ouvre ou ferme la fenêtre d'attribution du badge Fondateur.
 *
 *   node functions/scripts/set_founders_window.js            (affiche l'état)
 *   node functions/scripts/set_founders_window.js fermer
 *   node functions/scripts/set_founders_window.js ouvrir
 *
 * **Pourquoi ce script existe alors que l'endpoint admin refuse d'ouvrir.**
 *
 * `setFoundersOpen` est volontairement à sens unique : une fois la rareté
 * annoncée aux membres, la rouvrir d'un clic détruirait la crédibilité de
 * toutes les promesses suivantes. Ce verrou protège d'une décision prise sur
 * un coup de tête un soir de lancement poussif.
 *
 * Mais avant toute annonce publique, fermer et rouvrir ne trompe personne —
 * c'est même nécessaire : les relecteurs de Google Play créent des comptes
 * pendant l'examen, et chacun consommerait une place destinée à un vrai
 * premier utilisateur.
 *
 * D'où ce script : il écrit directement en base, hors de l'interface. Le coût
 * d'ouverture devient « ouvrir un terminal et taper une commande » plutôt
 * qu'« appuyer sur un bouton ». Assez pour qu'aucune réouverture ne soit
 * accidentelle, assez peu pour qu'une décision réfléchie reste possible.
 *
 * **Après le lancement, ne plus rouvrir.** Une place de marché vit de la
 * crédibilité de ses promesses, et celle-ci est la première qu'on fait.
 */

const path = require("path");
const admin = require(path.join(__dirname, "..", "node_modules", "firebase-admin"));

admin.initializeApp({
  credential: admin.credential.cert(
      require(path.join(__dirname, "..", "..", "tools", "service-account.json")),
  ),
});
const db = admin.firestore();
const ref = db.doc("config/badges");

const action = process.argv[2];

(async () => {
  const avant = (await ref.get()).data() || {};
  const ouverte = avant.foundersOpen === true;
  const utilise = Number(avant.founderQuotaUsed || 0);
  const maximum = Number(avant.founderQuotaMax || 100);

  const etat = () => {
    console.log(`  fenêtre  : ${ouverte ? "OUVERTE" : "fermée"}`);
    console.log(`  quota    : ${utilise} / ${maximum} (${maximum - utilise} places)`);
  };

  if (!action) {
    etat();
    console.log("\n  fermer | ouvrir");
    process.exit(0);
  }

  if (!["fermer", "ouvrir"].includes(action)) {
    console.error(`Action inconnue : ${action}. Attendu : fermer | ouvrir`);
    process.exit(1);
  }

  const voulu = action === "ouvrir";
  if (voulu === ouverte) {
    console.log(`La fenêtre est déjà ${ouverte ? "ouverte" : "fermée"}.`);
    process.exit(0);
  }

  await ref.set({
    foundersOpen: voulu,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: "script",
  }, {merge: true});

  console.log(`Fenêtre ${voulu ? "OUVERTE" : "fermée"}.`);
  console.log(`  quota : ${utilise} / ${maximum}`);
  if (!voulu) {
    console.log("\n  Les nouveaux comptes ne reçoivent plus le badge.");
    console.log("  Ceux qui l'ont le gardent : le déclencheur ne s'exécute");
    console.log("  qu'à la création du compte.");
  } else {
    console.log("\n  À ne plus refermer puis rouvrir une fois la rareté");
    console.log("  annoncée publiquement.");
  }
  process.exit(0);
})().catch((e) => {
  console.error("Échec :", e.message);
  process.exit(1);
});
