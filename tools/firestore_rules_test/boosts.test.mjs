/**
 * Le solde de boosts (`boostCredits`) ne se crédite pas depuis le client.
 *
 * Il est posé côté serveur — achat d'un lot (`finalizeBoostPack`) ou, plus
 * tard, abonnement premium — et dépensé côté serveur (`applyBoost`). Un client
 * qui écrit son propre document ne doit pas pouvoir gonfler ce solde.
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
import { doc, setDoc, updateDoc } from "firebase/firestore";

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

const env = await initializeTestEnvironment({
  projectId: "ablony-rules-test",
  firestore: {
    rules: readFileSync(RULES, "utf8"),
    host: "127.0.0.1",
    port: Number(process.env.FIRESTORE_EMULATOR_PORT ?? 8099),
  },
});

const db = (uid) => env.authenticatedContext(uid).firestore();

async function poser(données) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), "users", ALICE), données);
  });
}

console.log("\nLe solde de boosts ne se crédite pas depuis le client");

await env.clearFirestore();
await poser(profil({ boostCredits: 2 }));

await cas("un utilisateur ne peut pas s'offrir des boosts", () =>
  assertFails(
    updateDoc(doc(db(ALICE), "users", ALICE), { boostCredits: 100 }),
  ),
);

await cas("ni un seul, discrètement", () =>
  assertFails(
    updateDoc(doc(db(ALICE), "users", ALICE), { boostCredits: 3 }),
  ),
);

await cas("ni s'en attribuer alors qu'il n'en avait aucun", async () => {
  await env.clearFirestore();
  await poser(profil()); // pas de champ boostCredits → absent, vaut 0
  await assertFails(
    updateDoc(doc(db(ALICE), "users", ALICE), { boostCredits: 5 }),
  );
});

await cas("ni créditer le solde de quelqu'un d'autre", async () => {
  await env.clearFirestore();
  await poser(profil({ boostCredits: 0 }));
  await assertFails(
    updateDoc(doc(db(BOB), "users", ALICE), { boostCredits: 10 }),
  );
});

console.log("\nCe qui doit continuer de marcher");

await env.clearFirestore();
await poser(profil({ boostCredits: 4 }));

await cas("modifier son profil en laissant le solde intact", () =>
  assertSucceeds(
    updateDoc(doc(db(ALICE), "users", ALICE), { city: "Lomé" }),
  ),
);

await cas("modifier son profil sans champ boostCredits dans la requête", async () => {
  await env.clearFirestore();
  await poser(profil({ boostCredits: 4 }));
  await assertSucceeds(
    updateDoc(doc(db(ALICE), "users", ALICE), { city: "Kara" }),
  );
});

console.log("\nEt le serveur, lui, écrit toujours");
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), "users", ALICE), profil({ boostCredits: 50 }));
});
console.log("   ✓ l'Admin SDK contourne ces règles (achat de lot, premium, applyBoost)");
réussis += 1;

await env.cleanup();
console.log(`\n${réussis} réussi(s), ${échoués} échoué(s)`);
process.exit(échoués === 0 ? 0 : 1);
