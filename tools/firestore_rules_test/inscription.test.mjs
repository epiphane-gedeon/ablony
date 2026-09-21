/**
 * La création de profil, telle que `completeUserProfile` l'exécute : une
 * transaction qui écrit users/{uid} et usernames/{username}. Jouée pour un
 * compte Google et un compte e-mail.
 */
import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { doc, setDoc, runTransaction } from "firebase/firestore";

const RULES = new URL("../../firestore.rules", import.meta.url).pathname;
let ok = 0, ko = 0;
async function cas(nom, fn) {
  try { await fn(); console.log(`   ✓ ${nom}`); ok++; }
  catch (e) { console.log(`   ✗ ${nom}\n       ${String(e.message).split("\n")[0]}`); ko++; }
}

const env = await initializeTestEnvironment({
  projectId: "ablony-rules-test",
  firestore: { rules: readFileSync(RULES, "utf8"), host: "127.0.0.1",
    port: Number(process.env.FIRESTORE_EMULATOR_PORT ?? 8099) },
});
await env.clearFirestore();

// Un compte Google : le token porte l'email Google.
const UID = "google-user";
const EMAIL = "nouveau@gmail.com";
const ctx = env.authenticatedContext(UID, { email: EMAIL });
const db = ctx.firestore();

const profil = (extra = {}) => ({
  uid: UID,
  email: EMAIL,
  username: "kodjo",
  authProvider: "google",
  country: "TG",
  acceptedTerms: true,
  acceptedTermsDate: new Date().toISOString(),
  marketingEmailsEnabled: false,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  isVerified: true,
  isActive: true,
  productsCount: 0, salesCount: 0, rating: 0, reviewsCount: 0,
  followersCount: 0, followingCount: 0,
  ...extra,
});

console.log("\nCréation de profil Google");

await cas("créer users/{uid} avec l'email du token", () =>
  assertSucceeds(setDoc(doc(db, "users", UID), profil())),
);

await cas("réserver usernames/{username}", () =>
  assertSucceeds(setDoc(doc(db, "usernames", "kodjo"), {
    userId: UID, createdAt: new Date().toISOString(),
  })),
);

console.log("\nLes pièges possibles");

await env.clearFirestore();
await cas("email du doc ≠ email du token → refusé", () =>
  assertFails(setDoc(doc(db, "users", UID), profil({ email: "autre@gmail.com" }))),
);

await env.clearFirestore();
await cas("CGU non acceptées → refusé", () =>
  assertFails(setDoc(doc(db, "users", UID), profil({ acceptedTerms: false }))),
);

await env.clearFirestore();
await cas("country en objet plutôt qu'en chaîne", () =>
  assertSucceeds(setDoc(doc(db, "users", UID), profil({
    country: { code: "TG", name: "Togo" },
  }))),
);

await env.cleanup();
console.log(`\n${ok} réussi(s), ${ko} échoué(s)`);
process.exit(ko === 0 ? 0 : 1);
