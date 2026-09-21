# Après le lancement

*Ce qui a été écarté des 30 jours, et dans quel ordre le reprendre.*

L'ordre ci-dessous n'est pas celui de la ressemblance avec Vinted. Il suit une
règle simple : **ce qui vous coûte de l'argent d'abord, ce qui fait revenir
les gens ensuite, le confort en dernier.**

---

## 1. Les lots — *6 à 8 jours · à faire en premier*

**Pourquoi c'est le plus rentable.** Chez Vinted, le lot économise quelques
euros de port à l'acheteur. Chez vous, la livraison est un coût que **vous**
portez : 1 000 à 1 500 FCFA par colis, payés à des livreurs que vous employez.
Deux articles du même vendeur vers le même acheteur dans deux colis séparés,
c'est votre marge qui sort deux fois.

Ce n'est donc pas une fonctionnalité de confort. C'est une économie
d'exploitation qui se chiffre dès la première semaine.

**Le principe.** L'acheteur ajoute plusieurs articles d'un même vendeur à un
panier, paye une fois, et reçoit **un colis**. Le vendeur emballe une fois,
imprime une étiquette, dépose une fois.

**Ce que ça touche.** Beaucoup, et c'est pourquoi ce n'est pas dans les 30
jours :

- un panier par vendeur (nouvelle collection `carts`) ;
- `initiatePayment` qui accepte plusieurs articles ;
- l'index d'unicité « un article ne se vend qu'une fois » à revoir — il porte
  aujourd'hui sur une transaction par article ;
- un colis qui référence plusieurs articles ;
- un remboursement qui peut être partiel — **c'est le point difficile** : que
  se passe-t-il si un seul des trois articles pose problème ?

**Trancher avant de commencer :** un litige sur un article d'un lot
rembourse-t-il l'article ou le lot entier ? Je recommande l'article seul, avec
les frais de livraison au prorata — mais c'est une décision produit, pas
technique.

**La remise sur lot** (l'entrée morte du profil) vient avec, et ne coûte
presque rien une fois le panier en place : un pourcentage sur le profil
vendeur, appliqué à partir de deux articles.

---

## 2. Recherches sauvegardées — *3 à 4 jours*

**Pourquoi c'est le meilleur outil de rétention.** Sur une place de marché de
seconde main, personne ne trouve ce qu'il cherche du premier coup : le stock
est unique et change tous les jours. La recherche sauvegardée transforme « je
n'ai rien trouvé » en « je serai prévenu ».

C'est le mécanisme qui fait revenir chez Vinted, et il ne coûte qu'une requête
stockée plus une comparaison à chaque publication.

**Le principe.** Depuis les résultats de recherche, un bouton « Créer une
alerte ». La requête est stockée (mots-clés, catégorie, taille, prix
maximum). À chaque annonce publiée, un déclencheur compare et notifie.

**Dépend de** [18-recherche.md](18-recherche.md) : sans `searchTokens`, il n'y
a rien à comparer.

**Le piège à éviter.** Ne pas notifier pour chaque annonce. Quinze
notifications dans la soirée font désinstaller l'application. Grouper : un
message par alerte et par jour, « 7 nouveautés pour *robe wax* ». Vinted
utilise d'ailleurs une pastille silencieuse plutôt qu'une notification — c'est
un choix défendable, et moins risqué.

---

## 3. Avis réciproques — *2 jours*

Aujourd'hui l'acheteur note le vendeur. L'inverse n'existe pas.

**Pourquoi ça compte chez vous.** Un vendeur qui prépare un colis, l'emballe
et se déplace au point relais pour un acheteur qui ne confirme jamais n'a
aucun moyen de le signaler. Et comme **rien n'expire automatiquement sur
Firebase**, ces ventes-là restent bloquées jusqu'à votre intervention.

Une note d'acheteur rend ce comportement visible, et c'est moins coûteux que
de traiter les dossiers un par un.

**Le principe.** Après le dénouement d'une vente, chacun note l'autre. Les
deux notes ne sont visibles qu'une fois les deux données — ou après un délai —
pour éviter les représailles.

---

## 4. Offre privée aux intéressés — *2 jours*

Le vendeur voit qui a mis son article en favori sans l'acheter, et peut
envoyer un prix réduit valable 24 heures.

**Pourquoi c'est efficace.** Ces gens ont déjà montré leur intérêt ; il ne
manque qu'un déclic. C'est de la vente sans acquisition — les acheteurs sont
déjà là.

**Suppose** un nombre de favoris suffisant pour que ça vaille la peine. Sans
volume, un vendeur avec deux favoris n'en tirera rien.

---

## 5. Mode vacances — *1 jour*

Un interrupteur qui masque toutes ses annonces et suspend son obligation de
dépôt.

**Le vrai bénéfice n'est pas pour le vendeur, il est pour vous.** Un vendeur
absent dont les annonces restent en ligne génère des ventes qu'il ne déposera
pas — donc des remboursements, des acheteurs déçus et du travail
d'administration. Le mode vacances évite tout cela pour une journée de travail.

À reprendre l'entrée morte du profil (ligne 166).

---

## 6. Vingt photos et une vidéo — *2 jours*

Voir [C7](03-corrections.md#c7). Le coût n'est pas dans le curseur mais dans
le stockage, la bande passante et le temps d'envoi sur une connexion mobile
ouest-africaine. À traiter **avec** une compression plus agressive, pas avant.

---

## 7. Parrainage — *3 jours*

Un code par membre, une récompense au premier achat du filleul.

**Volontairement en dernier.** C'est un outil de croissance, et il ne se règle
bien qu'une fois qu'on sait ce que vaut un utilisateur. Le lancer trop tôt,
c'est distribuer de l'argent sans savoir contre quoi.

---

## 8. Le fil d'accueil personnalisé — *4 jours*

Voir [C8](03-corrections.md#c8). Premier pas modeste : remonter les annonces
des vendeurs suivis et des catégories consultées. Pas un moteur de
recommandation — une pondération.

---

## Ce qui reste hors périmètre, durablement

| Quoi | Pourquoi |
|---|---|
| **Comptes professionnels** | Suppose une réglementation, une facturation et une TVA que vous n'avez pas à traiter. |
| **Mise en avant de la boutique entière** | Utile à partir de vingt annonces actives par vendeur. |
| **Suivre une marque** | La marque est un attribut de catégorie, pas une entité. En faire une entité est un chantier de données pour un gain faible. |
| **Dons à une association** | Dépend de partenariats inexistants. |
| **Multi-devise** | Le XOF couvre le Togo et le Bénin — c'est l'avantage de votre périmètre, pas une limite. |

---

## Et le raccordement au backend autonome

Ce n'est pas une fonctionnalité, c'est un chantier — et il conditionne
plusieurs points ci-dessus.

Le backend autonome (`/ablony_back`) est complet : sept services, 634 tests,
la logistique, les litiges, les remboursements, les horloges qui font expirer
et libérer **automatiquement** — ce que Firebase ne fait pas.

Ce qu'il apporte concrètement et qui manque aujourd'hui :

- **les deux horloges** : un colis jamais déposé rembourse tout seul, une
  remise constatée libère les fonds au bout de trois jours. Sur Firebase, rien
  n'expire : chaque dossier attend votre geste ;
- une vraie recherche plein texte, insensible aux accents, indexée en base ;
- le champ `status` unique, qui règle [C5](03-corrections.md#c5) ;
- la modération, les litiges et les retraits déjà écrits et testés.

**Quand.** Après les lots, avant les recherches sauvegardées — celles-ci
s'appuient sur une recherche correcte, et le nouveau backend en offre une
meilleure que ce que Firestore permettra jamais.

**Combien.** Le raccordement seul — client HTTP, JWT avec renouvellement,
chaque appel Firestore remplacé — est de l'ordre de trois semaines. À
planifier comme un projet, pas comme une tâche.
