# Corrections — les défauts à reprendre

*Distinct des fonctionnalités manquantes : ici, du code qui existe et se
comporte mal.*

Classement par ce qu'il en coûte de ne rien faire.

---

## C1 — La recherche télécharge tout le catalogue {#c1}

**Gravité : bloquante depuis la cible de 2 500 comptes**

`product_repository_impl.dart:278` charge toutes les annonces disponibles puis
filtre en mémoire. Aucune limite, aucun index.

À la cible annoncée — 2 500 comptes, soit environ 6 000 annonces disponibles —
le quota gratuit est épuisé après **huit recherches par jour**, et la facture
atteint 270 à 470 $ par mois. L'écran, lui, gèle plusieurs secondes à chaque
requête.

Traité en détail dans [18-recherche.md](18-recherche.md).

---

## C2 — ablony.net est suspendu, et les CGU n'existent pas {#c2}

**Gravité : bloquante pour la publication**

Les trois URL légales renvoient `cgi-sys/suspendedpage.cgi`. Et
`app_urls.dart` pointe vers `cgu.html`, qui n'a jamais existé dans
`ablony_landing`.

L'application fait accepter des conditions générales illisibles, et les
magasins refusent une politique de confidentialité inaccessible.

*La suspension est un abonnement non renouvelé, et sera réglée avant le
lancement.* Reste le vrai manque : **les CGU n'ont jamais été écrites**, et
c'est une journée de rédaction, pas de code.

Traité dans [16-pages-legales.md](16-pages-legales.md).

---

## C3 — Vingt et une entrées d'interface ne font rien {#c3}

**Gravité : moyenne · effet immédiat sur la confiance**

Treize au profil, huit aux réglages. Traité dans
[13-entrees-mortes.md](13-entrees-mortes.md).

Dont deux cas particuliers qui sont des **motifs de refus** :

- **Aucun écran de suppression de compte.** La Cloud Function `deleteAccount`
  existe et n'est appelée de nulle part. Apple l'exige pour toute application
  permettant de créer un compte (règle 5.1.1 v).
- **Aucun moyen de bloquer un membre.** Exigé pour toute application à contenu
  produit par les utilisateurs (règle 1.2). Traité dans
  [12-blocage-membre.md](12-blocage-membre.md).

---

## C4 — reCAPTCHA n'a jamais été branché {#c4}

**Gravité : moyenne**

`lib/features/auth/presentation/pages/captcha_page.dart` porte un `TODO`. La
fonction `verifyRecaptcha` existe dans `functions/index.js` et **personne ne
l'appelle**.

Conséquence : l'inscription est ouverte à la création automatisée de comptes.
Sur une application qui distribue un porte-monnaie, c'est une invitation — et
à 2 500 comptes attendus, vous ne saurez pas distinguer la croissance du
bruit.

**Deux options, à trancher :**

1. **Brancher reCAPTCHA** sur l'inscription et la connexion. Une journée, et
   la fonction serveur est déjà écrite.
2. **Activer Firebase App Check** à la place. Plus simple, plus adapté au
   mobile, couvre tous les appels et pas seulement l'inscription. Une demi-
   journée. Le projet le référence déjà dans ses dépendances.

Je recommande la seconde. Et dans les deux cas, retirer `captcha_page.dart` si
elle n'est pas utilisée — un écran mort de plus.

---

## C5 — Trois booléens là où il faut un état {#c5}

**Gravité : faible aujourd'hui, élevée à la migration**

L'application représente l'état d'une annonce par `isSold`, `isReserved`,
`isHidden`. Trois booléens permettent huit combinaisons, dont plusieurs n'ont
aucun sens : vendu *et* réservé, masqué *et* vendu. Rien n'empêche de les
écrire.

Et surtout, ils ne savent pas exprimer « retiré par la modération », ni
« archivé ».

Le backend autonome utilise un champ `status` unique à cinq valeurs, avec une
contrainte de base qui interdit tout le reste. Le modèle retenu pour Firebase
s'en rapproche — ce qui rendra la migration future presque gratuite sur ce
point.

**Cette correction est entrée au périmètre.** Elle en était sortie le
15 septembre, jugée trop coûteuse pour ce qu'elle apportait à l'utilisateur.
Trois décisions prises depuis l'y ont ramenée : la modération veut un champ
d'état, l'archivage un autre, et la suspension une condition supplémentaire
sur toutes les listes.

Trois passages sur les mêmes quatre index composites, contre un seul si l'on
pose le bon modèle tout de suite. Le surcoût réel est d'environ une journée,
et toutes les requêtes de liste passent de trois égalités à une.

Voir [19-modele-annonce.md](19-modele-annonce.md).

---

## C6 — Le projet n'a aucun test {#c6}

**Gravité : élevée, pour une application qui déplace de l'argent**

Pas de dossier `test/`. Ni test unitaire, ni test de widget, ni test
d'intégration. `CLAUDE.md` le dit explicitement.

**Ne pas y remédier en 30 jours** — écrire une base de tests sur un code
existant prend plus de temps que le calendrier n'en offre.

**Ce qu'il faut à la place :** un cahier de recette manuelle sur les parcours
d'argent, exécuté sur un vrai téléphone avec de vrais paiements de petit
montant. Les jours 18 à 20 du [calendrier](02-perimetre-mvp.md#le-calendrier-proposé)
y sont consacrés, et ne sont pas négociables.

Les parcours à éprouver, dans cet ordre :

1. Inscription → publication d'une annonce → achat par un second compte
2. Le vendeur dépose, un agent scanne les quatre étapes
3. L'acheteur confirme → le vendeur voit son solde augmenter
4. Le vendeur demande un retrait → l'administration verse → le solde baisse
5. Un achat, un litige ouvert par l'acheteur, un remboursement → l'argent revient
6. Un compte avec du solde ne peut pas être supprimé
7. Deux comptes se bloquent mutuellement

Après le lancement, écrire les tests en commençant par ces sept parcours.

---

## C7 — Six photos, quand la photo est la description {#c7}

**Gravité : faible**

`image_picker_grid.dart:25` plafonne à six, et `firestore.rules:372` l'impose.
Vinted en accepte vingt, plus une vidéo.

Sur un marché de seconde main, la photo *est* la description : l'état réel,
les défauts, l'étiquette de taille, la doublure. Six suffisent pour un
t-shirt, pas pour un sac où l'on cherche les coutures.

**Hors périmètre des 30 jours** — le coût n'est pas dans le curseur mais dans
le stockage, la bande passante et le temps d'envoi sur une connexion mobile.
À traiter avec une compression plus agressive, après le lancement.

---

## C8 — Le fil d'accueil est le même pour tout le monde {#c8}

**Gravité : faible au lancement**

`paginatedProductsProvider` sert les annonces les plus récentes, sans tenir
compte de ce que la personne regarde, met en favori ou suit.

Sans personnalisation, le fil se dégrade à mesure que le catalogue grossit :
au début tout est nouveau, ensuite tout est mélangé.

**Hors périmètre.** Le premier pas utile, après le lancement, est modeste :
remonter les annonces des vendeurs suivis et des catégories consultées. Pas
un moteur de recommandation.
