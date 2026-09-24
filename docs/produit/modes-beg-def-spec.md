# Modes « beg » et « def » — spécification

> Deux modes de fonctionnement de l'app, commutables **depuis l'admin**.
> `def` = l'app complète actuelle (relais + livraison Ablony partout).
> `beg` = version de lancement (opération manuelle sur Lomé + auto-expédition
> ailleurs). **Le mode n'affecte QUE les fonctionnalités qui diffèrent** ; tout
> le reste (ville, vente, chat, paiement…) est indépendant du mode.
>
> Statut : spec validée avec le fondateur. 4 sous-points « à confirmer » en bas.
> Rien n'est encore codé.

---

## 1. Le drapeau `mode`

- Stocké dans Firestore `config/app` : `{ mode: "beg" | "def" }`.
- **Lu côté client** (UI) **et côté serveur** (validation paiement/livraison) —
  sinon un client bricolé contourne les règles.
- Commutable dans la **partie admin** (nouveau réglage).
- Repli si absent : `def` (comportement actuel).

## 2. Ce qui NE dépend PAS du mode (toujours actif)

- La **question ville** à l'inscription (voir §6).
- Le **processus de vente**, le **chat**, le **paiement/escrow**, les favoris,
  la recherche, etc.
- L'affichage/masquage des **points relais** : déjà piloté par « existe-t-il des
  relais actifs ? », **pas** par le mode. En beg, on n'y touche pas (tout
  désactiver les masque déjà).

## 3. Mode `def` (actuel) — inchangé

Relais + livraison à domicile Ablony ; vendeur dépose en relais ; ramassage
vendeur payant possible ; livraison proposée quelle que soit la ville.

## 4. Mode `beg` — les différences

### 4.1 Options de livraison au checkout (selon la ville)
La livraison **Ablony** n'est proposée que si **acheteur ET vendeur sont à
Lomé**. Sinon elle est masquée.

- **Acheteur & vendeur à Lomé** → l'acheteur choisit :
  - **Livraison Ablony** (domicile ; relais seulement s'il y a des relais actifs)
    → *Ablony collecte chez le vendeur* (voir 4.2).
  - **« Le vendeur m'envoie le colis »** → *auto-expédition* (voir 4.3).
- **Acheteur ou vendeur hors Lomé** → seule l'option **« Le vendeur m'envoie le
  colis »** (auto-expédition). Livraison Ablony masquée.

### 4.2 Chemin « Livraison Ablony » (collecte)
Le vendeur **ne dépose plus en relais**. À la place :
- Il **confirme « colis prêt »** → un **livreur Ablony vient le chercher**, sous
  **4 jours**.
- Message adapté (plus de « dépose en point relais »).
- Nécessite l'**adresse + tél de ramassage du vendeur** (demandés automatiquement
  après la vente / réutilise le formulaire déjà construit).
- Le **ramassage vendeur payant** (feature def) est **masqué** en beg (la
  collecte est déjà le modèle). *(à confirmer #4)*
- Suivi colis : fonctionne (scans agents à la collecte + livraison).

### 4.3 Chemin « auto-expédition » (le vendeur envoie)
- **Aucun contact révélé** : acheteur et vendeur **coordonnent le transport dans
  le chat** (l'acheteur partage lui-même ce qu'il veut : tél, gare…).
- **Frais** : **livraison Ablony = 0** ; l'acheteur paie l'article + les **frais
  de protection** ; le transport se règle **entre eux**. *(à confirmer #2)*
- **Marquer « expédié »** : bouton vendeur **« J'ai expédié le colis »** avec
  **preuve OBLIGATOIRE** (photo du reçu d'envoi) → **modération admin** :
  - En attente de modération → le **compte à rebours (4 j) est en pause**.
    *(à confirmer #3)*
  - **Approuvé** → statut « expédié », compteur arrêté.
  - **Refusé** → **notif au vendeur** + le compte à rebours **reprend là où il
    s'était arrêté** (pas remis à 0).
  - Génère une **file de modération + badge** dans l'admin (comme les autres
    files).
- **Escrow conservé** : à la réception, l'acheteur **confirme** → libération.
  Auto-libération si l'acheteur ne confirme jamais, **J+? après l'expédition
  validée**. *(à confirmer #1)*
- **Suivi masqué** pour l'auto-expédition (pas de scan → frise vide).
- **Preuve en litige** : optionnelle (un litige ne concerne pas que les colis
  expédiés) — distincte de la preuve **obligatoire** du bouton « expédié ».

### 4.4 Délais
- Collecte Ablony : vendeur a **4 jours** pour confirmer « prêt » / être
  disponible, sinon remboursement auto (réutilise la mécanique dépôt existante,
  signal = scan agent à la collecte).
- Auto-expédition : vendeur a **4 jours** pour cliquer « J'ai expédié » (+ preuve
  validée), sinon remboursement auto (signal = bouton + modération).

## 5. Responsabilité / CGU

Si le **paiement se fait en contournant l'app** (cash, virement direct…), la
**responsabilité d'Ablony est écartée** (pas d'escrow, pas de protection). À
inscrire dans les **CGU**. Projet de clause :

> **Article — Paiements hors plateforme.** La protection Ablony (séquestre des
> fonds, remboursement, gestion des litiges) ne s'applique **qu'aux paiements
> effectués via l'application**. Tout paiement convenu ou réalisé en dehors de
> l'application (espèces, virement, mobile money direct, etc.) est aux **risques
> exclusifs des parties** : Ablony n'en a aucune connaissance, n'en assure ni le
> séquestre ni le remboursement, et décline toute responsabilité en cas de
> non-remise, de non-paiement ou de litige lié à un tel paiement.

## 6. Ville à l'inscription (indépendant du mode)

- **Pays → ville** (on garde le pays). Au lancement, le pays est auto = Togo
  (`FeatureFlags.choixPaysActif = false`) → l'utilisateur ne voit **que** la
  ville.
- **Liste contrôlée** de villes par pays (Togo : Lomé, Sokodé, Kara, Kpalimé,
  Atakpamé, Dapaong, Tsévié, Aného…) + « Autre », avec recherche.
- **Stockage** : une **clé normalisée** (`cityKey` : minuscule, sans accent —
  `lome`, `sokode`…) pour comparer, + l'affichage dérivé de la liste (`Lomé`).
- `isProfileComplete` = username + pays + **ville**. Comptes existants sans ville
  → invités à la choisir une fois (les anciens clients installés ne vérifient pas
  la ville → rien ne casse).
- Nouvelle page **`/auth/city`** après le pays.

## 7. Chat — carrés d'info interlocuteur

Ajouter la **ville** à côté du **pays** dans les petits encarts d'info du chat
(l'acheteur voit où il achète, le vendeur où il vend).

## 8. Sous-décisions — tranchées

1. **Délai d'auto-libération** en auto-expédition (acheteur ne confirme jamais) :
   **J+7 après l'expédition validée**. ✅
2. **Frais** sur « le vendeur m'envoie » : **protection acheteur conservée,
   livraison = 0** (transport entre eux). ✅
3. **Compte à rebours en pause** pendant la modération de la preuve, reprise
   seulement en cas de refus. ✅
4. **Ramassage vendeur payant masqué en mode beg** (collecte gratuite = modèle
   par défaut). ✅

## 9. Ordre de construction proposé

1. Champ `cityKey` + page `/auth/city` + `isProfileComplete` (indépendant, utile
   tout de suite).
2. Drapeau `mode` (config/app) + réglage admin + lecture client/serveur.
3. Checkout mode beg : gating livraison par ville + option « le vendeur m'envoie ».
4. Chemin collecte (confirmer « prêt » → livreur vient) + wording.
5. Chemin auto-expédition : bouton « J'ai expédié » + preuve + **modération admin
   (file + badge)** + pause/reprise du compteur + escrow/auto-libération.
6. Masquages beg (suivi en auto-expédition, ramassage payant) + ville dans le chat.
7. Clause CGU.
