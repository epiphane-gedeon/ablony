# 20 — Avertissements, suspensions, bannissement

**Lot 1 · 2 jours**

---

## Le principe

Une échelle à trois barreaux, et **deux degrés de gravité** pour qu'un vendeur
maladroit ne soit pas traité comme un fraudeur.

```
  correction demandée   →   l'annonce est masquée, rien d'autre
         manquement     →   avertissement
      2 avertissements  →   suspension de 10 jours
        3 suspensions   →   bannissement
```

## Les deux degrés

**Correction demandée.** Photo floue, mauvaise catégorie, description vide,
prix manifestement erroné. L'annonce passe en `rejected`, le vendeur est
prévenu **avec le motif** — et il peut republier corrigé. **Aucun
avertissement.** C'est de la qualité de catalogue, pas une faute.

**Manquement.** Contrefaçon, produit interdit, contenu inapproprié, tentative
de fraude, vente hors de la plateforme. L'annonce passe en `rejected` et un
avertissement est inscrit.

Le modérateur choisit le degré au moment de rejeter. C'est un bouton, pas une
zone de texte : quatre motifs de correction, cinq de manquement. Un motif
libre ferait diverger trois modérateurs en une semaine.

## L'échelle

| Barreau | Déclencheur | Effet |
|---|---|---|
| Avertissement | 1 manquement | Notification avec le motif. Aucune restriction. |
| Suspension | 2 avertissements | 10 jours. Voir ci-dessous. |
| Bannissement | 3 suspensions | Définitif. Le compte reste, il ne sert plus. |

*Vous aviez proposé 3 avertissements et 3 suspensions, soit neuf annonces
problématiques avant de perdre le compte. Avec deux degrés, les manquements
comptent seuls — d'où deux avertissements au lieu de trois. Un vendeur de
contrefaçons est arrêté au deuxième article, un vendeur aux photos floues
n'est jamais sanctionné.*

## Ce que la suspension bloque, et ce qu'elle laisse

| Bloqué | Laissé |
|---|---|
| Publier une annonce | **Retirer son argent** |
| Ses annonces disparaissent des listes | Les ventes **déjà en cours** suivent leur cours |
| Modifier une annonce | **La messagerie** |
| | Acheter |

Deux choix méritent d'être dits à voix haute.

**Le retrait reste ouvert.** Retenir l'argent de quelqu'un qu'on sanctionne,
c'est une amende — et vous n'avez pas le pouvoir d'en infliger. L'argent lui
appartient.

**La messagerie reste ouverte.** Un acheteur dont la vente est en cours doit
pouvoir joindre son vendeur pour coordonner le dépôt. La couper casserait
précisément les ventes qu'on cherche à préserver.

## Le bannissement

Le compte passe en `banned`. Il **n'est pas supprimé** : supprimer, c'est
permettre une réinscription le lendemain avec une autre adresse, et perdre
toute trace de ce qui s'est passé.

Un compte banni ne peut ni se connecter, ni publier, ni acheter. Son adresse
et son numéro restent pris.

**Deux garde-fous avant de bannir**, et ils sont impératifs :

- **Solde nul.** Bannir quelqu'un qui détient 40 000 FCFA, c'est se les
  approprier. Si le solde est positif, le bannissement attend le retrait — et
  le retrait reste ouvert, précisément pour cela.
- **Aucune vente en cours.** Un acheteur a payé et attend son article.

Si l'un des deux n'est pas satisfait, l'interface le dit au modérateur et
propose une **suspension prolongée** à la place. Le bannissement redevient
possible une fois la situation dénouée.

---

## Fichier par fichier

### Données — Firestore

```
warnings/{id} = {
  userId, productId, reason, severity: "violation",
  moderatorId, note, createdAt
}

suspensions/{id} = {
  userId, reason, startedAt, endsAt,
  moderatorId, liftedAt?, liftedBy?, createdAt
}
```

Sur l'utilisateur :

```
users/{uid}.accountStatus   = "active" | "suspended" | "banned"
users/{uid}.suspendedUntil  = timestamp | null
users/{uid}.warningCount    = int    ← compteur entretenu, pour ne pas compter à chaque lecture
users/{uid}.suspensionCount = int
```

Les compteurs sont dérivés des collections. Ils existent parce qu'ils sont lus
à chaque décision de modération et à chaque publication d'annonce — compter
les documents à chaque fois coûterait plus que les maintenir. Même
justification que `isListable` : un seul écrivain, beaucoup de lectures.

### Règles — `firestore.rules`

```
function compteActif() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid))
           .data.get('accountStatus', 'active') == 'active';
}
```

À poser sur la **création** d'annonce et sur sa mise à jour par le vendeur.
Pas sur la messagerie, pas sur le porte-monnaie, pas sur les achats.

```
match /warnings/{id} {
  allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
  allow write: if false;
}
match /suspensions/{id} {
  allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
  allow write: if false;
}
```

Une personne sanctionnée doit pouvoir lire sa sanction et son motif. C'est la
moindre des choses, et cela évite un message au support.

### Serveur — `functions/index.js`

**`rejectProduct`** *(appelée par l'administration — voir [17](17-moderation.md))*

```
Entrée  : { productId, severity: "correction"|"violation", reason, note }
Vérifie : role in ["moderator","admin"]
Fait    : products/{id}.moderationStatus = "rejected", rejectedAt, rejectedBy
          recalcule isListable
          si severity == "violation" :
              warnings/{id} créé
              users.warningCount += 1
              si warningCount >= 2 → applique une suspension, remet le compteur à 0
Notifie : le vendeur, avec le motif — et la conséquence s'il y en a une
```

**`applySuspension(uid, reason, moderatorId)`** — interne.

```
users.accountStatus = "suspended"
users.suspendedUntil = maintenant + 10 jours
users.suspensionCount += 1
suspensions/{id} créé
recomputeListableForSeller(uid)      ← ses annonces sortent des listes
si suspensionCount >= 3 → tente le bannissement
```

**`banUser`** — administration seulement, pas les modérateurs.

```
Vérifie : role == "admin"
          · solde disponible == 0 ET solde en attente == 0
          · aucune vente en cours
Si l'un manque → refus explicite, avec le motif, et suspension prolongée proposée
Sinon : users.accountStatus = "banned", bannedAt, bannedBy, reason
        recomputeListableForSeller(uid)
        révocation des sessions
```

Le bannissement est réservé à l'administration. Un modérateur avertit et
suspend ; couper définitivement un accès est d'un autre ordre.

**La levée de suspension** est une tâche planifiée — voir
[21-taches-planifiees.md](21-taches-planifiees.md).

### Application — à modifier

| Fichier | Modification |
|---|---|
| `lib/features/auth/domain/entities/user.dart` | `accountStatus`, `suspendedUntil`, `warningCount`, `suspensionCount`. |
| `lib/features/auth/data/models/user_model.dart` | Lecture seule — **ne jamais** écrire ces champs depuis le client. |
| `lib/features/sell/presentation/widgets/sell_bottom_sheet.dart` | Si le compte est suspendu : un bandeau qui dit pourquoi et jusqu'à quand, à la place du formulaire. Pas une erreur au moment d'envoyer. |
| `lib/features/profile/presentation/pages/profile_page.dart` | Un bandeau en haut si suspendu : le motif, la date de fin, un lien vers ses avertissements. |
| *(à créer)* `lib/features/moderation/presentation/pages/my_warnings_page.dart` | Ses avertissements et suspensions, avec les motifs. Consultable, pas contestable — la contestation passe par le support. |

### Traductions

```
accountSuspendedTitle      Votre compte est suspendu
accountSuspendedUntil      Jusqu'au {date}
accountSuspendedWhat       Vous ne pouvez plus mettre d'articles en vente. Vous pouvez toujours acheter, discuter et retirer votre argent.
accountBanned              Votre compte a été fermé.
warningReceived            Avertissement : {reason}
warningsTitle              Mes avertissements
warningsEmpty              Aucun avertissement. Tout va bien.
productRejectedCorrection  Votre annonce « {title} » a été retirée : {reason}. Vous pouvez la republier corrigée.
productRejectedViolation   Votre annonce « {title} » a été retirée : {reason}. Un avertissement a été inscrit.
```

Le libellé de la suspension dit **ce qui reste possible**, pas seulement ce
qui est bloqué. Quelqu'un qui croit avoir perdu son argent écrit au support
dans l'heure.

---

## Critères d'acceptation

- [ ] Un rejet « correction » n'inscrit aucun avertissement.
- [ ] Un rejet « manquement » en inscrit un, avec le motif visible par le vendeur.
- [ ] Deux manquements déclenchent une suspension de 10 jours et remettent le compteur à zéro.
- [ ] Un vendeur suspendu ne peut pas publier — **vérifié par les règles**, en écrivant directement dans Firestore.
- [ ] Ses annonces disparaissent des listes ; ses ventes en cours continuent.
- [ ] Il peut toujours écrire, acheter et **demander un retrait**.
- [ ] Trois suspensions déclenchent le bannissement.
- [ ] Le bannissement est **refusé** si le solde n'est pas nul ou si une vente est en cours, avec un message qui dit lequel.
- [ ] Un compte banni ne peut plus se connecter, et ses sessions sont révoquées.
- [ ] Un modérateur ne peut pas bannir ; un administrateur oui.
- [ ] Le vendeur peut lire ses avertissements et ses suspensions.

## Le point à surveiller

L'échelle est automatique : deux manquements suspendent sans qu'un humain
revalide. C'est voulu — c'est ce qui la rend prévisible et défendable.

Mais cela veut dire qu'**un modérateur qui se trompe de degré suspend quelqu'un
à tort**. D'où la trace obligatoire : qui a rejeté, avec quel degré, quel
motif. Sans elle, vous ne pourrez ni corriger l'erreur, ni repérer le
modérateur qui la répète. Voir [17-moderation.md](17-moderation.md).
