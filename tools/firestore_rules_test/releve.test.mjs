/**
 * Qui lit quoi : relevé, reçus, colis, rôle.
 *
 * Une règle Firestore autorise ou refuse un document **entier**, jamais un
 * champ. Ce qu'on vérifie ici, c'est donc surtout où vit chaque information —
 * parce que c'est le seul levier disponible.
 */
import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { collection, doc, getDoc, getDocs, setDoc, updateDoc } from "firebase/firestore";

const RULES = new URL("../../firestore.rules", import.meta.url).pathname;
const ACHETEUR = "acheteur";
const VENDEUR = "vendeur";
const TIERS = "tiers";
const CODE = "AB-K7M2P-X4R9T";
const REF = "TX-2026-0001";

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
await env.withSecurityRulesDisabled(async (ctx) => {
  const f = ctx.firestore();
  await setDoc(doc(f, "transactions", REF), {
    reference: REF,
    userId: ACHETEUR,
    sellerId: VENDEUR,
    amount: 13000,
    type: "purchase",
    status: "completed",
    // C'est ce champ qui décide de tout : il porte le domicile de l'acheteur.
    delivery: { method: "home", address: { street: "12 rue des Cocotiers" } },
  });
  await setDoc(doc(f, "receipts", REF), {
    transactionRef: REF, buyerId: ACHETEUR, sellerId: VENDEUR,
    productTitle: "Robe wax taille M", productPrice: 12000, totalAmount: 13000,
    deliveryMethod: "home", parcelCode: CODE,
  });
  await setDoc(doc(f, "parcels", CODE), {
    code: CODE, transactionRef: REF, buyerId: ACHETEUR, sellerId: VENDEUR,
    productTitle: "Robe wax taille M", method: "home", status: "in_transit",
  });
  await setDoc(doc(f, "parcels", CODE, "private", "destination"), {
    buyerId: ACHETEUR,
    address: { street: "12 rue des Cocotiers", city: "Lomé" },
  });
  await setDoc(doc(f, "users", ACHETEUR), {
    uid: ACHETEUR, email: "a@ablony.net", username: "acheteur",
    authProvider: "email", country: "TG", acceptedTerms: true,
    createdAt: "2026-01-01T00:00:00Z", role: "member",
  });
});

console.log("\nLe relevé du porte-monnaie");

await cas("l'acheteur lit ses propres opérations", () =>
  assertSucceeds(getDoc(doc(db(ACHETEUR), "transactions", REF))),
);

await cas("le vendeur ne lit pas la transaction de son acheteur", () =>
  assertFails(getDoc(doc(db(VENDEUR), "transactions", REF))),
);

await cas("un tiers non plus", () =>
  assertFails(getDoc(doc(db(TIERS), "transactions", REF))),
);

await cas("personne n'écrit une transaction depuis le client", () =>
  assertFails(
    setDoc(doc(db(ACHETEUR), "transactions", "TX-FAUX"), {
      userId: ACHETEUR, amount: 999999, type: "recharge", status: "completed",
    }),
  ),
);

await cas("ni ne marque la sienne « completed »", () =>
  assertFails(
    updateDoc(doc(db(ACHETEUR), "transactions", REF), { status: "completed" }),
  ),
);

console.log("\nLe vendeur voit sa vente, pas le domicile de son acheteur");

await cas("le vendeur lit le reçu de sa vente", () =>
  assertSucceeds(getDoc(doc(db(VENDEUR), "receipts", REF))),
);

await cas("le reçu ne porte plus d'adresse", async () => {
  const reçu = await getDoc(doc(db(VENDEUR), "receipts", REF));
  const données = reçu.data();
  if ("delivery" in données || "address" in données) {
    throw new Error("le reçu porte encore la livraison");
  }
});

await cas("le vendeur suit le colis", () =>
  assertSucceeds(getDoc(doc(db(VENDEUR), "parcels", CODE))),
);

await cas("mais pas sa destination", () =>
  assertFails(getDoc(doc(db(VENDEUR), "parcels", CODE, "private", "destination"))),
);

await cas("l'acheteur, lui, lit sa propre adresse", () =>
  assertSucceeds(getDoc(doc(db(ACHETEUR), "parcels", CODE, "private", "destination"))),
);

await cas("un tiers ne lit ni le colis ni sa destination", async () => {
  await assertFails(getDoc(doc(db(TIERS), "parcels", CODE)));
  await assertFails(getDoc(doc(db(TIERS), "parcels", CODE, "private", "destination")));
});

console.log("\nLe rôle ne se donne pas soi-même");

await cas("un membre ne se déclare pas agent", () =>
  assertFails(updateDoc(doc(db(ACHETEUR), "users", ACHETEUR), { role: "agent" })),
);

await cas("ni administrateur", () =>
  assertFails(updateDoc(doc(db(ACHETEUR), "users", ACHETEUR), { role: "admin" })),
);

await cas("il peut toujours modifier son profil", () =>
  assertSucceeds(updateDoc(doc(db(ACHETEUR), "users", ACHETEUR), { city: "Lomé" })),
);


console.log("\nLes retraits");

await env.clearFirestore();
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), "withdrawals", "WD-1"), {
    id: "WD-1", userId: ACHETEUR, amountXof: 15000, feeXof: 250,
    netAmountXof: 14750, method: "tmoney",
    // Le numéro complet vit sur le document : c'est celui du demandeur.
    destination: "+22890123456", destinationMasked: "+228••••3456",
    status: "requested",
  });
});

await cas("on lit ses propres demandes", () =>
  assertSucceeds(getDoc(doc(db(ACHETEUR), "withdrawals", "WD-1"))),
);

await cas("celles des autres, non", () =>
  assertFails(getDoc(doc(db(TIERS), "withdrawals", "WD-1"))),
);

await cas("personne ne crée une demande depuis le client", () =>
  assertFails(
    setDoc(doc(db(ACHETEUR), "withdrawals", "WD-FAUX"), {
      userId: ACHETEUR, amountXof: 999999, status: "requested",
    }),
  ),
);

await cas("ni ne se déclare payé", () =>
  assertFails(
    updateDoc(doc(db(ACHETEUR), "withdrawals", "WD-1"), {status: "paid"}),
  ),
);

await env.cleanup();
console.log(`\n${réussis} réussi(s), ${échoués} échoué(s)`);
process.exit(échoués === 0 ? 0 : 1);
