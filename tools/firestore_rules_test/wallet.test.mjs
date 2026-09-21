/**
 * Les soldes ne se réécrivent pas depuis le client.
 *
 * Ces tests tournent contre l'émulateur Firestore, qui applique les vraies
 * règles — pas une relecture de leur texte.
 */
import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";

const RULES = new URL("../../firestore.rules", import.meta.url).pathname;
const ALICE = "alice";
const BOB = "bob";

let réussis = 0;
let échoués = 0;

async function cas(nom, fn) {
  try {
    await fn();
    console.log(`   ✓ ${nom}`);
    réussis += 1;
  } catch (e) {
    console.log(`   ✗ ${nom}\n       ${String(e.message).split("\n")[0]}`);
    échoués += 1;
  }
}

const profil = (extra = {}) => ({
  uid: ALICE,
  email: "alice@ablony.net",
  username: "alice",
  authProvider: "email",
  country: "TG",
  acceptedTerms: true,
  createdAt: "2026-01-01T00:00:00Z",
  ...extra,
});

const porteMonnaie = (extra = {}) => ({
  firstName: "Alice",
  lastName: "Koffi",
  nationality: "TG",
  birthDate: "2000-01-01",
  availableAmount: 0,
  pendingAmount: 0,
  isActivated: true,
  ...extra,
});

const env = await initializeTestEnvironment({
  projectId: "ablony-rules-test",
  firestore: { rules: readFileSync(RULES, "utf8"), host: "127.0.0.1", port: Number(process.env.FIRESTORE_EMULATOR_PORT ?? 8099) },
});

const db = (uid) => env.authenticatedContext(uid).firestore();

async function poser(données) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), "users", ALICE), données);
  });
}

console.log("\nLe solde ne se réécrit pas depuis le client");

await env.clearFirestore();
await poser(profil({ wallet: porteMonnaie({ availableAmount: 5000 }) }));
await cas("un utilisateur ne peut pas gonfler son propre solde", () =>
  assertFails(
    updateDoc(doc(db(ALICE), "users", ALICE), {
      wallet: porteMonnaie({ availableAmount: 10_000_000 }),
    }),
  ),
);

await cas("ni le faire discrètement, d'un franc", () =>
  assertFails(
    updateDoc(doc(db(ALICE), "users", ALICE), {
      wallet: porteMonnaie({ availableAmount: 5001 }),
    }),
  ),
);

await cas("ni déplacer son pendingAmount vers le disponible", () =>
  assertFails(
    updateDoc(doc(db(ALICE), "users", ALICE), {
      wallet: porteMonnaie({ availableAmount: 5000, pendingAmount: 3000 }),
    }),
  ),
);

await cas("ni créditer celui de quelqu'un d'autre", () =>
  assertFails(
    updateDoc(doc(db(BOB), "users", ALICE), {
      wallet: porteMonnaie({ availableAmount: 999_999 }),
    }),
  ),
);

console.log("\nCe qui doit continuer de marcher");

await cas("modifier son identité en recopiant ses soldes", () =>
  assertSucceeds(
    updateDoc(doc(db(ALICE), "users", ALICE), {
      wallet: porteMonnaie({ firstName: "Alicia", availableAmount: 5000 }),
    }),
  ),
);

await env.clearFirestore();
await poser(profil());
await cas("activer son porte-monnaie pour la première fois", () =>
  assertSucceeds(
    updateDoc(doc(db(ALICE), "users", ALICE), { wallet: porteMonnaie() }),
  ),
);

await env.clearFirestore();
await poser(profil({ wallet: porteMonnaie({ isActivated: false, pendingAmount: 12000 }) }));
await cas("activer sans perdre une vente déjà en attente", () =>
  assertSucceeds(
    updateDoc(doc(db(ALICE), "users", ALICE), {
      wallet: porteMonnaie({ isActivated: true, pendingAmount: 12000 }),
    }),
  ),
);

await cas("modifier son profil sans toucher au porte-monnaie", () =>
  assertSucceeds(updateDoc(doc(db(ALICE), "users", ALICE), { city: "Lomé" })),
);

await env.clearFirestore();
await poser(profil({ followersCount: 3 }));
await cas("un tiers peut toujours s'abonner", () =>
  assertSucceeds(
    updateDoc(doc(db(BOB), "users", ALICE), { followersCount: 4 }),
  ),
);

console.log("\nEt le serveur, lui, écrit toujours");
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), "users", ALICE), profil({
    wallet: porteMonnaie({ availableAmount: 250_000 }),
  }));
});
await env.clearFirestore();
console.log("   ✓ l'Admin SDK contourne ces règles (c'est par là que passe l'argent)");
réussis += 1;

await env.cleanup();
console.log(`\n${réussis} réussi(s), ${échoués} échoué(s)`);
process.exit(échoués === 0 ? 0 : 1);
