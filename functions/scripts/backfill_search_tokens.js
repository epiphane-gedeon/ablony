/**
 * Reprise : calcule `searchTokens` sur toutes les annonces existantes.
 *
 * À lancer **avant** de publier la version de l'application qui interroge
 * `searchTokens` — sinon la recherche ne trouve plus rien, et l'on attend
 * l'examen du magasin pour corriger.
 *
 * Idempotent : les annonces déjà pourvues sont sautées, sauf avec --force.
 *
 *   node functions/scripts/backfill_search_tokens.js [--dry-run] [--force]
 */

const admin = require("firebase-admin");
const serviceAccount = require("../../tools/service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

const ESSAI = process.argv.includes("--dry-run");
const FORCE = process.argv.includes("--force");
const LOT = 300;
const MAX_TOKENS = 120;

/**
 * Attributs qui ne méritent pas d'être cherchés en texte.
 *
 * L'état de l'article est un **filtre** de l'écran de recherche, pas un
 * terme : l'indexer remplissait chaque annonce de « neuf », « avec »,
 * « etiquette », « etat » — des mots si courants qu'une requête les
 * contenant ramènerait la moitié du catalogue.
 */
const ATTRIBUTS_NON_INDEXES = new Set(["condition"]);

const cache = new Map();

/**
 * Les ligatures que la normalisation Unicode ne décompose pas.
 *
 * NFD sépare une lettre de son accent, mais ne sait rien de « œ » ni de
 * « ß » : sans cette table, « Cœur » s'indexe « ur » et « Straße » « stra ».
 * Elle doit rester identique à `_sansAccent` côté Flutter
 * (product_repository_impl.dart) et à la copie du script de reprise.
 */
const LIGATURES = {"œ": "oe", "æ": "ae", "ß": "ss", "ø": "o", "đ": "d"};

/**
 * Mots trop courants pour discriminer quoi que ce soit.
 *
 * `array-contains-any` remonte les annonces portant **au moins un** des mots :
 * une requête contenant « avec » ramènerait la moitié du catalogue, et les
 * vingt résultats de la page seraient pris au hasard parmi eux.
 */
const MOTS_VIDES = new Set([
  "le", "la", "les", "un", "une", "des", "du", "de", "et", "ou",
  "pour", "sans", "avec", "dans", "sur", "par", "aux", "au", "en",
  "ce", "cet", "cette", "mon", "ma", "mes", "son", "sa", "ses",
]);

/**
 * Découpe un texte en mots-clés normalisés.
 *
 * Deux formes par mot, et la seconde compte : « H&M » découpé donne « h » et
 * « m », écartés pour leur longueur — la marque devenait introuvable. La
 * forme compacte, « hm », la rattrape, comme « t-shirt » → « tshirt ».
 *
 * @param {string} texte Le texte à découper.
 * @return {string[]} Les mots retenus, sans doublon.
 */
function tokeniser(texte) {
  let brut = String(texte || "").toLowerCase();
  for (const [de, vers] of Object.entries(LIGATURES)) {
    brut = brut.split(de).join(vers);
  }
  brut = brut.normalize("NFD").replace(/[̀-ͯ]/g, "");

  const sortie = new Set();
  for (const mot of brut.split(/\s+/)) {
    for (const part of mot.split(/[^a-z0-9]+/)) {
      if (part.length >= 2 && !MOTS_VIDES.has(part)) sortie.add(part);
    }
    const compact = mot.replace(/[^a-z0-9]+/g, "");
    if (compact.length >= 2 && !MOTS_VIDES.has(compact)) sortie.add(compact);
  }
  return [...sortie];
}

/**
 * Étend des mots avec leurs préfixes (recherche à la frappe : « rob » →
 * « robe »). Mots entiers d'abord, préfixes ensuite. Doit rester identique à
 * `avecPrefixes` dans functions/index.js.
 */
function avecPrefixes(mots) {
  const sortie = new Set(mots);
  for (const mot of mots) {
    const max = Math.min(mot.length, 10);
    for (let i = 2; i < max; i++) sortie.add(mot.slice(0, i));
  }
  return [...sortie];
}

/**
 * Charge une collection de configuration en mémoire, une fois.
 *
 * Trois lectures au total plutôt qu'une par annonce : sur six mille
 * annonces, la différence est l'essentiel du coût du script.
 *
 * @param {string} racine `categories`, `subcategories` ou `attributes`.
 * @return {Promise<Map<string, Object>>} Les documents, par identifiant.
 */
async function charger(racine) {
  if (cache.has(racine)) return cache.get(racine);
  const snap = await db.collection("config").doc(racine)
      .collection("items").get();
  const m = new Map(snap.docs.map((d) => [d.id, d.data()]));
  cache.set(racine, m);
  console.log(`  ${racine} : ${m.size} entrée(s)`);
  return m;
}

/**
 * Parcourt la collection et écrit les mots-clés.
 *
 * @return {Promise<void>}
 */
async function reprendre() {
  const categories = await charger("categories");
  const sousCategories = await charger("subcategories");
  const attributs = await charger("attributes");

  let dernier = null;
  let vues = 0;
  let ecrites = 0;
  let sansToken = 0;

  for (;;) {
    let q = db.collection("products").orderBy("__name__").limit(LOT);
    if (dernier) q = q.startAfter(dernier);
    const page = await q.get();
    if (page.empty) break;

    const lot = db.batch();
    let n = 0;

    for (const doc of page.docs) {
      vues += 1;
      const d = doc.data();
      if (!FORCE && Array.isArray(d.searchTokens)) continue;

      const morceaux = [d.title || ""];
      for (const [id, valeur] of Object.entries(d.attributes || {})) {
        if (ATTRIBUTS_NON_INDEXES.has(id)) continue;
        // Les valeurs sont des indices dans la liste de l'attribut :
        // indexer la valeur brute produirait le mot-clé « 3 ».
        if (typeof valeur === "number") {
          const def = attributs.get(id);
          morceaux.push((def?.values || [])[valeur] || "");
        } else if (valeur) {
          morceaux.push(String(valeur));
        }
      }
      morceaux.push(categories.get(d.categoryId)?.name || "");
      morceaux.push(sousCategories.get(d.subcategoryId)?.name || "");

      const mots = [...new Set(tokeniser(morceaux.join(" ")))];
      const tokens = avecPrefixes(mots).slice(0, MAX_TOKENS);

      // Une annonce sans aucun mot-clé serait introuvable : à signaler.
      if (tokens.length === 0) {
        sansToken += 1;
        console.warn(`  ! ${doc.id} : aucun mot-clé — titre « ${d.title} »`);
      }

      // En essai, montrer les premiers résultats : un compte ne dit pas si
      // les indices d'attributs ont bien été résolus en libellés. Des
      // mots-clés comme « 3 » ou « 7 » signaleraient que non.
      if (ESSAI && n < 6) {
        console.log(`    « ${d.title} »\n      → [${tokens.join(", ")}]`);
      }

      n += 1;
      if (!ESSAI) lot.update(doc.ref, {searchTokens: tokens});
    }

    if (n > 0 && !ESSAI) await lot.commit();
    ecrites += n;
    dernier = page.docs[page.docs.length - 1];
    console.log(`  ${vues} vues, ${ecrites} reprises`);
    if (page.size < LOT) break;
  }

  console.log(`\n${ESSAI ? "[essai] " : ""}${vues} annonce(s) parcourue(s), ` +
    `${ecrites} reprise(s)`);
  if (sansToken > 0) {
    console.log(`${sansToken} annonce(s) sans aucun mot-clé — introuvables.`);
  }
}

reprendre()
    .then(() => process.exit(0))
    .catch((e) => {
      console.error(e);
      process.exit(1);
    });
