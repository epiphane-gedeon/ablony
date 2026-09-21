/**
 * Les rôles d'administration.
 *
 * `role` est écrit côté serveur uniquement : les règles Firestore le gèlent
 * sur toute écriture client, précisément pour qu'un membre ne se promeuve
 * pas lui-même. Ce script est donc le chemin prévu pour l'attribuer.
 *
 *   node functions/scripts/roles.js                          liste
 *   node functions/scripts/roles.js --grant <email> <role>   attribue
 *   node functions/scripts/roles.js --revoke <email>         retire
 *
 * <role> vaut `moderator` ou `admin`.
 */

const admin = require("firebase-admin");
const serviceAccount = require("../../tools/service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

const ROLES = ["moderator", "admin"];

async function lister() {
  const snap = await db.collection("users")
    .where("role", "in", ROLES).get();

  if (snap.empty) {
    console.log("Aucun compte ne porte de rôle d'administration.");
    console.log("Personne ne peut donc ouvrir la console.");
    return;
  }

  console.log(`${snap.size} compte(s) avec un rôle d'administration :\n`);
  for (const d of snap.docs) {
    const u = d.data();
    let mail = u.email || "";
    if (!mail) {
      try {
        mail = (await admin.auth().getUser(d.id)).email || "(sans e-mail)";
      } catch {
        mail = "(compte d'authentification absent)";
      }
    }
    console.log(`  ${u.role.padEnd(9)} ${mail}`);
    console.log(`  ${" ".repeat(9)} uid ${d.id} · statut ${u.accountStatus || "active"}`);
  }
}

async function trouver(email) {
  const rec = await admin.auth().getUserByEmail(email);
  const ref = db.collection("users").doc(rec.uid);
  const doc = await ref.get();
  if (!doc.exists) {
    // Sans fiche `users/`, la console ne saurait pas lire le rôle et la
    // session serait rejetée sans expliquer pourquoi.
    throw new Error(
      `Le compte existe mais n'a pas de fiche users/${rec.uid}. ` +
      "Connectez-vous une fois à l'application mobile pour la créer.");
  }
  return { rec, ref, doc };
}

async function attribuer(email, role) {
  if (!ROLES.includes(role)) {
    throw new Error(`Rôle inconnu : ${role}. Attendu : ${ROLES.join(" ou ")}.`);
  }
  const { rec, ref, doc } = await trouver(email);
  const avant = doc.data().role || "(aucun)";
  await ref.update({
    role,
    roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`${email} : ${avant} → ${role}`);
  console.log(`uid ${rec.uid}`);
  console.log("\nLa console relit le rôle en base à chaque appel : c'est actif");
  console.log("immédiatement, sans attendre l'expiration du jeton.");
}

async function retirer(email) {
  const { rec, ref, doc } = await trouver(email);
  const avant = doc.data().role || "(aucun)";
  await ref.update({
    role: "member",
    roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`${email} : ${avant} → member`);
  console.log(`uid ${rec.uid}`);
  console.log("\nL'accès cesse au prochain appel, sans délai.");
}

(async () => {
  const args = process.argv.slice(2);
  const i = args.indexOf("--grant");
  const j = args.indexOf("--revoke");
  try {
    if (i !== -1) await attribuer(args[i + 1], args[i + 2]);
    else if (j !== -1) await retirer(args[j + 1]);
    else await lister();
    process.exit(0);
  } catch (e) {
    console.error(`\nÉchec : ${e.message}`);
    process.exit(1);
  }
})();
