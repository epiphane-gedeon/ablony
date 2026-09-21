/**
 * Remet la base à blanc pour repartir sur des données propres.
 *
 * Ce qui est CONSERVÉ, et pourquoi :
 *   users       — demandé : les comptes restent
 *   usernames   — les réservations de pseudo sont adossées aux comptes ;
 *                 les effacer libérerait des pseudos encore portés
 *   config      — l'arborescence des catégories et les attributs
 *   relayPoints — les points relais sont de la configuration d'exploitation,
 *                 pas des données de test
 *
 * Tout le reste est du contenu produit pendant les essais.
 *
 * La suppression est récursive : une conversation porte ses messages en
 * sous-collection, qu'un simple `delete()` laisserait orphelins et invisibles.
 *
 *   node tools/vider_base.js              (simulation)
 *   node tools/vider_base.js --appliquer
 */
const admin = require("firebase-admin");
const path = require("path");

const APPLIQUER = process.argv.includes("--appliquer");

const CONSERVEES = new Set(["users", "usernames", "config", "relayPoints"]);

admin.initializeApp({
  credential: admin.credential.cert(
    require(path.join(__dirname, "service-account.json")),
  ),
});
const db = admin.firestore();

async function main() {
  console.log(APPLIQUER ? "▶ APPLICATION\n" : "▶ SIMULATION (rien ne sera supprimé)\n");

  const collections = await db.listCollections();
  let total = 0;

  console.log("  CONSERVÉ");
  for (const c of collections) {
    if (!CONSERVEES.has(c.id)) continue;
    const n = (await c.count().get()).data().count;
    console.log(`    ${c.id.padEnd(22)} ${n} document(s)`);
  }

  console.log("\n  SUPPRIMÉ");
  for (const c of collections) {
    if (CONSERVEES.has(c.id)) continue;
    const n = (await c.count().get()).data().count;
    total += n;
    console.log(`    ${c.id.padEnd(22)} ${n} document(s)`);
    if (APPLIQUER) {
      // recursiveDelete emporte aussi les sous-collections (les messages
      // d'une conversation, par exemple).
      await db.recursiveDelete(c);
    }
  }

  console.log(`\n  ${total} document(s) ${APPLIQUER ? "supprimés" : "à supprimer"}`);
  if (!APPLIQUER) console.log("\nRelancez avec --appliquer pour supprimer.");
  else console.log("\n⚠️  Les compteurs des comptes (ventes, note, abonnés) et\n" +
    "   les soldes de porte-monnaie n'ont PAS été touchés : ils portent\n" +
    "   encore les valeurs des tests.");
  process.exit(0);
}

main().catch((e) => {
  console.error("Échec :", e.message);
  process.exit(1);
});
