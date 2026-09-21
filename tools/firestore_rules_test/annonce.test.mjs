/**
 * Le modèle d'une annonce : ce que le vendeur peut faire, et ce qu'il ne peut
 * pas.
 *
 * L'enjeu tient en une phrase : une décision de modération doit résister au
 * vendeur. Si celui-ci peut remettre son annonce en ligne d'un geste, tout le
 * dispositif est cosmétique.
 */
import { readFileSync } from "node:fs";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, setDoc, updateDoc } from "firebase/firestore";

const RULES = new URL("../../firestore.rules", import.meta.url).pathname;
const VENDEUR = "vendeur";
const TIERS = "tiers";

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

const annonce = (extra = {}) => ({
  title: "Robe wax taille M",
  description: "Portée deux fois.",
  price: 12000,
  imageUrls: ["https://x/1.webp"],
  condition: 1,
  sellerId: VENDEUR,
  categoryId: "c1",
  subcategoryId: "s1",
  status: "active",
  moderationStatus: "pending",
  isListable: true,
  createdAt: "2026-01-01T00:00:00Z",
  ...extra,
});

async function poser(id, extra = {}) {
  await env.withSecurityRulesDisabled(async (c) => {
    await setDoc(doc(c.firestore(), "products", id), annonce(extra));
  });
}

await env.clearFirestore();

console.log("\nCe que le vendeur peut faire");

await poser("p1");
await cas("modifier le prix de son annonce active", () =>
  assertSucceeds(updateDoc(doc(db(VENDEUR), "products", "p1"), { price: 9000 })),
);

await cas("la masquer lui-même", () =>
  assertSucceeds(
    updateDoc(doc(db(VENDEUR), "products", "p1"), { status: "hidden" }),
  ),
);

await poser("p2");
await cas("l'archiver — c'est ce que fait « Supprimer »", () =>
  assertSucceeds(
    updateDoc(doc(db(VENDEUR), "products", "p2"), { status: "archived" }),
  ),
);

console.log("\nCe que le vendeur ne peut pas faire");

await poser("p3", { status: "sold", isListable: false });
await cas("modifier une annonce vendue", () =>
  assertFails(updateDoc(doc(db(VENDEUR), "products", "p3"), { price: 1 })),
);

await cas("archiver une annonce vendue", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p3"), { status: "archived" }),
  ),
);

await poser("p4", { moderationStatus: "rejected", isListable: false });
await cas("remettre en ligne une annonce rejetée", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p4"), { status: "active" }),
  ),
);

await cas("s'auto-approuver", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p4"), {
      moderationStatus: "approved",
    }),
  ),
);

// La vraie attaque : une annonce invisible, dont le vendeur force le champ
// que le serveur calcule.
await poser("p5", { status: "hidden", isListable: false });
await cas("se rendre visible en forçant isListable", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p5"), { isListable: true }),
  ),
);

await cas("se rendre visible en repassant active ET en forçant le champ", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p5"), {
      status: "active",
      isListable: true,
    }),
  ),
);

await cas("repasser son annonce active sans toucher au champ calculé", () =>
  assertSucceeds(
    updateDoc(doc(db(VENDEUR), "products", "p5"), { status: "active" }),
  ),
);

await cas("effacer son annonce", () =>
  assertFails(deleteDoc(doc(db(VENDEUR), "products", "p5"))),
);

await cas("effacer celle d'un autre", () =>
  assertFails(deleteDoc(doc(db(TIERS), "products", "p5"))),
);

await cas("modifier celle d'un autre", () =>
  assertFails(updateDoc(doc(db(TIERS), "products", "p5"), { price: 1 })),
);

// ── Corriger, oui. Se blanchir, non. ────────────────────────────────────
//
// C'est ici que se joue la différence entre les deux degrés de gravité. Une
// photo floue se corrige ; une contrefaçon ne se corrige pas, elle se retire.
// Traiter les deux pareil, c'est soit bloquer un vendeur maladroit, soit
// laisser un contrefacteur republier.

console.log("\nUne annonce renvoyée pour correction");

await poser("p6", {
  moderationStatus: "rejected",
  reviewDecision: "correction",
  reviewReason: "blurry_photos",
  isListable: false,
});

await cas("le vendeur peut remplacer les photos", () =>
  assertSucceeds(
    updateDoc(doc(db(VENDEUR), "products", "p6"), {
      imageUrls: ["https://x/net.webp"],
    }),
  ),
);

await cas("il peut corriger le titre et le prix", () =>
  assertSucceeds(
    updateDoc(doc(db(VENDEUR), "products", "p6"), {
      title: "Robe wax taille M, photos refaites",
      price: 11000,
    }),
  ),
);

await cas("mais pas se déclarer approuvé au passage", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p6"), {
      title: "Robe corrigée",
      moderationStatus: "approved",
    }),
  ),
);

await cas("ni forcer sa remise en ligne", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p6"), {
      title: "Robe corrigée",
      isListable: true,
    }),
  ),
);

console.log("\nUne annonce retirée pour manquement");

await poser("p7", {
  moderationStatus: "rejected",
  reviewDecision: "violation",
  reviewReason: "counterfeit",
  isListable: false,
});

await cas("changer le titre ne la sauve pas", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p7"), { title: "Sac inspiré" }),
  ),
);

await cas("changer les photos non plus", () =>
  assertFails(
    updateDoc(doc(db(VENDEUR), "products", "p7"), {
      imageUrls: ["https://x/autre.webp"],
    }),
  ),
);

// ── Le compteur de vues ─────────────────────────────────────────────────
//
// Un chiffre de vanité montré au vendeur. N'importe quel visiteur peut
// l'incrémenter de 1 — mais de 1 seulement, et sans toucher à rien d'autre.

console.log("\nLe compteur de vues");

await poser("v1", { viewsCount: 4 });

await cas("un visiteur incrémente les vues de 1", () =>
  assertSucceeds(
    updateDoc(doc(db(TIERS), "products", "v1"), { viewsCount: 5 }),
  ),
);

await cas("mais pas de 10 d'un coup", () =>
  assertFails(
    updateDoc(doc(db(TIERS), "products", "v1"), { viewsCount: 15 }),
  ),
);

await cas("ni le décrémenter", () =>
  assertFails(
    updateDoc(doc(db(TIERS), "products", "v1"), { viewsCount: 3 }),
  ),
);

await cas("ni en profiter pour changer le prix", () =>
  assertFails(
    updateDoc(doc(db(TIERS), "products", "v1"), { viewsCount: 5, price: 1 }),
  ),
);

await poser("v2");
await cas("première vue sur une annonce sans compteur", () =>
  assertSucceeds(
    updateDoc(doc(db(TIERS), "products", "v2"), { viewsCount: 1 }),
  ),
);

console.log("\nEt le serveur, lui, décide");

await env.withSecurityRulesDisabled(async (c) => {
  await updateDoc(doc(c.firestore(), "products", "p4"), {
    moderationStatus: "approved",
    isListable: true,
  });
});
console.log("   ✓ l'Admin SDK contourne ces règles (c'est par là que passe la modération)");
ok += 1;

await env.cleanup();
console.log(`\n${ok} réussi(s), ${ko} échoué(s)`);
process.exit(ko === 0 ? 0 : 1);
