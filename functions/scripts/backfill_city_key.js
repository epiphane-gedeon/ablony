/**
 * Reprise : renseigne `cityKey` (ville normalisée : minuscule, sans accent) à
 * partir du `city` d'affichage existant, sur tous les comptes. Sert au
 * géo-focus du lancement (comparaison « est-ce Lomé ? ») et évite que les
 * comptes créés avant l'étape ville soient renvoyés la choisir.
 * Idempotent : ne réécrit que si absent ou différent.
 *   node functions/scripts/backfill_city_key.js [--dry-run]
 */
const admin = require("firebase-admin");
const sa = require("../../tools/service-account.json");
admin.initializeApp({credential: admin.credential.cert(sa)});
const db = admin.firestore();
const ESSAI = process.argv.includes("--dry-run");

function normalizeCityKey(input) {
  let s = String(input).trim().toLowerCase();
  const accents = {
    "à": "a", "â": "a", "ä": "a", "á": "a", "ã": "a", "å": "a",
    "ç": "c",
    "é": "e", "è": "e", "ê": "e", "ë": "e",
    "í": "i", "ì": "i", "î": "i", "ï": "i",
    "ñ": "n",
    "ó": "o", "ò": "o", "ô": "o", "ö": "o", "õ": "o",
    "ú": "u", "ù": "u", "û": "u", "ü": "u",
    "ý": "y", "ÿ": "y", "œ": "oe", "æ": "ae",
  };
  s = s.split("").map((ch) => accents[ch] || ch).join("");
  return s.replace(/[^a-z0-9]/g, "");
}

(async () => {
  const snap = await db.collection("users").get();
  const aFaire = [];
  const parCle = {};
  snap.docs.forEach((d) => {
    const u = d.data();
    if (typeof u.city !== "string" || u.city.trim() === "") return;
    const key = normalizeCityKey(u.city);
    if (key === "") return;
    if (u.cityKey !== key) {
      aFaire.push({ref: d.ref, key});
    }
    parCle[key] = (parCle[key] || 0) + 1;
  });
  console.log(`${snap.size} comptes · ${aFaire.length} à renseigner`);
  console.log("Répartition (villes normalisées) :", parCle);
  if (ESSAI) {
    console.log("--dry-run : rien écrit.");
    process.exit(0);
  }
  // Par lots de 400 (limite Firestore : 500 écritures / batch).
  for (let i = 0; i < aFaire.length; i += 400) {
    const lot = aFaire.slice(i, i + 400);
    const batch = db.batch();
    lot.forEach((x) => batch.update(x.ref, {cityKey: x.key}));
    await batch.commit();
    console.log(`  lot ${i / 400 + 1} : ${lot.length} écrits`);
  }
  console.log(`✅ ${aFaire.length} comptes mis à jour.`);
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
