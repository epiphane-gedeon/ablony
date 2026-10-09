#!/usr/bin/env node
/**
 * Importe la liste d'attente dans `founderInvites`.
 *
 *   node functions/scripts/import_founder_invites.js docs/ablony_waitlist.csv
 *   node functions/scripts/import_founder_invites.js --etat
 *
 * Les invitations de la liste d'attente sont **hors quota** : elles sont
 * honorées même si les 100 places sont prises. C'est la contrepartie d'une
 * promesse faite avant l'ouverture — leur opposer un quota décidé après coup
 * serait leur reprocher d'être arrivés tôt.
 *
 * L'e-mail sert de clé, normalisé (minuscules, espaces retirés). Quelqu'un qui
 * s'inscrit ensuite via Google avec une **autre** adresse ne sera pas reconnu :
 * c'est irréductible, d'où l'ajout manuel possible depuis l'admin.
 */

const fs = require("fs");
const path = require("path");
const admin = require(path.join(__dirname, "..", "node_modules", "firebase-admin"));

admin.initializeApp({
  credential: admin.credential.cert(
      require(path.join(__dirname, "..", "..", "tools", "service-account.json")),
  ),
});
const db = admin.firestore();

/** Normalise une adresse pour en faire une clé stable. */
function cle(email) {
  return String(email || "")
      .replace(/^﻿/, "")   // BOM des exports tableur
      .trim()
      .toLowerCase();
}

async function etat() {
  const snap = await db.collection("founderInvites").get();
  const parSource = {};
  let reclamees = 0;
  snap.forEach((d) => {
    const x = d.data();
    parSource[x.source || "?"] = (parSource[x.source || "?"] || 0) + 1;
    if (x.claimedBy) reclamees++;
  });
  const cpt = await db.doc("config/badges").get();
  console.log("founderInvites :", snap.size, "invitations");
  for (const [s, n] of Object.entries(parSource)) console.log("   ", s, ":", n);
  console.log("   dont réclamées :", reclamees);
  console.log("\nQuota (hors liste d'attente) :",
      (cpt.data() || {}).founderQuotaUsed || 0, "/ 100");
}

(async () => {
  const arg = process.argv[2];

  if (!arg || arg === "--etat") {
    await etat();
    process.exit(0);
  }

  const chemin = path.resolve(arg);
  const lignes = fs.readFileSync(chemin, "utf8").split(/\r?\n/).filter(Boolean);
  // La première ligne est l'en-tête de l'export.
  const emails = [...new Set(
      lignes.slice(1).map((l) => cle(l.split(",")[0])).filter((e) => e.includes("@")),
  )];

  console.log(`${emails.length} adresses uniques lues dans ${path.basename(chemin)}`);

  let ajoutees = 0;
  let deja = 0;
  const lot = db.batch();
  for (const email of emails) {
    const ref = db.collection("founderInvites").doc(email);
    const snap = await ref.get();
    if (snap.exists) {
      deja++;
      continue;
    }
    lot.set(ref, {
      email,
      source: "waitlist",
      // Hors quota : honorée quoi qu'il arrive.
      horsQuota: true,
      claimedBy: null,
      claimedAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    ajoutees++;
  }
  if (ajoutees) await lot.commit();

  console.log(`  ajoutées : ${ajoutees} | déjà présentes : ${deja}`);
  console.log();
  await etat();
  process.exit(0);
})().catch((e) => {
  console.error("Échec :", e.message);
  process.exit(1);
});
