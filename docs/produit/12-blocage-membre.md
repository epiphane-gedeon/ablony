# 12 — Bloquer un membre

**Lot 1 · bloquant · 1 jour**

---

## Le problème

Il n'existe aucune occurrence de `block` dans le code. N'importe qui peut
écrire à n'importe qui, autant de fois qu'il veut, sans que le destinataire
puisse y couper court.

Sur une application où des inconnus se parlent d'argent, c'est un défaut de
sécurité — et les magasins d'applications le vérifient. Apple exige, pour
toute application à contenu produit par les utilisateurs, « un mécanisme de
blocage des utilisateurs abusifs » (App Review Guidelines, 1.2). Google a une
exigence équivalente. C'est un motif de refus fréquent, et il coûte un cycle
d'examen entier.

## La décision produit

**Le blocage est unilatéral, silencieux et réciproque dans ses effets.**

- **Unilatéral** : je bloque, je n'ai rien à justifier.
- **Silencieux** : la personne bloquée n'est pas prévenue. La prévenir invite
  la représaille, et c'est précisément ce qu'on cherche à éviter.
- **Réciproque dans ses effets** : une fois le blocage posé, aucun des deux ne
  peut écrire à l'autre. Sinon le bloqueur aurait un avantage asymétrique
  étrange — il pourrait écrire sans recevoir de réponse.

Le blocage **n'est pas** un signalement. Bloquer règle mon problème ;
signaler porte le problème à Ablony. Les deux gestes sont proposés côte à
côte, et l'écran de blocage propose de signaler dans la foulée.

**Ce qu'on ne fait pas :** on ne masque pas les annonces de la personne
bloquée dans le catalogue. C'est le choix de Vinted, et il complique chaque
requête de liste pour un gain faible — on ne se fait pas harceler par une
annonce.

## Les règles

| Règle | Pourquoi |
|---|---|
| Blocage sans motif | Exiger une justification décourage l'usage. |
| La personne bloquée n'est pas prévenue | Éviter la représaille. |
| Aucun des deux ne peut écrire à l'autre | Pas d'avantage asymétrique. |
| Les conversations existantes deviennent muettes, pas invisibles | L'historique peut servir de preuve dans un litige. |
| Déblocable à tout moment | Un blocage n'est pas une sanction. |
| Une vente en cours n'est pas interrompue | Bloquer quelqu'un ne doit pas faire perdre son colis ni son argent. |

Ce dernier point mérite une décision explicite : si un acheteur bloque son
vendeur en pleine livraison, **la vente continue**. La messagerie se ferme, le
colis arrive, l'argent suit son cours. Les deux sont indépendants.

## Le parcours

Profil public → menu → « Bloquer ». Confirmation qui explique l'effet en une
phrase. Puis : « Voulez-vous aussi le signaler ? »

La liste des personnes bloquées vit dans les réglages, avec un bouton
« Débloquer » par ligne.

Dans une conversation avec une personne bloquée, le champ de saisie est
remplacé par un bandeau : « Vous avez bloqué cette personne. » avec
« Débloquer ».

---

## Fichier par fichier

### Données — Firestore

Une collection à plat, identifiant composite :

```
blocks/{blockerId}_{blockedId} = {
  blockerId, blockedId, createdAt
}
```

L'identifiant composite rend le doublon impossible et permet de tester un
blocage par une lecture directe, sans requête. C'est ce qui permet de
l'appliquer dans les règles de sécurité, où les requêtes ne sont pas
disponibles.

### Règles — `firestore.rules`

```
match /blocks/{blockId} {
  // Chacun ne voit que ses propres blocages : savoir qui vous a bloqué
  // n'apporte rien et invite la représaille.
  allow read: if isAuthenticated()
    && resource.data.blockerId == request.auth.uid;

  // Créé et supprimé directement par le client : il n'y a rien à valider
  // côté serveur, et l'identifiant composite empêche le doublon.
  allow create: if isAuthenticated()
    && request.resource.data.blockerId == request.auth.uid
    && request.resource.data.blockedId != request.auth.uid
    && blockId == request.auth.uid + "_" + request.resource.data.blockedId;

  allow delete: if isAuthenticated()
    && resource.data.blockerId == request.auth.uid;

  allow update: if false;
}
```

Et la règle qui fait le travail, dans les messages :

```
function estBloque(autre) {
  return exists(/databases/$(database)/documents/blocks/$(request.auth.uid + "_" + autre))
      || exists(/databases/$(database)/documents/blocks/$(autre + "_" + request.auth.uid));
}
```

À ajouter à la condition d'écriture de `messages/{conversationId}/messages`.
Deux lectures supplémentaires par message envoyé : à votre volume, c'est
négligeable, et c'est la seule façon d'empêcher un client modifié de
contourner le blocage.

### Application — fichiers à créer

| Fichier | Rôle |
|---|---|
| `lib/features/block/data/block_repository.dart` | `block(uid)`, `unblock(uid)`, `watchBlocked()`, `isBlocked(uid)`. Écriture Firestore directe, pas de Cloud Function. |
| `lib/features/block/presentation/providers/block_provider.dart` | `blockedUsersProvider` (flux), `isBlockedProvider(uid)`. |
| `lib/features/block/presentation/pages/blocked_users_page.dart` | La liste, avec « Débloquer ». Vide, elle dit à quoi sert l'écran. |

### Application — fichiers à modifier

| Fichier | Modification |
|---|---|
| `lib/features/profile/presentation/pages/public_profile_page.dart` | Menu en haut à droite : « Bloquer » et « Signaler ». Si déjà bloqué, « Débloquer ». |
| `lib/features/messages/presentation/pages/chat_page.dart` | Si l'un des deux a bloqué l'autre, remplacer le champ de saisie par le bandeau. L'historique reste lisible. |
| `lib/features/messages/presentation/pages/messages_page.dart` | Marquer les conversations bloquées d'une icône discrète. Ne pas les masquer : elles contiennent peut-être une commande en cours. |
| `lib/features/profile/presentation/pages/settings_page.dart` | L'entrée « Personnes bloquées » — une des huit entrées mortes qui prend enfin vie. |
| `lib/core/navigation/app_router.dart` | Route `blocked_users` sous `/profile/settings`. |
| `firestore.rules` | Le bloc ci-dessus et `estBloque()` dans les messages. |
| `lib/l10n/*.arb` | Libellés ci-dessous. |

### Traductions

```
blockUser              Bloquer
unblockUser            Débloquer
blockConfirmTitle      Bloquer {username} ?
blockConfirmBody       Vous ne pourrez plus vous écrire. Cette personne ne sera pas prévenue. Une vente en cours suit son cours normalement.
blockDone              {username} a été bloqué.
blockAlsoReport        Voulez-vous aussi le signaler à Ablony ?
blockedUsersTitle      Personnes bloquées
blockedUsersEmpty      Vous n'avez bloqué personne.
blockedConversation    Vous avez bloqué cette personne.
blockedByOther         Vous ne pouvez plus écrire dans cette conversation.
```

---

## Critères d'acceptation

- [ ] Depuis un profil public, on bloque en deux gestes, avec une confirmation qui explique l'effet.
- [ ] La personne bloquée ne reçoit aucune notification.
- [ ] Aucun des deux ne peut envoyer de message à l'autre — vérifié **par les règles**, en écrivant directement dans Firestore avec le jeton, pas seulement en masquant le champ.
- [ ] Les conversations existantes restent lisibles.
- [ ] Une vente en cours entre les deux se poursuit : le colis avance, l'argent suit.
- [ ] La liste des personnes bloquées est dans les réglages, et le déblocage est immédiat.
- [ ] On ne peut pas se bloquer soi-même.
- [ ] Bloquer deux fois la même personne ne crée pas deux documents.

## Pourquoi une journée suffit

Il n'y a aucune Cloud Function à écrire, aucun état à synchroniser, aucune
notification à router. Un document, deux règles, trois écrans. C'est la
fonctionnalité au meilleur rapport entre ce qu'elle protège et ce qu'elle
coûte — et c'est aussi celle qui peut vous faire refuser par Apple si elle
manque.
