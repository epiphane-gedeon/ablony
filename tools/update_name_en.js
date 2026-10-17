/**
 * Script de mise à jour des noms en anglais (nameEn) dans Firestore.
 * 
 * Met à jour :
 * 1. Les 8 catégories de niveau 1 (config/categories/items)
 * 2. Les 253 sous-catégories (config/subcategories/items)
 * 
 * Usage :
 *   NODE_PATH=./tools/node_modules node tools/update_name_en.js
 */

const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ── 1. Traductions des catégories racines (8) ──────────────────────────
const CATEGORIES_EN = {
  femme: "Women",
  homme: "Men",
  enfants: "Kids",
  electronique: "Electronics",
  livres: "Books & Media",
  maison: "Home",
  beaute: "Beauty & Personal Care",
  sport_loisirs: "Sports & Leisure"
};

// ── 2. Traductions des sous-catégories (253) ───────────────────────────
const SUBCATEGORIES_EN = {
  // === FEMME ===
  hauts_femme: "Tops",
  chemisier_femme: "Shirt & blouse",
  tshirt_femme: "T-shirt",
  debardeur_femme: "Tank top",
  top_femme: "Top & blouse",
  pull_femme: "Sweater & cardigan",
  sweat_femme: "Sweatshirt & hoodie",

  robes_femme: "Dresses",
  robe_jour_femme: "Day dress",
  robe_soiree_femme: "Evening dress",
  robe_ceremonie_femme: "Ceremonial dress",
  combinaison_femme: "Jumpsuit & playsuit",

  bas_femme: "Bottoms",
  pantalon_femme: "Pants",
  jean_femme: "Jeans",
  jupe_femme: "Skirt",
  short_femme: "Shorts",
  legging_femme: "Leggings",

  vestes_femme: "Jackets & coats",
  veste_femme: "Jacket",
  blazer_femme: "Blazer",
  manteau_femme: "Coat",
  impermeable_femme: "Raincoat",

  traditionnel_femme: "Traditional wear",
  kaba_femme: "Kaba & wrapper set",
  bazin_femme: "Bazin",
  boubou_femme: "Boubou",
  ensemble_wax_femme: "Wax print outfit",
  tissu_pagne_femme: "African print & fabric by the yard",

  chaussures_femme: "Shoes",
  baskets_femme: "Sneakers",
  sandales_femme: "Sandals",
  talons_femme: "Heels",
  ballerines_femme: "Flats & ballerinas",
  mules_femme: "Mules & slides",
  bottes_femme: "Boots",

  sacs_femme: "Bags",
  sac_main_femme: "Handbag",
  sac_dos_femme: "Backpack",
  pochette_femme: "Clutch",
  sac_voyage_femme: "Travel bag",

  accessoires_femme: "Accessories",
  bijoux_femme: "Jewelry",
  montre_femme: "Watch",
  ceinture_femme: "Belt",
  foulard_femme: "Scarf",
  lunettes_femme: "Glasses & sunglasses",
  chapeau_femme: "Hat & beanie",

  lingerie_femme: "Lingerie & sleepwear",
  soutien_femme: "Bra",
  culotte_femme: "Panties",
  pyjama_femme: "Pajamas & nightgown",

  sport_femme: "Sportswear",
  tenue_sport_femme: "Workout outfit",
  basket_sport_femme: "Athletic shoes",

  // === HOMME ===
  hauts_homme: "Tops",
  chemise_homme: "Shirt",
  tshirt_homme: "T-shirt",
  polo_homme: "Polo shirt",
  pull_homme: "Sweater & cardigan",
  sweat_homme: "Sweatshirt & hoodie",

  bas_homme: "Bottoms",
  pantalon_homme: "Pants",
  jean_homme: "Jeans",
  short_homme: "Shorts",
  jogging_homme: "Sweatpants & joggers",

  vestes_homme: "Jackets & coats",
  veste_homme: "Jacket",
  blazer_homme: "Blazer & suit",
  manteau_homme: "Coat",

  traditionnel_homme: "Traditional wear",
  boubou_homme: "Boubou",
  bazin_homme: "Bazin",
  agbada_homme: "Agbada",
  chemise_wax_homme: "Wax print shirt",
  tissu_pagne_homme: "African print & fabric by the yard",

  chaussures_homme: "Shoes",
  baskets_homme: "Sneakers",
  sandales_homme: "Sandals & slides",
  mocassins_homme: "Loafers",
  ville_homme: "Dress shoes",
  bottes_homme: "Boots",

  accessoires_homme: "Accessories",
  montre_homme: "Watch",
  ceinture_homme: "Belt",
  casquette_homme: "Cap & hat",
  lunettes_homme: "Glasses & sunglasses",
  portefeuille_homme: "Wallet",
  sac_homme: "Bag",

  sport_homme: "Sportswear",
  tenue_sport_homme: "Workout outfit",
  maillot_homme: "Soccer jersey",
  basket_sport_homme: "Athletic shoes",

  // === ENFANTS ===
  bebe: "Baby (0-2 years)",
  body_bebe: "Onesie & pajamas",
  ensemble_bebe: "Outfit set",
  manteau_bebe: "Coat & jacket",
  chaussons_bebe: "Booties & slippers",

  fille: "Girls (2-16 years)",
  haut_fille: "Tops",
  robe_fille: "Dresses",
  bas_fille: "Bottoms",
  veste_fille: "Jackets & coats",
  traditionnel_fille: "Traditional outfit",
  chaussures_fille: "Shoes",

  garcon: "Boys (2-16 years)",
  haut_garcon: "Tops",
  bas_garcon: "Bottoms",
  veste_garcon: "Jackets & coats",
  traditionnel_garcon: "Traditional outfit",
  chaussures_garcon: "Shoes",

  ecole: "School",
  uniforme_ecole: "School uniform",
  cartable_ecole: "School bag & backpack",
  fournitures_ecole: "School supplies",

  puericulture: "Baby gear & childcare",
  poussette: "Stroller",
  siege_auto: "Car seat",
  lit_bebe: "Crib & bassinet",
  porte_bebe: "Baby carrier",
  repas_bebe: "Feeding & bottles",
  baignoire_bebe: "Bath & grooming",

  jouets: "Toys & games",
  eveil_jouet: "Early learning toys",
  poupee_jouet: "Dolls & plush toys",
  voiture_jouet: "Toy cars & race tracks",
  societe_jouet: "Board games",
  construction_jouet: "Building sets",
  exterieur_jouet: "Outdoor toys",

  // === ELECTRONIQUE ===
  telephonie: "Phones & tablets",
  smartphone: "Smartphone",
  telephone_simple: "Basic phone",
  tablette: "Tablet",
  accessoire_telephone: "Cases & screen protectors",

  informatique: "Computers",
  ordinateur_portable: "Laptop",
  ordinateur_bureau: "Desktop computer",
  imprimante: "Printer",
  peripherique: "Keyboard, mouse & monitor",
  stockage: "USB flash drives & hard drives",

  audio: "Audio",
  ecouteurs: "Earbuds & earphones",
  casque_audio: "Headphones",
  enceinte: "Speakers",
  radio: "Radio",
  sono: "PA system & microphones",

  image: "TV, photo & video",
  televiseur: "Television",
  decodeur: "TV box & antenna",
  videoprojecteur: "Projector",
  appareil_photo: "Camera",
  camera: "Camcorder & video camera",

  jeux_video: "Video games",
  console: "Console",
  jeu_video: "Game",
  manette: "Controller & accessories",

  energie: "Power & charging",
  chargeur: "Charger & cable",
  batterie_externe: "Power bank",
  panneau_solaire: "Solar panel",
  lampe_solaire: "Solar lamp",
  onduleur: "UPS & voltage stabilizer",
  groupe_electrogene: "Generator",

  // === LIVRES & MEDIAS ===
  livres_scolaires: "School textbooks",
  manuel_scolaire: "School textbook",
  cahier_exercices: "Workbook",
  annales: "Exam prep & past papers",
  dictionnaire: "Dictionary",

  litterature: "Literature & fiction",
  roman: "Novel",
  litterature_africaine: "African literature",
  poesie_theatre: "Poetry & drama",
  essai: "Essay",

  pratique: "Practical & self-help",
  developpement_personnel: "Self-improvement",
  cuisine_livre: "Cookbook",
  sante_livre: "Health & wellness",
  informatique_livre: "Tech & language learning",
  business_livre: "Business & entrepreneurship",

  religion: "Religion & spirituality",
  bible: "Bible & biblical studies",
  coran: "Quran & Islamic books",
  spiritualite: "Spirituality",

  bd_jeunesse: "Comics & YA",
  bd: "Comic book",
  manga: "Manga",
  livre_enfant: "Children's book",

  medias: "Music & movies",
  cd: "CD",
  dvd: "DVD & movies",
  magazine: "Magazines & journals",

  // === MAISON ===
  cuisine: "Kitchen",
  ustensile: "Utensils & tableware",
  marmite: "Pots & pans",
  petit_electromenager: "Small appliances",
  rangement_cuisine: "Kitchen storage",

  electromenager: "Home appliances",
  refrigerateur: "Refrigerator & freezer",
  machine_laver: "Washing machine",
  ventilateur: "Fan & air conditioner",
  fer_repasser: "Iron",
  micro_onde: "Microwave & oven",

  linge_maison: "Home linen & bedding",
  draps: "Bed sheets & blankets",
  serviettes: "Towels",
  rideaux: "Curtains",
  nappe: "Tablecloths",

  decoration: "Home decor",
  tableau: "Paintings & frames",
  luminaire: "Lighting",
  tapis: "Rugs",
  objet_deco: "Decorative objects",
  artisanat: "Local handicrafts",

  meubles: "Furniture",
  canape: "Sofa & armchairs",
  table: "Table & chairs",
  lit: "Bed & mattress",
  armoire: "Wardrobe & storage",
  bureau_meuble: "Desk",

  // === BEAUTE & SOINS ===
  cheveux: "Hair",
  meches: "Hair extensions & weaves",
  perruque: "Wigs",
  soin_cheveux: "Hair care products",
  accessoire_cheveux: "Hair accessories",

  maquillage: "Makeup",
  teint: "Foundation & powder",
  levres: "Lipstick & lip gloss",
  yeux: "Eye makeup & eyebrows",
  ongles: "Nails & nail polish",
  pinceaux: "Brushes & accessories",

  parfums: "Fragrances",
  parfum_femme: "Women's perfume",
  parfum_homme: "Men's cologne",
  encens: "Incense & room sprays",

  soins_corps: "Skin & body care",
  soin_visage: "Face care",
  soin_corps: "Body care",
  savon: "Soaps & scrubs",
  huile: "Natural oils & butters",

  // === SPORT & LOISIRS ===
  equipement_sport: "Sports equipment",
  ballon: "Balls",
  musculation: "Fitness & bodybuilding",
  velo: "Bicycles & scooters",
  raquette: "Rackets",

  plein_air: "Outdoors",
  camping: "Camping",
  peche: "Fishing",
  plage: "Beach & pool",

  instruments: "Musical instruments",
  guitare: "Guitar",
  clavier_musique: "Keyboard & piano",
  percussion: "Djembe & percussion",
  instrument_autre: "Other instruments"
};

async function run() {
  console.log("=== MISE À JOUR DES TRADUCTIONS ANGLAISES (nameEn) DANS FIRESTORE ===\n");

  // 1. Mise à jour des catégories racines
  console.log("▶ Mise à jour des catégories racines...");
  const catBatch = db.batch();
  let catCount = 0;
  for (const [id, nameEn] of Object.entries(CATEGORIES_EN)) {
    const ref = db.collection('config').doc('categories').collection('items').doc(id);
    catBatch.update(ref, { nameEn });
    catCount++;
  }
  await catBatch.commit();
  console.log(`✅ ${catCount} catégories racines mises à jour.\n`);

  // 2. Mise à jour des sous-catégories
  console.log("▶ Mise à jour des sous-catégories...");
  const subEntries = Object.entries(SUBCATEGORIES_EN);
  const CHUNK_SIZE = 400; // Firestore limite les batchs à 500 opérations
  let subCount = 0;

  for (let i = 0; i < subEntries.length; i += CHUNK_SIZE) {
    const chunk = subEntries.slice(i, i + CHUNK_SIZE);
    const subBatch = db.batch();

    for (const [id, nameEn] of chunk) {
      const ref = db.collection('config').doc('subcategories').collection('items').doc(id);
      subBatch.update(ref, { nameEn });
      subCount++;
    }

    await subBatch.commit();
  }

  console.log(`✅ ${subCount} sous-catégories mises à jour dans Firestore.\n`);

  // 3. Vérification de la complétude
  const allSubDocs = await db.collection('config').doc('subcategories').collection('items').get();
  let missing = 0;
  for (const doc of allSubDocs.docs) {
    if (!doc.data().nameEn) {
      console.warn(`⚠️ Sous-catégorie sans nameEn : ${doc.id}`);
      missing++;
    }
  }

  if (missing === 0) {
    console.log("🎉 Parfait ! 100% des sous-catégories ont maintenant leur champ nameEn renseigné dans Firestore.");
  } else {
    console.warn(`Il reste ${missing} sous-catégories sans nameEn.`);
  }

  process.exit(0);
}

run().catch(err => {
  console.error("❌ Erreur :", err);
  process.exit(1);
});
