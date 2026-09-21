/**
 * Migration vers la nouvelle arborescence de catégories.
 *
 * À lancer APRÈS `node tools/import_to_firestore.js`, qui écrit le nouvel
 * arbre mais ne supprime rien : `.set()` n'efface pas les documents devenus
 * inutiles, et les annonces déjà publiées continueraient de pointer vers des
 * sous-catégories disparues — invisibles dans l'app, impossibles à filtrer.
 *
 * Deux gestes :
 *   1. réaffecter les annonces dont la sous-catégorie a changé d'identifiant ;
 *   2. supprimer les sous-catégories qui ne sont plus dans l'arbre.
 *
 * Le script est idempotent : le relancer ne fait rien de plus.
 *
 *   node tools/migrer_taxonomie.js            (simulation, n'écrit rien)
 *   node tools/migrer_taxonomie.js --appliquer
 */
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const APPLIQUER = process.argv.includes("--appliquer");

// Anciens identifiants → leur équivalent dans le nouvel arbre.
const RENOMMAGES = {
  chemise_femme: "chemisier_femme", // « Chemise » → « Chemise & chemisier »
  robe_femme: "robe_jour_femme", // la robe quitte « Bas » pour « Robes »
  sac_femme: "sac_main_femme", // « Sac » → « Sac à main »
  casquette_femme: "chapeau_femme", // fusionné dans « Chapeau & bonnet »
  haut_femme: "hauts_femme", // niveau intermédiaire renommé
  haut_homme: "hauts_homme",
};

admin.initializeApp({
  credential: admin.credential.cert(
    require(path.join(__dirname, "service-account.json")),
  ),
});
const db = admin.firestore();

async function main() {
  const arbre = JSON.parse(
    fs.readFileSync(path.join(__dirname, "seed_data/subcategories.json")),
  );
  const valides = new Set(arbre.map((s) => s.id));

  console.log(APPLIQUER ? "▶ APPLICATION\n" : "▶ SIMULATION (rien ne sera écrit)\n");

  // ── 1. Les annonces ───────────────────────────────────────────────────
  const produits = await db.collection("products").get();
  let deplaces = 0;
  let orphelins = 0;

  for (const doc of produits.docs) {
    const sub = doc.data().subcategoryId;
    if (!sub) continue;

    const cible = RENOMMAGES[sub];
    if (cible) {
      console.log(`  ${doc.id} : ${sub} → ${cible}`);
      if (APPLIQUER) await doc.ref.update({subcategoryId: cible});
      deplaces++;
    } else if (!valides.has(sub)) {
      // Rien ne dit vers quoi la déplacer : on le signale plutôt que de
      // choisir à l'aveugle, une annonce mal rangée étant pire qu'une alerte.
      console.log(`  ⚠️  ${doc.id} : « ${sub} » inconnue et sans équivalent`);
      orphelins++;
    }
  }
  console.log(`\n  ${deplaces} annonce(s) réaffectée(s), ${orphelins} sans équivalent\n`);

  // ── 2. Les sous-catégories périmées ───────────────────────────────────
  const enBase = await db
    .collection("config").doc("subcategories").collection("items").get();
  let supprimees = 0;

  for (const doc of enBase.docs) {
    if (valides.has(doc.id)) continue;
    console.log(`  suppression : ${doc.id}`);
    if (APPLIQUER) await doc.ref.delete();
    supprimees++;
  }
  console.log(`\n  ${supprimees} sous-catégorie(s) périmée(s)\n`);

  if (!APPLIQUER) console.log("Relancez avec --appliquer pour écrire.");
  process.exit(0);
}

main().catch((e) => {
  console.error("Échec :", e.message);
  process.exit(1);
});
