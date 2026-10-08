# Offre Fondateurs — ce qu'on promet, ce que ça coûte, ce qui reste à construire

Référence opérationnelle de la promesse de lancement.
Voir `31-strategie-marketing-lancement.md` pour la campagne qui s'appuie dessus.

---

## 1. La promesse

> **Les 100 premiers inscrits sont Fondateurs à vie.**
>
> · Un **badge Fondateur** sur leur profil, impossible à obtenir ensuite
> · **5 boosts offerts** pour mettre leurs annonces en avant
> · Leur **premier retrait sans frais**

Formulation courte pour les réseaux :

> **Les 100 premiers inscrits deviennent Fondateurs d'Ablony. Badge à vie,
> 5 boosts offerts, premier retrait sans frais. Il reste [X] places.**

---

## 2. Ce que ça coûte réellement

| Élément | Valeur affichée | Coût réel | Pourquoi |
|---|---:|---:|---|
| Badge Fondateur | — | **0 F** | Un champ en base |
| 5 boosts | 2 500 F | **≈ 0 F** | Un boost est un drapeau qui réordonne une liste |
| Premier retrait sans frais | ~500 F | **~250 F** | 2,5 % de coût de sortie chez nyole, sur un retrait moyen de 10 000 F |
| **Par personne** | **~3 000 F** | **~250 F** | |
| **Pour 100 Fondateurs** | **~300 000 F** | **~25 000 F** | |

Le coût maximal n'est atteint que si **les 100 vendent et retirent**. En
pratique il sera plus bas : on ne paie le retrait que pour ceux qui ont
réellement vendu.

### Pourquoi ces trois-là et pas d'autres

Le critère : **coût marginal nul, ou plafonné par compte et déclenché par une
vraie transaction.** Jamais quelque chose qui grandit avec le volume.

Ce qui a été écarté, et pourquoi :

| Écarté | Coût | Problème |
|---|---|---|
| Protection acheteur offerte | **−5 %** par commande | nyole prélève quand même ; perte sèche qui grandit avec le succès |
| Livraison offerte | 1 000–2 000 F / commande | Intégralement à ta charge, au moment où tu livres toi-même |
| Cash de parrainage | variable | Sortie de trésorerie pure, et attire les faux comptes |

---

## 3. État de construction

### ✅ Badge Fondateur — déjà en place

Le déclencheur `onUserCreated` pose `isFounder` d'après `config/badges.foundersOpen`.

Trois propriétés utiles, vérifiées dans le code :

- **Le serveur fait autorité.** Un client modifié ne peut pas s'attribuer le
  badge ; le déclencheur écrase ce que le client a écrit.
- **La fermeture est immédiate**, sur toutes les versions installées, sans
  mise à jour de l'application.
- **Fermer ne retire rien aux Fondateurs existants** : le déclencheur ne
  s'exécute qu'à la *création* du compte. La promesse « à vie » tient.

**État actuel : `foundersOpen: true`, et 31 comptes sur 31 sont Fondateurs.**
La fenêtre est donc déjà ouverte — chaque inscription en cours reçoit le badge.

### ❌ 5 boosts offerts — à construire

`boostCredits` existe sur le compte, mais n'est alimenté que par l'**achat**
d'un lot. Rien ne permet d'en offrir.

Deux façons de faire :
- **Rapide** : un script qui crédite 5 boosts à tous les comptes `isFounder`.
  Suffit si l'offre est fermée à 100.
- **Propre** : créditer les 5 boosts dans `onUserCreated`, en même temps que le
  badge. Les Fondateurs les ont alors dès l'inscription, sans intervention.

### ❌ Premier retrait sans frais — à construire

`withdrawalFee()` applique 5 % à tout le monde, sans exception.

À faire : exempter le premier retrait d'un compte `isFounder`. Le marqueur le
plus simple est un champ `founderWithdrawalUsed` posé au premier retrait — plus
fiable que de compter les retraits passés.

**Attention à l'affichage** : l'écran de retrait annonce les frais *avant*
validation, en les recalculant côté client. Si l'exemption n'existe que côté
serveur, le Fondateur verra « −500 F » puis recevra la somme entière. Bonne
surprise, mais incohérence — et c'est exactement le genre d'écart que l'app
s'efforce d'éviter ailleurs.

---

## 4. Règles d'exploitation

**Fermer à 100.** Une rareté qu'on ne referme jamais n'est pas une rareté.
C'est ce qui donne sa valeur au badge, et ce qui rend le compte à rebours
crédible.

**Le compte à rebours est du contenu.** « Il reste 43 places » se publie chaque
semaine, gratuitement, et crée de l'urgence sans rien promettre de faux.

**Surveiller le compteur :**

```bash
node -e 'const a=require("./functions/node_modules/firebase-admin");
a.initializeApp({credential:a.credential.cert(require("./tools/service-account.json"))});
a.firestore().collection("users").where("isFounder","==",true).count().get()
 .then(s=>{console.log("Fondateurs :",s.data().count,"/100");process.exit(0);});'
```

**Fermer la fenêtre** depuis l'onglet admin (`setFoundersOpen(false)`), ou par
script. L'effet est immédiat.

**Ne jamais rouvrir.** Rouvrir après avoir annoncé la fermeture détruit la
crédibilité de toutes les promesses suivantes — et une place de marché se
construit précisément sur la crédibilité des promesses.

---

## 5. Ce qu'il reste à décider

- **Les 31 comptes déjà Fondateurs** comptent-ils dans les 100 ? Ils ont été
  créés pendant les tests. Soit on les garde (il reste 69 places), soit on
  réinitialise `isFounder` sur les comptes de test avant de lancer.
- **Quand créditer les 5 boosts** : à l'inscription, ou en une fois à la
  fermeture de la fenêtre ?
