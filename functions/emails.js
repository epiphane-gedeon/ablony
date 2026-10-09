/**
 * Envoi d'e-mails transactionnels.
 *
 * **Transactionnels, et rien d'autre.** Un litige, un message de l'équipe :
 * des cas où de l'argent est en jeu et où la notification push peut être
 * désactivée, ratée, ou arriver sur un téléphone éteint. L'e-mail est le seul
 * canal qui attend.
 *
 * Ce qui n'a rien à faire ici : les ventes, les messages entre membres, les
 * favoris, les abonnements. Le risque n'est pas d'agacer — c'est que les
 * destinataires signalent les e-mails comme indésirables, et qu'alors les
 * avis **importants** cessent d'arriver. On préserve le canal en ne s'en
 * servant que quand il le faut.
 *
 * Ces envois ne dépendent pas de `marketingEmailsEnabled` : un consentement
 * publicitaire ne conditionne pas un avis transactionnel.
 */

const nodemailer = require("nodemailer");

const SMTP = {
  host: process.env.SMTP_HOST || "",
  port: Number(process.env.SMTP_PORT || 587),
  user: process.env.SMTP_USER || "",
  pass: process.env.SMTP_PASS || "",
  from: process.env.SMTP_FROM || process.env.SMTP_USER || "",
};

let _transport = null;

/** Le transporteur SMTP, créé une seule fois par instance. */
function transport() {
  if (!_transport) {
    _transport = nodemailer.createTransport({
      host: SMTP.host,
      port: SMTP.port,
      // 465 est implicitement chiffré ; 587 passe par STARTTLS.
      secure: SMTP.port === 465,
      auth: {user: SMTP.user, pass: SMTP.pass},
    });
  }
  return _transport;
}

/** Échappe le texte inséré dans le HTML d'un e-mail. */
function esc(s) {
  return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
}

const BLEU = "#2385AE";
const APP_URL = (process.env.APP_PUBLIC_URL || "https://ablony-a5db9.web.app")
    .replace(/\/+$/, "");

/**
 * Le gabarit commun : en-tête, contenu, pied.
 *
 * Styles en ligne et tableaux : les clients de messagerie ignorent une bonne
 * part du CSS moderne, et Gmail retire les feuilles de style. Be Vietnam Pro
 * est chargée depuis Google Fonts avec un repli système, comme sur le site.
 *
 * @param {Object} p Paramètres du gabarit.
 * @return {string} Le HTML complet du message.
 */
function gabarit({titre, intro, bloc, bouton, lien, pied}) {
  return `<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;600;700&display=swap" rel="stylesheet">
<style>@import url('https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;600;700&display=swap');</style>
</head>
<body style="margin:0;padding:0;background:#f4f6f8;font-family:'Be Vietnam Pro',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f8;padding:28px 12px;">
<tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#ffffff;border-radius:14px;overflow:hidden;box-shadow:0 2px 10px rgba(0,0,0,.06);">

<tr><td style="background:${BLEU};padding:20px 28px;">
<!-- Le logo est blanc sur fond transparent : il n'est lisible que sur ce
     bandeau bleu. L'attribut alt reprend le nom en blanc, pour les clients
     qui bloquent les images par défaut — Outlook le fait encore. -->
<img src="${APP_URL}/assets/assets/images/logo.png" alt="Ablony" width="132"
     style="display:block;border:0;width:132px;height:auto;font-family:'Be Vietnam Pro',sans-serif;color:#ffffff;font-size:20px;font-weight:700;">
</td></tr>

<tr><td style="padding:28px;">
<h1 style="margin:0 0 14px;font-family:'Be Vietnam Pro',sans-serif;font-size:19px;font-weight:700;color:#111;">${esc(titre)}</h1>
<p style="margin:0 0 18px;font-family:'Be Vietnam Pro',sans-serif;font-size:15px;line-height:1.6;color:#444;">${intro}</p>
${bloc || ""}
${bouton ? `<table role="presentation" cellpadding="0" cellspacing="0" style="margin:22px 0 6px;"><tr>
<td style="background:${BLEU};border-radius:10px;">
<a href="${esc(lien)}" style="display:inline-block;padding:13px 26px;font-family:'Be Vietnam Pro',sans-serif;font-size:15px;font-weight:600;color:#ffffff;text-decoration:none;">${esc(bouton)}</a>
</td></tr></table>` : ""}
</td></tr>

<tr><td style="padding:18px 28px 26px;border-top:1px solid #eceff1;">
<p style="margin:0;font-family:'Be Vietnam Pro',sans-serif;font-size:12px;line-height:1.6;color:#8a9199;">${pied || "Vous recevez cet e-mail parce qu'il concerne une transaction sur votre compte Ablony."}</p>
</td></tr>

</table></td></tr></table></body></html>`;
}

/**
 * Envoie un e-mail. Ne lève jamais : un échec d'envoi ne doit pas faire
 * échouer l'action en cours — un litige doit pouvoir s'ouvrir même si le
 * serveur de messagerie est tombé.
 *
 * @param {Object} p Destinataire, objet, HTML et texte brut.
 * @return {Promise<boolean>} Vrai si l'e-mail est parti.
 */
async function envoyer({to, sujet, html, texte}) {
  if (!SMTP.host || !SMTP.user || !to) {
    console.warn("E-mail non envoyé : SMTP non configuré ou destinataire absent");
    return false;
  }
  try {
    await transport().sendMail({
      from: `"Ablony" <${SMTP.from}>`,
      to,
      subject: sujet,
      html,
      text: texte,
    });
    return true;
  } catch (e) {
    console.error(`E-mail « ${sujet} » non envoyé à ${to} :`, e.message);
    return false;
  }
}

/**
 * Litige ouvert : prévenir l'autre partie.
 *
 * **Le contenu de la plainte n'est volontairement pas repris.** Un e-mail se
 * lit par-dessus l'épaule, se transfère et se cite de travers ; recopier une
 * accusation envenime une situation déjà tendue, et expose si elle s'avère
 * infondée. On annonce le fait, on renvoie à l'application.
 *
 * @param {Object} p Destinataire et contexte du litige.
 * @return {Promise<boolean>} Vrai si l'e-mail est parti.
 */
async function emailLitigeOuvert({to, prenom, article}) {
  const titre = "Un litige a été ouvert sur une de vos transactions";
  const intro =
    `Bonjour${prenom ? " " + esc(prenom) : ""},<br><br>` +
    `Un litige vient d'être ouvert concernant <strong>${esc(article || "une commande")}</strong>. ` +
    `Les fonds restent bloqués par Ablony le temps que la situation soit examinée : ` +
    `ni vous ni l'autre partie ne perdez quoi que ce soit pour l'instant.`;
  const bloc =
    `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f7f9fa;border-left:3px solid ${BLEU};border-radius:6px;margin:4px 0 2px;">
<tr><td style="padding:14px 16px;">
<p style="margin:0;font-family:'Be Vietnam Pro',sans-serif;font-size:14px;line-height:1.6;color:#444;">
<strong>Ce qu'il faut faire :</strong> ouvrez Ablony pour consulter le motif et répondre.
Plus votre réponse arrive tôt, plus le dossier se règle vite.</p>
</td></tr></table>`;
  return envoyer({
    to,
    sujet: "Ablony — un litige a été ouvert sur votre transaction",
    html: gabarit({
      titre, intro, bloc,
      bouton: "Voir le litige", lien: `${APP_URL}/home`,
      pied: "Vous recevez cet e-mail parce qu'un litige concerne une de vos " +
        "transactions. Il ne s'agit pas d'un message publicitaire.",
    }),
    texte:
      `Un litige a été ouvert concernant ${article || "une commande"}. ` +
      `Les fonds restent bloqués par Ablony le temps de l'examen. ` +
      `Ouvrez l'application pour consulter le motif et répondre : ${APP_URL}`,
  });
}

/**
 * Message de l'équipe : reprendre le texte dans l'e-mail.
 *
 * Ici, contrairement au litige, le message **est** adressé au destinataire :
 * le lire sans ouvrir l'application lui fait gagner du temps, et augmente les
 * chances qu'il réponde.
 *
 * @param {Object} p Destinataire et message.
 * @return {Promise<boolean>} Vrai si l'e-mail est parti.
 */
async function emailMessageEquipe({to, prenom, message}) {
  const titre = "L'équipe Ablony vous a écrit";
  const intro =
    `Bonjour${prenom ? " " + esc(prenom) : ""},<br><br>` +
    `L'équipe Ablony vous a envoyé un message dans l'application :`;
  const bloc =
    `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f7f9fa;border-left:3px solid ${BLEU};border-radius:6px;margin:4px 0 2px;">
<tr><td style="padding:16px;">
<p style="margin:0;font-family:'Be Vietnam Pro',sans-serif;font-size:15px;line-height:1.65;color:#222;white-space:pre-wrap;">${esc(message)}</p>
</td></tr></table>`;
  return envoyer({
    to,
    sujet: "Ablony — message de l'équipe",
    html: gabarit({
      titre, intro, bloc,
      bouton: "Répondre dans l'application", lien: `${APP_URL}/home`,
      pied: "Répondez depuis l'application pour que l'équipe reçoive votre " +
        "réponse : les réponses à cet e-mail ne sont pas lues automatiquement.",
    }),
    texte:
      `L'équipe Ablony vous a écrit :\n\n${message}\n\n` +
      `Répondez depuis l'application : ${APP_URL}`,
  });
}

/**
 * Mot de passe oublié.
 *
 * Le lien est engendré par le SDK admin puis envoyé par nous, plutôt que de
 * laisser Firebase expédier son propre message : c'est le seul moyen d'avoir
 * notre gabarit et notre adresse. Un e-mail de réinitialisation venant d'un
 * domaine inconnu ressemble à une tentative d'hameçonnage — or c'est
 * précisément le moment où l'on demande à quelqu'un de cliquer.
 *
 * Le délai d'expiration est rappelé : sans lui, un lien ouvert le lendemain
 * donne une erreur que l'on prend pour une panne.
 *
 * @param {Object} p Destinataire, nom et lien de réinitialisation.
 * @return {Promise<boolean>} Vrai si l'e-mail est parti.
 */
async function emailMotDePasseOublie({to, prenom, lien}) {
  const titre = "Réinitialisation de votre mot de passe";
  const intro =
    `Bonjour${prenom ? " " + esc(prenom) : ""},<br><br>` +
    `Vous avez demandé à réinitialiser le mot de passe de votre compte Ablony. ` +
    `Le lien ci-dessous est valable <strong>une heure</strong>.`;
  const bloc =
    `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f7f9fa;border-left:3px solid ${BLEU};border-radius:6px;margin:4px 0 2px;">
<tr><td style="padding:14px 16px;">
<p style="margin:0;font-family:'Be Vietnam Pro',sans-serif;font-size:14px;line-height:1.6;color:#444;">
<strong>Vous n'êtes pas à l'origine de cette demande ?</strong> Ignorez cet e-mail :
votre mot de passe reste inchangé tant que le lien n'est pas utilisé.</p>
</td></tr></table>`;
  return envoyer({
    to,
    sujet: "Ablony — réinitialisation de votre mot de passe",
    html: gabarit({
      titre, intro, bloc,
      bouton: "Choisir un nouveau mot de passe", lien,
      pied: "Ce lien expire dans une heure et ne peut servir qu'une fois. " +
        "Si le bouton ne fonctionne pas, copiez cette adresse dans votre " +
        "navigateur :<br><span style=\"word-break:break-all;color:#8a9199;\">" +
        esc(lien) + "</span>",
    }),
    texte:
      `Vous avez demandé à réinitialiser votre mot de passe Ablony.\n\n` +
      `Ouvrez ce lien (valable une heure) :\n${lien}\n\n` +
      `Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail : ` +
      `votre mot de passe reste inchangé.`,
  });
}

module.exports = {
  envoyer, emailLitigeOuvert, emailMessageEquipe, emailMotDePasseOublie,
};
