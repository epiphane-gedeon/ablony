/**
 * Le blocage entre membres.
 *
 * Masquer le champ de saisie ne bloque personne : un client modifié écrit
 * directement dans Firestore. C'est donc ici, et seulement ici, que le blocage
 * existe réellement.
 */
import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc } from "firebase/firestore";

const RULES = new URL("../../firestore.rules", import.meta.url).pathname;
const ANA = "ana";
const BRUNO = "bruno";
const CONV = "conv-ana-bruno";

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
await env.withSecurityRulesDisabled(async (c) => {
  await setDoc(doc(c.firestore(), "conversations", CONV), {
    participants: [ANA, BRUNO],
    participantDetails: {},
    productId: "p1",
    productDetails: {},
    unreadCount: 0,
    createdAt: "2026-01-01T00:00:00Z",
    updatedAt: "2026-01-01T00:00:00Z",
  });
});

const message = (uid) => ({
  senderId: uid,
  type: "text",
  text: "bonjour",
  timestamp: "2026-01-01T00:00:00Z",
  read: false,
});

console.log("\nAvant tout blocage");

await cas("Ana écrit à Bruno", () =>
  assertSucceeds(
    setDoc(doc(db(ANA), `conversations/${CONV}/messages`, "m1"), message(ANA)),
  ),
);
await cas("Bruno répond", () =>
  assertSucceeds(
    setDoc(doc(db(BRUNO), `conversations/${CONV}/messages`, "m2"), message(BRUNO)),
  ),
);

console.log("\nPoser un blocage");

await cas("Ana bloque Bruno", () =>
  assertSucceeds(
    setDoc(doc(db(ANA), "blocks", `${ANA}_${BRUNO}`), {
      blockerId: ANA,
      blockedId: BRUNO,
      createdAt: "2026-01-02T00:00:00Z",
    }),
  ),
);

await cas("on ne se bloque pas soi-même", () =>
  assertFails(
    setDoc(doc(db(ANA), "blocks", `${ANA}_${ANA}`), {
      blockerId: ANA,
      blockedId: ANA,
      createdAt: "2026-01-02T00:00:00Z",
    }),
  ),
);

await cas("on ne bloque pas au nom d'un autre", () =>
  assertFails(
    setDoc(doc(db(BRUNO), "blocks", `${ANA}_${BRUNO}`), {
      blockerId: ANA,
      blockedId: BRUNO,
      createdAt: "2026-01-02T00:00:00Z",
    }),
  ),
);

await cas("l'identifiant doit correspondre au contenu", () =>
  assertFails(
    setDoc(doc(db(ANA), "blocks", "nimporte-quoi"), {
      blockerId: ANA,
      blockedId: BRUNO,
      createdAt: "2026-01-02T00:00:00Z",
    }),
  ),
);

console.log("\nCe que le blocage empêche");

await cas("Ana ne peut plus écrire", () =>
  assertFails(
    setDoc(doc(db(ANA), `conversations/${CONV}/messages`, "m3"), message(ANA)),
  ),
);

// Le point qui compte : le blocage coupe dans les deux sens. Sinon Ana
// écrirait sans pouvoir recevoir de réponse — un avantage asymétrique étrange.
await cas("Bruno non plus, alors qu'il n'a rien bloqué", () =>
  assertFails(
    setDoc(doc(db(BRUNO), `conversations/${CONV}/messages`, "m4"), message(BRUNO)),
  ),
);

await cas("l'historique reste lisible pour Ana", () =>
  assertSucceeds(getDoc(doc(db(ANA), `conversations/${CONV}/messages`, "m1"))),
);

await cas("et pour Bruno — il peut servir de preuve", () =>
  assertSucceeds(getDoc(doc(db(BRUNO), `conversations/${CONV}/messages`, "m2"))),
);

console.log("\nCe que le blocage ne dit pas");

await cas("Bruno ne peut pas lire le blocage qui le vise", () =>
  assertFails(getDoc(doc(db(BRUNO), "blocks", `${ANA}_${BRUNO}`))),
);

await cas("Ana voit le sien", () =>
  assertSucceeds(getDoc(doc(db(ANA), "blocks", `${ANA}_${BRUNO}`))),
);

await cas("Bruno ne peut pas l'effacer", () =>
  assertFails(deleteDoc(doc(db(BRUNO), "blocks", `${ANA}_${BRUNO}`))),
);

await cas("un blocage ne se modifie pas, il se retire", () =>
  assertFails(
    setDoc(
      doc(db(ANA), "blocks", `${ANA}_${BRUNO}`),
      { blockedId: "quelqu-un-d-autre" },
      { merge: true },
    ),
  ),
);

console.log("\nDébloquer");

await cas("Ana débloque", () =>
  assertSucceeds(deleteDoc(doc(db(ANA), "blocks", `${ANA}_${BRUNO}`))),
);

await cas("la parole revient aux deux", async () => {
  await assertSucceeds(
    setDoc(doc(db(ANA), `conversations/${CONV}/messages`, "m5"), message(ANA)),
  );
  await assertSucceeds(
    setDoc(doc(db(BRUNO), `conversations/${CONV}/messages`, "m6"), message(BRUNO)),
  );
});

await env.cleanup();
console.log(`\n${ok} réussi(s), ${ko} échoué(s)`);
process.exit(ko === 0 ? 0 : 1);
