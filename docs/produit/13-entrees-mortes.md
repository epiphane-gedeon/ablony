# 13 — Les 21 entrées mortes

**Lot 2 · 1,5 jour**

---

## Le problème

Vingt et une entrées de l'interface ne font rien. Treize au profil, huit aux
réglages. Ce sont des `onTap: () {}`.

Ces libellés viennent de Vinted : le squelette de l'interface a été copié
avant que les fonctionnalités n'existent. C'est une façon parfaitement
légitime de travailler — à condition de ne pas livrer les entrées vides.

**Pourquoi c'est plus grave qu'il n'y paraît.** Un bouton absent ne dit rien.
Un bouton qui ne répond pas dit quelque chose : que l'application est cassée.
L'utilisateur ne sait pas que la fonctionnalité n'existe pas — il croit que
son appui n'a pas été pris, réessaie, appuie plus fort, et finit par douter du
reste. Sur une application où il s'apprête à saisir un numéro de mobile money,
ce doute coûte cher.

## La décision produit

**Trois sorts, pas deux.** Chaque entrée est soit branchée, soit retirée, soit
gardée avec une étiquette honnête. La troisième catégorie doit rester très
petite — deux entrées au maximum — sinon elle redevient le problème qu'elle
prétend résoudre.

Ce travail coûte une journée et demie et change l'impression générale plus que
n'importe quelle fonctionnalité de la liste.

---

## Le profil — `lib/features/profile/presentation/pages/profile_page.dart`

| Ligne | Entrée | Sort | Pourquoi |
|---|---|---|---|
| 109 | Inviter des amis | **Retirer** | Le parrainage n'existe pas. Rien à faire croître au jour 1. |
| 137 | Ventes et achats | **Brancher** | Voir [15](15-historique-commandes.md). C'est l'entrée la plus cherchée après un achat. |
| 144 | Outils de promotion | **Brancher** | La mise en avant existe déjà (`boost_bottom_sheet.dart`). Il manque seulement l'écran qui liste ses annonces et propose de les mettre en avant. |
| 151 | Personnalisation | **Retirer** | Recouvre des préférences qui n'existent pas. |
| 159 | Remise sur lot | **Retirer** | Les lots sont hors périmètre. Voir [99](99-apres-le-lancement.md). |
| 166 | Mode vacances | **Retirer** | Hors périmètre. |
| 174 | Dons | **Retirer** | Suppose des partenariats inexistants. |
| 183 | Guide Ablony | **Brancher** | Une page web dans une WebView. Voir [16](16-pages-legales.md). |
| 190 | Centre d'aide | **Brancher** | Idem. |
| 204 | Paramètres des cookies | **Retirer** | Une application mobile ne pose pas de cookies. L'entrée vient du site web de Vinted. |
| 211 | À propos | **Brancher** | WebView. |
| 218 | Informations légales | **Brancher** | WebView. **Obligatoire** — voir [16](16-pages-legales.md). |
| 225 | Notre plateforme | **Retirer** | Page institutionnelle sans contenu. |

**Bilan : 6 branchées, 7 retirées.**

## Les réglages — `settings_page.dart`

| Ligne | Entrée | Sort | Pourquoi |
|---|---|---|---|
| 39 | Informations du profil | **Brancher** | Un écran de modification du profil : photo, nom affiché, ville. Les champs existent déjà sur `User` et `updateUserProfile` sait les écrire. **Une demi-journée, et c'est attendu.** |
| 44 | Paramètres du compte | **Fusionner** | Redondant avec le précédent. Retirer. |
| 49 | Paiements | **Retirer** | Aucun moyen de paiement enregistré : chaque achat redemande le numéro. |
| 54 | Expédition | **Retirer** | L'adresse se choisit à l'achat. Une adresse par défaut est un confort d'après-lancement. |
| 59 | Sécurité | **Brancher** | Changement de mot de passe. Le serveur sait déjà le faire. |
| 71 | Mobile | **Retirer** | Le numéro se saisit au paiement. |
| 76 | E-mail | **Brancher** | Afficher l'adresse et son état de vérification, avec « renvoyer le lien ». La vérification existe côté serveur et n'est exposée nulle part. |
| 109 | Confidentialité | **Remplacer** | Devient **« Personnes bloquées »** — voir [12](12-blocage-membre.md). |

**Bilan : 4 branchées, 4 retirées.** Et il faut **ajouter** une entrée
« Supprimer mon compte » : la suppression existe côté serveur, elle n'est
accessible depuis aucun écran, et **Apple l'exige** pour toute application
permettant de créer un compte (App Review Guidelines 5.1.1 v). C'est un motif
de refus certain.

---

## Fichier par fichier

### À créer

| Fichier | Contenu |
|---|---|
| `lib/features/profile/presentation/pages/edit_profile_page.dart` | Photo (réutiliser `image_picker_grid.dart` avec `maxImages: 1`), nom affiché, ville. Appelle `authRepository.updateUserProfile`. |
| `lib/features/profile/presentation/pages/security_page.dart` | Changement de mot de passe : ancien, nouveau, confirmation. Appelle la route existante. Masquer l'écran si le compte est social (`user.hasPassword == false`) et expliquer pourquoi. |
| `lib/features/profile/presentation/pages/email_settings_page.dart` | L'adresse, son état, « renvoyer le lien de vérification ». |
| `lib/features/profile/presentation/pages/delete_account_page.dart` | Explique ce qui est supprimé et ce qui reste (les annonces vendues restent dans l'historique des autres). Demande le mot de passe. Appelle `deleteAccount`. |
| `lib/features/product/presentation/pages/promotion_page.dart` | Ses annonces actives, avec « Mettre en avant » par ligne — ouvre `boost_bottom_sheet.dart` qui existe déjà. |

### À modifier

| Fichier | Modification |
|---|---|
| `profile_page.dart` | Retirer 7 entrées, brancher 6. |
| `settings_page.dart` | Retirer 4, brancher 4, ajouter « Supprimer mon compte ». |
| `app_router.dart` | Routes : `edit_profile`, `security`, `email_settings`, `delete_account`, `promotion`, `blocked_users`. |
| `lib/l10n/*.arb` | Retirer les clés devenues inutiles (`inviteFriends`, `personalization`, `bundleDiscount`, `vacationMode`, `donations`, `cookieSettings`, `ourPlatform`, `payments`, `shipping`, `mobile`, `accountSettings`) et ajouter celles des nouveaux écrans. |

**Sur les clés de traduction.** Les retirer plutôt que les laisser : une clé
orpheline réapparaît dans six mois dans une entrée qu'on croit nouvelle. Le
projet en compte 534 ; en retirer onze est une hygiène, pas une optimisation.

---

## Critères d'acceptation

- [ ] Aucun `onTap: () {}` ne subsiste dans `profile_page.dart` ni dans `settings_page.dart`.
- [ ] `grep -rn "onTap: () {}" lib/features/` ne renvoie rien.
- [ ] « Supprimer mon compte » existe, explique ce qui est supprimé, et fonctionne.
- [ ] Le changement de mot de passe est masqué — avec explication — pour un compte créé par Google, Facebook ou Apple.
- [ ] Modifier son nom affiché met à jour le profil public sans redémarrer l'application.
- [ ] Les clés de traduction retirées ne sont plus référencées : `flutter analyze` ne signale rien.

## L'ordre conseillé

Commencer par **retirer les onze entrées**. C'est une heure de travail, et
l'application paraît immédiatement finie. Brancher ensuite, dans l'ordre :
suppression de compte (obligation Apple), informations du profil, sécurité,
e-mail, promotion. Les WebView viennent avec [16](16-pages-legales.md).
