# 25 — Intégration du paiement nyole

## Objectif

Remplacer **candidat** à GeniusPay : un deuxième fournisseur de paiement
(Mobile Money + carte) branché à côté de l'existant, testable en bac à sable,
et dont le retrait — s'il ne convient pas — ne coûte qu'un flag, pas une
chirurgie.

GeniusPay reste en place et fonctionnel jusqu'à ce que nyole soit validé en
conditions réelles. Rien n'est supprimé avant ça.

## Contrainte actée (voir discussion précédente)

nyole, comme GeniusPay, ne propose **pas** de charge 100 % API (saisie du
numéro + OTP depuis notre propre UI). Le paiement réel se fait sur une page
hébergée (`checkout_url` / `url` de la session) ouverte en WebView — exactement
le modèle déjà en place avec GeniusPay. Ce n'est donc pas une régression, et
ça veut dire que **le changement est presque entièrement serveur** : la
WebView cliente (`payment_web_view_page.dart`) n'a pas à changer.

## Ce qui existe déjà et qu'on réutilise tel quel

L'architecture actuelle sépare déjà « fournisseur de paiement » de
« finalisation métier » — c'est ce qui rend ce remplacement possible sans
tout réécrire :

- `transactions/{reference}` (Firestore) : un document par tentative de
  paiement, statut `pending` → `completed`, créé par `initiatePayment`.
- `finalizePurchase` / `finalizeBoost` / `finalizeBoostPack` / `finalizePickup`
  / `finalizeRecharge` : la logique métier (débit wallet, crédit
  `pendingAmount` vendeur, produit marqué vendu…) ne connaît **pas**
  GeniusPay — elle reçoit juste des montants et des ids. **Ces fonctions ne
  changent pas.**
- Le contrat client est minimal et déjà agnostique du fournisseur :
  - `initiatePayment` renvoie `{reference, status, paymentUrl}`.
  - `confirmPayment` renvoie `{status: "completed"}`.
  - La WebView détecte succès/échec par sous-chaîne dans l'URL
    (`success`/`completed`/`callback` vs `cancel`/`failed`/`error`),
    pas par un domaine particulier — donc tant que les `success_url`/
    `cancel_url` qu'on passe à nyole contiennent ces mots, **zéro ligne
    Flutter à toucher**.
- `passerellePour(moyen)` (`functions/index.js:47`) : GeniusPay lui-même route
  déjà vers plusieurs sous-passerelles selon le moyen de paiement. Le réflexe
  « choisir la bonne route selon le contexte » existe déjà côté code — nyole a
  l'équivalent (`POST /v1/route`), pas besoin de le réinventer, juste de voir
  si on en a besoin ou si on laisse nyole router seul.

## Principe directeur : réversibilité

Un flag serveur choisit le fournisseur actif, sur le modèle déjà en place pour
`config/app.mode` (beg/def) :

```
config/app : { paymentProvider: "geniuspay" | "nyole" }
```

- Code GeniusPay **intact**, jamais supprimé à ce stade.
- Code nyole ajouté **à côté**, dans les mêmes fonctions (`initiatePayment`,
  `confirmPayment`, + un nouveau `nyoleWebhook` séparé de `geniusPayWebhook`).
- Revenir en arrière = remettre le flag à `"geniuspay"` et redéployer les
  functions (pas de rollback de code nécessaire si les deux chemins
  coexistent).
- Chaque étape ci-dessous = un commit distinct, testable isolément.

## Étapes

### 1. Clés et configuration (commit : config seule, rien d'exécutable)
- Ajouter dans `functions/.env` (gitignored) : `NYOLE_SECRET_KEY`,
  `NYOLE_PUBLIC_KEY` (clés `af_test_...` d'abord, jamais `af_live_...` avant
  la validation finale).
- `NYOLE_CONFIG` dans `index.js`, même forme que `GENIUSPAY_CONFIG` : base
  URL (`https://app.nyole.com/api`), clés, et un `MODE_BAC_A_SABLE_NYOLE`
  déduit du préfixe de clé (`af_test_`), même logique que l'existant.
- Ajouter `paymentProvider` à la lecture de `config/app` (déjà lue par
  `appModeServeur()` pour beg/def — un champ de plus sur le même document).

### 2. Client HTTP nyole côté serveur (commit : fonctions utilitaires, non branchées)
- `creerSessionNyole({amount, currency, customer, description, successUrl,
  cancelUrl, metadata})` → `POST /v1/checkout/sessions`, avec
  `Idempotency-Key` = la référence de transaction qu'on génère nous-mêmes
  (évite les doublons sur un retry réseau).
- `statutSessionNyole(sessionId)` → `GET /v1/checkout/sessions/{id}/status`.
- Pas encore appelées par `initiatePayment`/`confirmPayment` à ce stade —
  juste écrites et testables isolément (script ou emulator) contre les clés
  test.

### 3. Brancher `initiatePayment` derrière le flag (commit)
- Si `paymentProvider === "nyole"` et moyen ≠ wallet pur : appeler
  `creerSessionNyole` au lieu du bloc GeniusPay actuel (`index.js:1808-1857`).
- `success_url`/`cancel_url` : construire des URLs **à nous** (pas besoin de
  copier le couple `geniuspaywebhook.../success|cancel` de GeniusPay) qui
  contiennent les mots-clés attendus par la WebView — par exemple une page
  statique minimale sur le hosting, ou réutiliser le même schéma que
  GeniusPay pour rester cohérent.
- Stocker la transaction avec le même schéma (`reference`, `status: pending`,
  mais `nyoleSessionId` au lieu de `geniusPayId`) — `finalize*` n'a pas besoin
  de savoir d'où vient `reference`.
- Renvoyer `{reference, status, paymentUrl}` — **même forme**, donc le client
  ne voit aucune différence.

### 4. Brancher `confirmPayment` derrière le flag (commit)
- Si la transaction a été initiée côté nyole (détecté via la présence de
  `nyoleSessionId` sur le document, pas besoin de relire le flag — la
  transaction porte sa propre origine), appeler `statutSessionNyole` au lieu
  du `GET .../payments/{reference}` GeniusPay.
- Mapper les statuts nyole (`pending`/`success`/`failed`/`cancelled`/
  `refunded`) vers la même logique de décision déjà en place
  (`completed`/`success`/`successful` → on finalise).
- Appeler les **mêmes** `finalize*` — aucun changement là.

### 5. Webhook nyole (commit séparé, nouvelle fonction)
- Nouvelle fonction `nyoleWebhook`, distincte de `geniusPayWebhook` (pas de
  mélange des deux schémas de signature).
- Vérification HMAC-SHA256 selon la doc : `X-Afriflow-Timestamp` +
  `X-Afriflow-Signature` (format `t=<ts>,v1=<hex>`), comparaison à temps
  constant (`crypto.timingSafeEqual`), rejet si l'écart dépasse 5 minutes.
  **Attention au nom des headers** (`X-Afriflow-*`, pas `X-Nyole-*` — vérifié
  dans la doc, incohérence de marque connue côté nyole).
- Traiter l'événement `payment.completed` → même chemin que
  `confirmPayment` (idempotent : `finalize*` vérifie déjà le statut
  `completed` avant d'agir).
- Gérer aussi `payment.failed`/`payment.cancelled` pour marquer la
  transaction en échec plutôt que de la laisser `pending` indéfiniment.

### 6. Tests en bac à sable (pas de commit de code — validation)
- `af_test_...` uniquement. Scénarios à vérifier un par un :
  - Paiement simulé réussi (`POST /checkout/sandbox`, `issue: "succes"`) →
    webhook reçu → `finalizePurchase` appelée une seule fois.
  - Paiement simulé échoué (`issue: "echec"`) → transaction marquée en échec,
    pas de crédit vendeur.
  - Double livraison du webhook (nyole annonce des retentatives) →
    idempotence confirmée (pas de double crédit).
  - `confirmPayment` appelé **avant** le webhook (retour WebView plus rapide
    que le serveur-à-serveur) → pas de conflit, les deux chemins convergent
    vers le même `finalize*` protégé par la vérification `status===
    "completed"`.
  - Annulation client (bouton retour / croix sur la page nyole) → `cancel_url`
    bien détectée par la WebView existante.
- Vérifier le rendu de la page de paiement nyole sur Android **et** iOS, avec
  autant d'opérateurs togolais/béninois que possible (T-Money, Flooz, MTN
  MoMo, Moov) — la doc ne garantit rien sur l'UX par opérateur, à constater en
  vrai.

### 7. Bascule prudente
- Flag `paymentProvider` à `"nyole"` d'abord en interne (compte de test réel,
  petit montant) avant tout utilisateur.
- Si ça tient : ouverture progressive si le flag le permet (sinon tout-ou-
  rien assumé, avec rollback instantané prêt).
- GeniusPay gardé en veille (code + clés) un moment raisonnable après la
  bascule, avant d'envisager sa suppression dans un commit séparé et
  explicitement demandé.

## Rollback

À tout moment : `paymentProvider` → `"geniuspay"`, redeploy functions. Aucune
transaction en cours n'est perdue — `transactions/{reference}` porte son
propre fournisseur (`nyoleSessionId` vs `geniusPayId`), donc les paiements
nyole déjà initiés continuent d'être confirmables même après que le flag soit
revenu à GeniusPay pour les *nouveaux* paiements.

## Risques / inconnues à vérifier empiriquement (pas dans la doc nyole)

- Fiabilité et délai réel du webhook depuis le Togo/Bénin (latence réseau,
  taux de perte).
- Couverture opérateur réelle par pays (la doc liste les devises/pays
  supportés, pas une garantie d'UX par opérateur).
- Comportement de la page hébergée nyole dans une WebView Flutter (vs un
  vrai navigateur) — pas testé par la doc, à vérifier nous-mêmes avant la
  bascule.
- Taux de commission réel nyole vs le routage actuel GeniusPay
  (`paiementpro` 100 F + 11 % mobile money, `paystack` 100 F + 6 % carte) — à
  comparer avant de décider si nyole est *économiquement* intéressant, pas
  seulement techniquement viable.

## Hors scope (volontairement pas fait dans cette passe)

- `/v1/route` (routage multi-passerelle nyole) — nyole route déjà seul par
  défaut ; à envisager seulement si un besoin de contrôle fin apparaît.
- `/v1/payment-links` (liens de paiement nyole) — utile pour le sans-code,
  pas pour le flux d'achat intégré à l'app.
- Suppression du code GeniusPay — décision distincte, après validation.
