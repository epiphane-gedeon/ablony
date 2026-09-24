# Stratégie de livraison au lancement — notes de décision

> Réflexion sur : comment assurer les livraisons au démarrage sans réseau de
> points relais ni prestataire, et sans casser la confiance ni se piéger sur les
> prix. À relire pour trancher. Rien n'est encore codé.

---

## 1. Le problème

- Ouvrir des points relais coûte cher / prend du temps.
- Pas encore de prestataire fiable identifié (cf. `livraison-transporteurs-lome.md`).
- On ne peut pas livrer dans une ville où on n'opère pas physiquement.

## 2. Le modèle de démarrage retenu (idée fondateur, validée)

**Porte-à-porte opéré par Ablony (toi) :** tu ramasses le colis chez le vendeur,
tu le livres chez l'acheteur. **L'acheteur paie** les frais de livraison.
C'est le « do things that don't scale » classique : à la main, sur **une ville**,
pour valider la demande avant d'industrialiser.

### L'app est déjà à ~90 % prête
- **0 point relais actif → l'option relais disparaît**, il ne reste que la
  livraison à domicile (auto-sélection relais déjà codée).
- En domicile, **l'acheteur paie déjà** au checkout et **donne adresse + tél**.
- **Suivi colis + scans agents + confirmation réception + libération des fonds**
  fonctionnent déjà.

### Le seul vrai changement : côté vendeur
Aujourd'hui on dit au vendeur « dépose en point relais ». En direct, **c'est toi
qui viens** → il faut :
1. Lui dire « un agent Ablony vient récupérer chez toi — reste joignable ».
2. **Capturer son adresse + tél de ramassage** (réutilise le formulaire déjà
   construit, mais **gratuit et automatique** cette fois). → **Décision prise :
   demande automatique après la vente.**

### Implémentation proposée (non codée)
Un **drapeau admin** `mode_livraison = "direct" | "relais"`.
- En `direct` : écran vendeur « on vient chercher » + capture auto adresse/tél ;
  l'étiquette/code reste (pour ton suivi) mais le texte « dépose en relais »
  change.
- Bascule en `relais` le jour où tu as un réseau — le domicile **reste**.
- On peut même **démarrer sans code** (0 relais = domicile only, coordination
  ramassage à la main), puis activer le mode direct proprement.

---

## 3. Prix : éviter le « retour en arrière »

Inquiétude : plus tard, ajouter les relais + monter les prix domicile = perçu
comme une régression.

**Deux règles qui suppriment le problème :**
1. **Ne pas lancer le domicile à prix cassé.** Price-le à son **vrai coût** dès
   le jour 1. Ainsi, quand les relais arrivent **moins chers**, tu n'augmentes
   rien : le relais est une **remise**, pas une hausse.
2. **Ne jamais retirer le porte-à-porte.** Quand les relais arrivent, le domicile
   **reste** comme option confort/premium. Tu **ajoutes** une option économique,
   tu n'enlèves rien. (L'app gère déjà les deux côte à côte.)

L'écart de prix est **réel** (venir chez toi coûte plus que consolider en relais)
→ affiché honnêtement, il paraît juste. Adoucir avec un **avantage Fondateur**
(quelques livraisons offertes aux premiers).

---

## 4. Le ramassage vendeur payant (cohérence avec le modèle relais)

Dans le modèle relais, le vendeur peut **payer** pour qu'on vienne chercher au
lieu de déposer. Comment l'introduire sans que ça semble « c'était gratuit
avant » ?

**Principe stable : celui qui bénéficie du confort paie le confort.**
- **Lancement** (0 relais) : le ramassage est le **seul chemin** → son coût est
  dans les **frais acheteur**. Le vendeur ne paie rien car il n'a pas le choix.
- **Relais** : le vendeur a une **option gratuite** (déposer au relais) → s'il
  préfère qu'on vienne, c'est **son** confort → **il** paie. (Déjà encodé ainsi
  dans le code : frais acheteur d'un côté, ramassage vendeur payant de l'autre.)

**À faire, pas plus tard mais ensemble :** introduire l'enlèvement payant **en
même temps que les relais**, comme un menu clair côté vendeur (« Dépose au relais
(gratuit) / On vient chercher (X FCFA) »). Et au lancement, présenter l'enlèvement
comme une **opération de lancement** (temporaire), pas un « avantage gratuit ».

---

## 5. Villes où tu n'opères pas → décision : Voie A (géo-focus)

Là où tu ne livres pas, tu ne peux pas **garantir la remise** (le scan agent qui
protège les deux parties disparaît). Deux voies :

- **Voie A — Se concentrer sur Lomé** *(retenue)*. Seule Lomé transacte au
  départ ; ailleurs « bientôt dans ta ville ». On grandit **ville par ville**.
  Protection complète, pas de fuite (personne ne paie hors app). Marché initial
  plus petit — prix normal d'un lancement.
- **Voie B — Remise en main propre optionnelle**. Étend la portée sans opérer
  partout, mais **protection plus faible** (pas de scan agent) et **risque de
  paiement cash hors app**. Revient sur la décision « plus de main-propre » (qui
  n'était valable que tant qu'on livrait tout). → **Reporté**, éventuellement
  plus tard et clairement étiqueté.

---

## 6. Conséquence Voie A : demander la VILLE à l'onboarding

Pour restreindre à Lomé (et dire « bientôt » ailleurs), il faut connaître la
ville de chaque compte.

### État actuel
- Le champ **`city` existe déjà** sur le compte (`user.city`, optionnel), **mais
  n'est pas demandé** à l'inscription.
- Flux onboarding : `username → captcha → (pays) → home`. « Profil complet » =
  username + pays.
- **`FeatureFlags.choixPaysActif = false`** → au lancement, pays **auto = Togo**
  et la page pays est **sautée**.

### Approche retenue : **pays → ville** (garder le pays)
« Ville à la place du pays » = non (on perd le pays : Togo/Bénin, devise, filtrage
par pays). On **ajoute la ville après le pays**. Comme le pays est auto-sauté au
lancement, **l'utilisateur ne verra en pratique que la question ville** — sans
perdre le pays en base. À l'ouverture Bénin, on rallume le drapeau : pays **puis**
ville, sans refonte.

### Ville = liste déroulante (pas champ libre)
Valeur **contrôlée** (pour le géo-filtrage et des données propres). Liste des
villes principales par pays (Togo : Lomé, Sokodé, Kara, Kpalimé, Atakpamé,
Dapaong, Tsévié, Aného…) + « Autre », avec recherche. Extensible depuis l'admin
plus tard.

### Ce que ça touche
- Nouvelle page **`/auth/city`** (style page pays), après le pays.
- `isProfileComplete` = username + pays + **ville** → comptes existants sans ville
  invités à la choisir une fois (backfill ; les **anciens clients installés ne
  vérifient pas la ville → rien ne casse**).
- Complétion de l'inscription après la ville.

### ⚠️ Périmètre
Cette étape **collecte** seulement la ville. **Bloquer les achats hors zone
couverte (Lomé)** est une **2ᵉ brique** (petite) — sans elle, on demande la ville
mais tout le monde peut acheter partout.

---

## 7. Décisions à trancher plus tard

- [ ] **Quand** construire le « mode direct » (drapeau admin + écran vendeur) :
      maintenant, ou démarrer à la main d'abord (0 relais + coordination manuelle) ?
- [ ] **Ville** : liste curée Togo + « Autre » (recommandé) vs champ libre ?
- [ ] **Étape ville seule**, ou **ville + blocage des achats hors Lomé** dans la
      foulée ?
- [ ] **Prix domicile de lancement** : le fixer à son vrai coût (pour ne jamais
      avoir à l'augmenter). Combien ?
- [ ] Avantage **Fondateur** sur la livraison (quelques courses offertes) ? oui/non.
- [ ] Confirmer le principe « le confort se paie par celui qui en profite » comme
      règle communiquée publiquement.
