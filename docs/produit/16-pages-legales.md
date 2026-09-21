# 16 — Pages légales et aide

**Lot 2 · 1,5 jour · dont l'essentiel est de la rédaction, pas du code**

---

## Le problème, et il est plus grave que prévu

### ablony.net est suspendu — abonnement non renouvelé

Vérifié le 16 septembre 2026. *C'est une facture d'hébergement en attente, et
elle sera réglée avant le lancement — ce point est donc réglé. Il reste
consigné ici parce qu'il conditionne tout le reste de la fiche.*

```
https://ablony.net/cgu.html                        → 302 → /cgi-sys/suspendedpage.cgi
https://ablony.net/politique_confidentialite.html  → 302 → /cgi-sys/suspendedpage.cgi
https://ablony.net/                                → 302 → /cgi-sys/suspendedpage.cgi
```

Le domaine entier renvoie la page de suspension de l'hébergeur. **Les deux
liens légaux de l'application mènent à une page vide.**

### Et les CGU n'existent pas

`app_urls.dart` pointe vers `ablony.net/cgu.html`. Le dépôt `ablony_landing`
contient `index.html`, `contact.html`, `mention_legal.html`,
`politique_confidentialite.html`, `linktree.html`, `waitlist.html` — **pas de
`cgu.html`**. Le lien était déjà cassé avant la suspension.

### Pourquoi cela bloque le lancement

Ce n'est pas une question de confort. Apple et Google refusent une application
dont la politique de confidentialité n'est pas accessible depuis un lien
fonctionnel — c'est vérifié à chaque soumission, et c'est un des motifs de
refus les plus courants. Le lien est demandé **dans le formulaire de
soumission**, pas seulement dans l'application : un examinateur le cliquera.

Et l'écran d'inscription fait accepter des conditions générales que personne
ne peut lire. Faire cocher « j'accepte les CGU » en pointant vers une page
suspendue est un problème avant d'être un problème d'App Store.

## La décision produit

**Rétablir l'hébergement, écrire les CGU, brancher quatre liens.** Dans cet
ordre.

Le code est presque fait : `WebViewPage.open()` existe, avec `hideSelectors`
pour masquer l'en-tête et le pied de page du site. Il ne reste qu'à l'appeler
depuis quatre entrées du profil.

**L'essentiel du travail est de la rédaction.** Les CGU d'une place de marché
qui détient l'argent de ses utilisateurs pendant la livraison ne s'improvisent
pas : il faut décrire le séquestre, les délais, les remboursements, les
litiges, et qui porte quoi. Comptez une journée d'écriture, et faites relire.

**Ce qu'on ne fait pas :** pas de pages natives (une WebView suffit et se
corrige sans republier l'application), pas de versionnement des CGU avec
réacceptation, pas de centre d'aide interactif.

---

## Les quatre pages, et ce qu'elles doivent dire

### 1. Conditions générales — **à écrire**

Le minimum pour votre modèle :

- **Qui est Ablony** et où la société est enregistrée.
- **Le rôle d'Ablony** : intermédiaire et transporteur, pas vendeur. C'est
  l'article qui vous protège le plus.
- **Le séquestre** : l'argent est retenu jusqu'à la remise, et pourquoi.
- **Les délais** : cinq jours pour déposer, remboursement au-delà ; la
  libération après confirmation de l'acheteur.
- **Les frais** : livraison, mise en avant. Dire ce qui est prélevé et quand.
- **Ce qui ne peut pas être vendu** : contrefaçons, produits réglementés.
- **Litiges et remboursements** : qui décide, sous quel délai.
- **Suppression de compte** : ce qui est effacé, ce qui reste.
- **Droit applicable** : Togo, et la juridiction compétente.

### 2. Politique de confidentialité — **existe, à reprendre**

À vérifier point par point, parce qu'un examinateur le fera : les données
collectées (identité, téléphone, localisation, photos), pourquoi, combien de
temps, avec qui elles sont partagées (Firebase, GeniusPay), et comment
demander leur suppression. Cette dernière doit correspondre à ce que
l'application fait vraiment — voir [13](13-entrees-mortes.md), qui ajoute
l'écran de suppression de compte.

### 3. Mentions légales — **existe**

À relire seulement.

### 4. Aide / Guide — **à écrire**

Une page, six questions, et elles se déduisent de ce que vous allez recevoir :

- Comment vendre un article ?
- **Où est mon argent après une vente ?** ← la plus fréquente
- Comment déposer mon colis ?
- Quand suis-je payé ?
- Je n'ai pas reçu mon colis, que faire ?
- Comment retirer mon argent ?

C'est aussi l'endroit où expliquer que **votre protection est plus forte que
celle d'un site d'annonces** : vos agents constatent la remise. Voir
[01](01-comparaison-vinted.md#votre-protection-acheteur-est-plus-forte-et-vous-ne-le-dites-nulle-part).

---

## Fichier par fichier

### Hébergement — **d'abord**

Rétablir `ablony.net`. Rien d'autre ne sert tant que le domaine renvoie une
page de suspension.

### Site — `ablony_landing/`

| Fichier | Action |
|---|---|
| `cgu.html` | **Créer**. Reprendre la structure de `politique_confidentialite.html` pour l'homogénéité. |
| `aide.html` | **Créer**. Les six questions ci-dessus. |
| `politique_confidentialite.html` | Relire et compléter. |
| `mention_legal.html` | Relire. |

Ces pages ont un `nav.navbar` et un `footer.footer` que la WebView masque
déjà — garder ces classes pour que `legalPageHideSelectors` continue de
fonctionner.

### Application — `lib/core/config/app_urls.dart`

```dart
static const String termsOfService = 'https://ablony.net/cgu.html';
static const String privacyPolicy  = 'https://ablony.net/politique_confidentialite.html';
static const String legalNotice    = 'https://ablony.net/mention_legal.html';   // ajouter
static const String helpCenter     = 'https://ablony.net/aide.html';            // ajouter
static const String about          = 'https://ablony.net/#a-propos';            // ajouter
```

### Application — `profile_page.dart`

Quatre entrées à brancher, toutes sur le même appel :

| Ligne | Entrée | Appel |
|---|---|---|
| 183 | Guide Ablony | `WebViewPage.open(context, url: AppUrls.helpCenter, title: l10n.ablonyGuide, hideSelectors: AppUrls.legalPageHideSelectors)` |
| 190 | Centre d'aide | même page, même appel |
| 211 | À propos | `AppUrls.about` |
| 218 | Informations légales | Une feuille à trois choix : CGU, confidentialité, mentions légales |

Guide et Centre d'aide pointant au même endroit, **n'en garder qu'une** :
« Aide ». Deux entrées vers la même page est exactement le genre de détail qui
fait paraître une application bâclée.

### Application — à vérifier

`lib/features/auth/` — l'écran qui fait accepter les CGU doit pointer vers un
lien qui fonctionne. Vérifier que le lien est cliquable et non un simple
libellé.

---

## Critères d'acceptation

- [ ] `https://ablony.net/` ne renvoie plus la page de suspension.
- [ ] Les quatre URL de `app_urls.dart` renvoient 200 — vérifié avec `curl -L`, pas dans un navigateur qui garde du cache.
- [ ] Depuis le profil : Aide, À propos et Informations légales ouvrent chacun la bonne page.
- [ ] L'en-tête et le pied de page du site sont masqués dans la WebView.
- [ ] Sur le web et le bureau, le lien s'ouvre dans le navigateur système (`WebViewPage.open` le fait déjà).
- [ ] À l'inscription, le lien vers les CGU est cliquable et mène à une page lisible.
- [ ] Une page inaccessible affiche un message clair, pas un écran blanc.
- [ ] Les CGU décrivent le séquestre, les délais de dépôt, les remboursements et les litiges.
- [ ] La politique de confidentialité décrit la suppression de compte, et l'application la permet vraiment.

## Le vrai travail est la rédaction

L'hébergement se règle par un paiement. Les CGU, non : elles n'ont jamais été
écrites, et celles d'une place de marché qui détient l'argent de ses
utilisateurs pendant la livraison ne s'improvisent pas.

Comptez **une journée d'écriture** pour les CGU et l'aide, et faites relire.
C'est la seule tâche du dossier qui ne se délègue pas à du code.
