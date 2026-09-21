/**
 * Les signalements.
 *
 * Deux versions de l'application coexistent toujours : celle qu'on vient de
 * publier et celle qui reste installée pendant des semaines. Une règle qui
 * exige un champ que l'ancienne n'écrit pas ne durcit rien — elle empêche
 * simplement de signaler.
 */
import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from "firebase/firestore";

const RULES = new URL("../../firestore.rules", import.meta.url).pathname;
const AUTEUR = "auteur";
const VENDEUR = "vendeur";

let ok = 0;
let ko = 0;
async function cas(nom, fn) {
  try {
    await fn();
    console.log(`   ✓ ${nom}`);
    ok += 1;
  } catch (e) {
    console.log(`   ✗ ${nom}\n       ${String(e.message).split("\n")[0]}`);
    ko += 1;
  }
}

const env = await initializeTestEnvironment({
  projectId: "ablony-rules-test",
  firestore: {
    rules: readFileSync(RULES, "utf8"),
    host: "127.0.0.1",
    port: Number(process.env.FIRESTORE_EMULATOR_PORT ?? 8099),
  },
});

const db = (uid) => env.authenticatedContext(uid).firestore();
await env.clearFirestore();

// Exactement ce qu'écrit la version installée aujourd'hui : pas de `status`.
const ancienneVersion = {
  productId: "p1",
  productTitle: "Sac à main",
  sellerId: VENDEUR,
  reporterId: AUTEUR,
  reason: "counterfeit",
  createdAt: "2026-09-16T12:00:00Z",
};

const nouvelleVersion = { ...ancienneVersion, status: "open" };

console.log("\nLes deux versions de l'application doivent pouvoir signaler");

await cas("l'ancienne version, qui n'écrit pas `status`", () =>
  assertSucceeds(setDoc(doc(db(AUTEUR), "reports", "r1"), ancienneVersion)),
);

await cas("la nouvelle, qui l'écrit", () =>
  assertSucceeds(setDoc(doc(db(AUTEUR), "reports", "r2"), nouvelleVersion)),
);

await cas("un signalement visant un membre, sans annonce", () =>
  assertSucceeds(
    setDoc(doc(db(AUTEUR), "reports", "r3"), {
      productId: null,
      sellerId: VENDEUR,
      reporterId: AUTEUR,
      reason: "scam",
      status: "open",
      createdAt: "2026-09-16T12:00:00Z",
    }),
  ),
);

console.log("\nCe qui reste interdit");

await cas("se signaler soi-même", () =>
  assertFails(
    setDoc(doc(db(VENDEUR), "reports", "r4"), {
      ...nouvelleVersion,
      reporterId: VENDEUR,
    }),
  ),
);

await cas("signaler au nom d'un autre", () =>
  assertFails(setDoc(doc(db(VENDEUR), "reports", "r5"), nouvelleVersion)),
);

// Poser « reviewed » à la création, c'est déposer un signalement déjà clos :
// il n'apparaîtrait jamais dans la file, et le vendeur passerait entre les
// mailles sans que personne ne l'ait regardé.
await cas("naître déjà traité", () =>
  assertFails(
    setDoc(doc(db(AUTEUR), "reports", "r6"), {
      ...nouvelleVersion,
      status: "reviewed",
    }),
  ),
);

await cas("relire les signalements — même les siens", () =>
  assertFails(getDoc(doc(db(AUTEUR), "reports", "r1"))),
);

await cas("modifier un signalement déposé", () =>
  assertFails(updateDoc(doc(db(AUTEUR), "reports", "r1"), { reason: "other" })),
);

await cas("effacer un signalement déposé", () =>
  assertFails(deleteDoc(doc(db(AUTEUR), "reports", "r1"))),
);

await env.cleanup();
console.log(`\n${ok} réussi(s), ${ko} échoué(s)`);
process.exit(ko === 0 ? 0 : 1);
