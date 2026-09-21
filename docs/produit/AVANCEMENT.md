# Avancement

*Où en est la mise en œuvre du périmètre décrit dans
[02-perimetre-mvp.md](02-perimetre-mvp.md). Mis à jour le 16 septembre 2026.*

---

## Lot 1 — terminé

| # | Chantier | État |
|---|---|---|
| [19](19-modele-annonce.md) | Modèle d'annonce | ✅ `status` · `moderationStatus` · `isListable`, reprise faite, déclencheur déployé |
| [10](10-retraits.md) | Retraits | ✅ écrans, frais et trace. **Les appels au fournisseur attendent la clé d'API** |
| [18](18-recherche.md) | Recherche | ✅ `searchTokens`, pagination, reprise faite |
| [11](11-litige-acheteur.md) | Litige acheteur | ✅ `openDispute` · `listDisputes` · `resolveDispute`, gel, écran, onglet d'administration |
| [21](21-taches-planifiees.md) | Tâche planifiée | ✅ `hourlyTasks` — purge, levée des suspensions, deux horloges de livraison |
| [20](20-sanctions.md) | Sanctions | ✅ avertissements, suspensions, `banUser` avec ses deux garde-fous |
| [17](17-moderation.md) | `ablony_admin` | ✅ cinq files, rôles, réservation, trace — et une image Docker |
| [12](12-blocage-membre.md) | Bloquer un membre | ✅ règles éprouvées à l'émulateur, liste, bandeau de conversation |

## Lot 2 — terminé

| # | Chantier | État |
|---|---|---|
| [13](13-entrees-mortes.md) | 21 entrées mortes | ✅ **0 `onTap: () {}` restant** — 12 retirées, 9 branchées |
| [14](14-boite-notifications.md) | Boîte de notifications | ✅ liste, cloche à l'accueil, **une seule table de routage** partagée avec le push |
| [15](15-historique-commandes.md) | Ventes et achats | ✅ deux onglets, l'action attendue en bouton |
| [16](16-pages-legales.md) | Pages légales | ✅ `cgu.md` et `aide.md` écrites, quatre liens branchés |

---

## Lot 3 — après le lancement (en cours)

Des ajouts décidés une fois le MVP fonctionnel, pour tenir les promesses du
lancement et ouvrir la monétisation.

| Chantier | État |
|---|---|
| **Badges fondateur & star** | ✅ `UserBadges` partout où un nom apparaît (fiches, chats, messages, avis, recherche, liste des bloqués). Fondateur = puce bleue, star = étoile dorée. Champs `isFounder`/`isStar` **serveur uniquement**, gelés par les règles. Attribution star par l'admin (`setUserStar`). Tous les comptes existants passés en fondateurs (`backfill_founders.js`). |
| **Boosts accumulables** ([24](24-boosts.md)) | ✅ Solde `boostCredits` sur le profil, **serveur uniquement**, gelé par les règles (test `boosts.test.mjs`, 7/7). Trois voies : dépenser un boost de la réserve (`applyBoost`, sans paiement), booster à l'unité pour 500 F (inchangé), ou acheter un lot d'avance (`type: boostpack` → `finalizeBoostPack`, quantité validée serveur). La durée de 48 h court à l'**usage**, pas à l'achat. Page « Outils de promotion » = réserve + achat + mise en avant par annonce. Premium (plus tard) créditera ce même solde. |

| **Envoi d'images (web)** | ✅ Le sélecteur rendait un `File` de `dart:io`, inexistant sur le web : tout envoi d'image depuis le navigateur échouait. Passage à `XFile` + `putData` partout (chat, profil, litiges), aperçu en `Image.memory`. |
| **Photos de profil et de litige** | ✅ Bug silencieux **sur toutes les plateformes** : la grille rend des `XFile`, mais le code filtrait sur `whereType<File>()` — toujours vide. La photo de profil n'était donc jamais envoyée, et les litiges partaient sans leurs photos. |
| **Recherche d'adresse de livraison** | ✅ Barre de recherche en tête de carte : on ne se fait pas forcément livrer là où l'on se trouve. Le géocodage passe par la Cloud Function `geocodeSearch` (et non le paquet `geocoding`, qui ne gère qu'Android/iOS et rendait la recherche inerte sur le web) ; résultats restreints au Togo et au Bénin, clé Google côté serveur. Repli automatique par ville : « Agoe » seul retombait sur le centre du Togo, « Agoe, Lomé » trouve — 8 quartiers testés sur 8. |
| **Cache web** | ✅ `main.dart.js`, `index.html` et le service worker gardent le même nom à chaque build et étaient servis avec `max-age=3600` : après un déploiement, les utilisateurs continuaient d'exécuter l'ancienne version jusqu'à une heure (et plus via le service worker). Passés en `no-cache` dans `firebase.json` — stockage conservé, mais revalidation par ETag. |
| **Suggestions au fil de la frappe** | ✅ `placeSearch` (Autocomplete + Place Details) avec jeton de session, debounce 350 ms et minimum 3 caractères — les trois garde-fous qui contiennent la facture, Autocomplete se facturant à la frappe. Repli par géocodage sur la touche Entrée, qui ne dépend pas de Places. |
| **Piège `1 << 32` (web)** | ✅ Le jeton de session utilisait `Random().nextInt(1 << 32)`. Compilé en JavaScript, `1 << 32` vaut **0** (opérations binaires sur 32 bits) et `nextInt(0)` lève une `RangeError`, jetée **depuis `onChanged`** donc de façon synchrone : ni suggestion, ni message, rien — et invisible sur mobile, où la même ligne passe. Plafond ramené à `0x7FFFFFFF`, vérifié en compilant réellement en JS. La génération du jeton est désormais protégée pour qu'une erreur ne puisse plus être avalée. |

| **Boosts masqués sur mobile** | ✅ Un boost est un service **numérique** : Play et l'App Store imposent leur propre facturation, pas GeniusPay (les articles, biens physiques, restent exemptés). En attendant Play Billing, `boostsDisponibles` (dans `boost_config.dart`) masque les 4 entrées — menu profil, bouton de la fiche produit, pastille de « Mes annonces », page promotion — **et** ferme la route, atteignable par lien direct. Le web n'est pas concerné : aucun magasin, boosts pleinement actifs. |
| **Garde-fou passage en live** | ✅ `confirmPayment` tolérait un statut non confirmé si la référence commençait par `SANDBOX_`. Le contournement est désormais conditionné à `MODE_BAC_A_SABLE`, déduit du préfixe des clés : poser des clés `pk_live_` l'éteint **automatiquement**, sans geste à ne pas oublier. |

| **Fenêtre des fondateurs, pilotée par l'admin** | ✅ Le badge était posé **par le client** (`userData['isFounder'] = true`), sans condition ni fin : rien ne l'aurait arrêté, et fermer la fenêtre aurait exigé que chacun mette son application à jour — une version ancienne aurait continué d'en distribuer. Pire, la règle de création ne l'interdisait pas : un client modifié pouvait se l'attribuer. Désormais le déclencheur serveur `onUserCreated` fait autorité et **écrase ce que le client écrit**, d'après `config/badges.foundersOpen`. Interrupteur dans la console admin (`setFoundersOpen`, admin uniquement), effet **immédiat sur toutes les versions installées**. Aucune fermeture automatique, par choix. Testé : fenêtre ouverte → badge posé ; fermée → pas de badge ; fermée + client malveillant écrivant `isFounder: true` → **corrigé à false**. |
| **Messagerie : dire ce qui n'est pas protégé** | ✅ La politique disait « les échanges avec l'application sont chiffrés » — vrai du transport, mais lisible comme du chiffrement **de bout en bout**, qui n'existe pas ici (`text` et `imageUrl` sont stockés en clair, aucun chiffrement applicatif). Réécrit en deux blocs explicites — ce qui est protégé, ce qui ne l'est pas — et l'avertissement est repris **dans l'écran de conversation**, en tête du fil et seul à l'écran sur une conversation neuve : c'est là que se joue l'arnaque au faux support réclamant un code SMS, pas dans un document qu'on lit rarement. |
| **Documents légaux réécrits** | ✅ La politique de confidentialité ne décrivait que le formulaire de liste d'attente du site et affirmait « les données ne sont pas partagées avec des services tiers » — faux (Google/Firebase, GeniusPay, Google Maps) — et « le site n'utilise pas de cookies », sans dire ce que l'application conserve sur l'appareil. Réécrite à partir d'un inventaire du code : porte-monnaie (nom, nationalité, date de naissance), adresse et coordonnées GPS de livraison, destinataire des retraits, messages, signalements, jetons de notification, événements d'usage, plantages. Mentions légales corrigées : l'hébergeur déclaré était encore LWS. Adresse de contact harmonisée (trois variantes circulaient : `.net`, `.com`, et une adresse personnelle). ⚠️ **À faire relire par un juriste** — ces textes engagent. |
| **Pages légales sur Firebase** | ✅ InfinityFree répondait par un **défi JavaScript anti-robot** (880 octets de script au lieu de la page) : lisible par un navigateur, illisible par la vérification automatique de Google Play. Le site est déployé sur `ablony-site.web.app` (second site du même projet Firebase), avec exclusion explicite du `.env` (identifiants SMTP), de `data/` (adresses e-mail de la liste d'attente) et des `*.php` — que Firebase renverrait **en texte brut**, exposant la logique d'envoi de mail. Vérifié : pages en contenu réel, secrets en 404. ⚠️ Les deux formulaires (liste d'attente, contact) dépendent de PHP et ne fonctionnent pas sur cette copie — voir `ablony_landing/DEPLOIEMENT.md`. |
| **Site public centralisé** | ✅ `AppUrls.siteBase` est désormais **le seul endroit à changer** quand le site déménage : les cinq adresses (CGU, confidentialité, mentions légales, aide, à propos) en découlent. Pointé provisoirement sur `ablony.infinityfree.me`, `ablony.net` étant suspendu. |
| **Choix du pays suspendu** | ✅ `FeatureFlags.choixPaysActif = false` : l'inscription retient le Togo sans poser la question. L'écran existe toujours et reste l'étape qui finalise l'inscription — il se contente de choisir seul, ce qui évitait de dupliquer la création de compte dans les trois écrans qui y mènent. À rallumer pour l'ouverture au Bénin. |
| **Internationalisation** | ✅ Audit : la couverture ARB était en fait complète (709 clés des deux côtés), mais **34 textes français étaient écrits en dur** dans 13 fichiers, contournant l10n. Tous extraits (28 nouvelles clés FR+EN), plus 6 libellés du PDF de reçu qui n'utilisaient pas des clés pourtant existantes. Clé de template `homeWelcome` (« Hello World! 🎉 ») supprimée. Vérifié : **0 texte en dur restant**, 736 clés à parité. |
| **Échafaudage retiré** | ✅ Le bouton « Adresse par défaut » de la carte posait une adresse en dur (Boulevard du 13 Janvier, Lomé) et livrait donc tout le monde au même endroit. Marqué « temporaire » dans le code, rendu inutile par la recherche de lieu. |

| **Arborescence des catégories** | ✅ De 2 catégories / 36 entrées à **8 catégories, 47 sous-catégories, 206 feuilles**, déclarées dans `tools/seed_data/generer_taxonomie.py` (l'arbre tient sur un écran, les 253 entrées en sont dépliées). Défaut corrigé : **Robe** était sous « Bas » — elle a désormais sa propre branche. Ajouts propres au marché : tenues traditionnelles (pagne, bazin, boubou, agbada), mèches et perruques, livres scolaires, énergie solaire, marques de téléphones d'Afrique de l'Ouest (Tecno, Infinix, itel). |
| **⚠️ Attributs en ajout seul** | ✅ Découvert en migrant : les annonces stockent l'**indice** de la valeur (`condition: 1`), pas son texte. Insérer ou réordonner une valeur change donc le sens de toutes les annonces publiées, en silence. Les listes ont été refaites en ajout seul (21 valeurs ajoutées en fin), et `generer_taxonomie.py` **refuse désormais** toute modification qui ne serait pas un ajout en fin de liste. *Correction de fond à prévoir : stocker la valeur plutôt que sa position.* |
| **Attributs stockés en clair** | ✅ La correction de fond annoncée ci-dessous est faite : une annonce enregistre désormais `condition: "Bon état"` et non `condition: 2`. `ProductCondition` gagne `parLibelle()` et ses deux états manquants (« Neuf sans étiquette », « Pour pièces ») — sans eux, les choisir plantait sur `ProductCondition.values[5]`. La lecture tolère encore l'ancien format. **Effet de bord bienvenu** : le filtre par marque de la recherche comparait déjà du texte, il ne pouvait donc pas fonctionner avec des indices — il marche maintenant. |
| **Base remise à blanc** | ✅ `tools/vider_base.js` (simulation par défaut) : 220 documents supprimés sur 14 collections, suppression **récursive** (les messages vivent en sous-collection d'une conversation et seraient restés orphelins). Conservés : `users`, `usernames` (les réservations de pseudo sont adossées aux comptes), `config` et `relayPoints` (configuration d'exploitation, pas des données de test). |
| **Champ de saisie multiligne** | ✅ Le widget `Input` avait deux défauts : `InputType.multiline` ne donnait **jamais** plus d'une ligne (`maxLines` valant 1 par défaut l'écrasait), et un champ `maxLines: 5` gardait le clavier `text` — la touche Entrée validait au lieu d'aller à la ligne. Le type de clavier et l'action sont désormais déduits du nombre de lignes, `minLines` est ajouté (la description s'ouvre sur 4 lignes et grandit jusqu'à 10), et un mot de passe reste forcé sur une ligne comme Flutter l'exige. Couvert par `test/input_multiligne_test.dart` — **premiers tests de widget du projet**, 7/7. |
| **Retrait de la photo de profil** | ✅ La croix de suppression existait dans la grille, mais l'enregistrement ignorait le cas : `copyWith(photoUrl: null)` veut dire « ne change rien », pas « efface ». Une photo posée une fois ne pouvait donc plus jamais être retirée. Un drapeau `effacerPhoto` traverse la chaîne (entité → dépôt → Firestore, avec `FieldValue.delete()` car `toFirestore` omet les champs nuls), et le fichier est supprimé du stockage — sinon son URL de téléchargement resterait valable. Couvert par `test/user_photo_test.dart`, 7/7. |
| **Version affichée** | ✅ Les réglages annonçaient « v26.12.0 », écrit en dur, alors que le binaire était en 1.0.0+1. Elle est maintenant lue sur le paquet installé (`package_info_plus`) : elle suivra `pubspec.yaml` sans intervention. Une version fausse rend tout rapport de bogue inexploitable. |
| **Compteurs remis à zéro** | ✅ `tools/reinitialiser_compteurs.js` : les champs dénormalisés (annonces, ventes, note, avis, abonnés, avertissements) décrivaient des contenus supprimés — un vendeur noté 3,6 sur 5 avis dont aucun n'était consultable. 5 comptes corrigés. **Les soldes sont conservés** (1 126 680 FCFA + 3 crédits de boost) : l'option `--soldes` du script les remettra à zéro **au moment du déploiement**, avant le passage aux clés live — sans quoi cet argent de test deviendrait de vraies demandes de retrait. |
| **Marque cliquable** | ✅ Le lien de marque sur la fiche produit portait un `TODO` : il ouvre désormais la recherche avec le filtre marque déjà posé. Le widget `Link` maison est conservé. |
| **Bouton « traduire »** | ✅ Il portait `onPressed: () {}` — visible, cliquable, sans effet. Retiré, avec sa clé de traduction. |
| **Migration des données** | ✅ `tools/migrer_taxonomie.js` (simulation par défaut, `--appliquer` pour écrire) : 5 annonces réaffectées vers leurs nouveaux identifiants, 6 sous-catégories périmées supprimées — `.set()` n'efface rien, elles seraient restées visibles. Vérifié après coup : 0 annonce orpheline, 0 document périmé. |

**Décidé pour les boosts :** le boost occasionnel à 500 F reste possible en
plus de la réserve — accumuler n'enlève rien. Le lot payé depuis le
porte-monnaie apparaît au relevé (`boostpack` → « Mise en avant ») ; le boost
dépensé depuis la réserve (`boost_credit`, montant nul) n'y figure pas, faute
de mouvement de solde.

---

## Ce qui reste, et qui ne dépend pas du code

**Renouveler l'hébergement d'ablony.net.** Les quatre liens légaux pointent
vers `ablony.net` ; tant que le domaine renvoie la page de suspension, ils
mènent dans le vide — et c'est un motif de refus certain sur les deux
magasins.

**Faire relire les CGU.** Elles sont écrites à partir de ce que le code fait
réellement — délais, frais, séquestre, échelle des sanctions — mais elles
engagent juridiquement et n'ont pas été relues par un juriste.

**Quand un paiement reste bloqué — trois manques comblés.** Un débit sans
confirmation faisait conclure au vol, et rien ne permettait d'y remédier.
(1) *Écran de paiement* : passé 75 s, le sablier laisse place à « paiement en
cours de vérification », avec la référence à citer et la mention que rien n'est
perdu ; « Annuler » devient « Fermer », puisqu'il n'y a plus rien à annuler.
(2) *Relevé du porte-monnaie* : un paiement externe en attente était **invisible**
— filtré avec les opérations avortées. La personne avait payé et l'application
n'en gardait aucune trace. Il s'affiche désormais, marqué « en attente ».
(3) *Crédit manuel* (`creditManuel`, admin uniquement, plafond 500 000 F, motif
obligatoire, double confirmation) : de quoi réparer sur preuve de débit, avec
auteur, date, motif et référence de la transaction bloquée — au lieu d'envoyer
l'argent par mobile money hors du système, sans trace et avec un solde faux.

**Assistance intégrée.** Un fil par membre dans une collection `support`
distincte : les conversations entre membres sont adossées à une annonce, y
greffer l'assistance aurait demandé d'inventer un produit fictif. Le membre
écrit avec pièce jointe (la capture du débit est ce qui tranche le plus vite),
et retrouve l'échange. Accessible depuis le profil **et** depuis l'écran de
paiement bloqué, avec message pré-rempli portant la référence — c'est là qu'on
doute d'avoir été volé, et l'envoyer chercher une adresse e-mail à cet instant,
c'est le perdre. Règles : chacun son fil, le personnel accède à tous, un message
envoyé ne se réécrit pas.

**Rattrapage des paiements non confirmés.** Le webhook est le chemin normal,
mais il peut manquer à l'appel. `reconcilierPaiementsEnAttente` (ajouté à
`hourlyTasks`) interroge GeniusPay pour chaque transaction restée `pending`
entre 5 minutes et 48 h, et finalise celles qu'il déclare payées — achat, boost,
lot ou recharge. Sans double crédit, les finalisations étant idempotentes. Sans
ce filet, l'argent quitte le compte de l'acheteur et l'application reste
persuadée qu'il n'a pas payé, ce dont personne ne s'aperçoit avant une
réclamation. Index composite `(status, createdAt)` déployé.

**Formulaire de carte bancaire masqué (18/09/2026).** L'écran de paiement
capturait nom, **numéro de carte, expiration et cryptogramme**, avec une case
proposant d'« enregistrer la carte pour la prochaine fois » renvoyant vers un
écran *Paramètres > Paiements* inexistant. Or **rien n'était lu** : les
contrôleurs n'apparaissaient que dans `dispose()`, la carte n'était ni
transmise ni conservée, et la personne devait tout ressaisir sur la page du
prestataire. Trois problèmes en un — une promesse fausse faite à l'utilisateur,
une double saisie, et surtout **une entrée dans le périmètre PCI-DSS** pour des
champs qui ne servaient à rien. **Masqué et non supprimé** : le code reste
derrière `formulaireCarteActif` (à `false`), pour être branché correctement plus
tard. Tant qu'il l'est, la redirection vers le prestataire s'affiche à la place
et **aucune donnée bancaire n'est capturée** — vérifié, la page ne renvoie que
`method` et `phoneNumber`. Confirme la déclaration Data Safety « pas
d'informations de paiement collectées ».

**Connexion Google cassée en test interne — cause et correctif (17/09/2026).**
Déclarer les empreintes dans Firebase ne suffit pas : le `google-services.json`
**embarqué au build** ne contenait un client OAuth que pour la clé d'upload
(`74af5e82…`). Play App Signing re-signant l'application avec la clé de Google
(`5fb0b220…`), la signature installée ne correspondait à aucun client du
fichier — d'où l'échec, invisible en debug. Il faut donc **re-télécharger
`google-services.json` après avoir ajouté les empreintes, puis reconstruire** :
c'est le fichier compilé qui fait foi, pas la console. Release **1.0.0+2**
publiée, avec les trois clients OAuth (upload, Google, web).

**Empreintes de signature branchées (17/09/2026).** L'application Firebase
`com.ablony.app` ne déclarait **aucune empreinte** : la connexion Google aurait
échoué sur Android dès la première installation, alors qu'elle marchait en
debug. Quatre empreintes ajoutées — SHA-1 et SHA-256 de la **clé d'application
Google** (celle qui signe réellement ce que reçoivent les utilisateurs, Play App
Signing retirant la signature d'upload) et de la **clé d'upload** (builds
locaux). `assetlinks.json` porte désormais les deux SHA-256 : en retirer une
casserait les liens partagés dans l'un des deux cas.

**Release 1.0.0+1 construite avec Shorebird**, publiée sur Shorebird et prête
pour Play (`build/app/outputs/bundle/release/app-release.aab`, signée
`CN=Ablony`, 24,7–28,9 Mo par appareil). Construite **avec** Shorebird et non
avec `flutter build` : seule une version publiée ainsi peut recevoir un
correctif à distance, et c'est irrattrapable après coup. Corriger le changement
d'agrégateur se fera donc par `shorebird patch`, sans repasser par une review.
⚠️ Après création de l'app dans Play Console : relever le SHA-1 et le SHA-256 de
la **clé d'application Google** (pas la clé d'upload) et les poser dans Firebase
— sinon la connexion Google casse en production — et dans `assetlinks.json`.

**⚠️ Économie du produit : la marge est négative.** Les frais de paiement sont
**100 F + 11 %** (GeniusPay 100 F + 1 %, PaiementPro 10 % par-dessus), mesurés
sur cinq montants. Or la protection acheteur est à **5 %**. La marge vaut donc
`−6,55 % du prix − 11 % de la livraison − 100 F` : **négative quel que soit le
montant**. Sur un article à 5 000 F livré à 1 000 F, l'acheteur paie 6 250 F et
Ablony perd 537 F. Il faudrait 14–18 % de protection pour l'équilibre (Vinted :
~5 %). **À trancher avant le lancement.** Les recharges ont le même défaut :
`finalizeRecharge` crédite le montant demandé alors que le compte marchand ne
reçoit que le net — 200 F rechargés coûtent 122 F à Ablony. Piste recommandée :
supprimer la recharge, le porte-monnaie se remplissant par les ventes (modèle
Vinted), ce qui supprime un événement de frais sans justification.

**Routage vers la passerelle la moins chère.** Mesuré passerelle par passerelle
sur le compte : `paiementpro` 100 F + 11 % (seul à couvrir T-Money et Flooz),
`paystack` 100 F + 6 % (cartes), `wave` 100 F + 2,5 % (pas encore ouvert au
Togo). La carte part donc chez Paystack — cinq points économisés sur chaque
paiement par carte — et le mobile money chez PaiementPro, faute d'alternative.
Vérifié sur la fonction déployée. Une ligne à changer le jour où Wave ouvre au
Togo.

**Passerelle imposée : PaiementPro.** Aucun `payment_method` n'était envoyé à
GeniusPay, qui ouvrait donc sa page de sélection et y proposait des opérateurs
absents du Togo. `GENIUSPAY_CONFIG.GATEWAY = "paiementpro"` (T-Money et Flooz).
Vérifié sur la fonction déployée : l'URL renvoyée pointe bien vers
`paiementpro.net`. Une ligne à changer pour en essayer une autre — les valeurs
acceptées sont listées dans le commentaire.

**Paiement impossible sur le web — corrigé le 17/09/2026.** `webview_flutter` ne
déclare qu'Android, iOS et macOS : sur navigateur, `PaymentWebViewPage`
n'affichait qu'un écran gris vide, donc **aucun paiement ne pouvait aboutir
depuis le web** (le backend, lui, fonctionnait : la transaction était bien
créée). Sur le web, la page de paiement s'ouvre désormais dans un nouvel onglet
et l'application **surveille la transaction en base** jusqu'au verdict du
serveur — plus fiable que de se fier au retour de l'utilisateur, qui peut fermer
l'onglet. Sans risque de double crédit : `confirmPayment` et `finalizeRecharge`
sont tous deux idempotents. Mobile inchangé.

**Passage en clés live — fait le 17/09/2026.** Les trois clés GeniusPay sont en
`pk_live_` / `sk_live_` / `whsec_live`. Le webhook **n'existait pas** en live :
le secret n'est retourné qu'à la création, donc introuvable dans le tableau de
bord — il a fallu créer le webhook par l'API (`POST /merchant/webhooks`,
id 5046, événements `payment.success` et `payment.failed`). Vérifié après
déploiement : signature valide → 200, signature invalide → 401. Les soldes de
test (1 125 580 FCFA) et les crédits de boost ont été remis à zéro **avant** le
déploiement — sans quoi de la monnaie fictive serait devenue de vraies demandes
de retrait.

**Obtenir la clé d'API du fournisseur de retrait.** Tout est en place côté
Ablony : demande, retenue, frais, trace, file d'administration. Il manque
l'appel qui envoie réellement l'argent.

**Confirmer le barème des retraits.** 100 F + 1 %, plafonné à 2 100 F. À
500 000 F, cela ne fait que 0,4 % — à confronter aux tarifs réels T-Money et
Flooz.

**Publier l'application.** Les utilisateurs déjà installés interrogent
l'ancien schéma ; les trois booléens historiques sont toujours écrits pour
eux, à retirer deux à quatre semaines après l'adoption de la nouvelle version.

## Ce qui reste, et qui est du code

**La recette de bout en bout sur les parcours d'argent**, sur appareil réel —
les jours 23 à 25 du calendrier. Le projet n'a aucun test d'application, et
l'application déplace de l'argent.

---

## 2026-09-18 — Correctifs de lancement

**Play Store : refus « exigences Play Console ».** La déclaration
« Fonctionnalités financières » cochait « Paiements mobiles et portefeuilles
numériques » — réservée aux apps bancaires. Décochée (une marketplace n'est
pas un service financier régulé, le wallet est opéré par GeniusPay).
Catégorie déjà « Shopping ». App acceptée.

**Connexion Google KO sur la version Play Store (marchait en local).**
Diagnostic sur émulateur (Google Play image) : la version distribuée par Play
App Signing est signée `SHA-1 40:A1:E9:F5:A0:00:3F:FC:FE:B4:3C:D6:CA:A8:A8:20:12:D6:63:6E`
(SHA-256 `60:75:D6:DF:…:56:EE`), qui n'était **pas** enregistrée dans Firebase
— d'où « This android application is not registered to use OAuth2.0 ». Le
`5fb0…` lu dans Play Console n'était pas le bon certificat. Correctif : ajouter
ces deux empreintes dans Firebase (Paramètres projet → app Android). Sans
rebuild. *(action console côté fondateur)*

**Prix négocié ignoré au paiement.** `initiatePayment` recalculait le montant
attendu depuis `products.price` (prix de base) et ignorait l'offre acceptée →
« Montant incohérent : 3100 FCFA attendus » pour une vente négociée à 1450.
Correctif serveur : `prixNegocieAccepte(acheteur, vendeur, article)` relit le
montant depuis l'offre `accepted` de leur conversation ; utilisé comme
`productPrice` (cohérent jusqu'à la finalisation, `confirmPayment` relisant
`transaction.productPrice`). Aucun changement client → corrige aussi les apps
installées.

**Faille refermée en même temps.** La règle de mise à jour des messages laissait
n'importe quel participant écrire `offer.status` → un acheteur aurait pu
s'auto-accepter une offre dérisoire et fixer son prix. `majMessageIntegre()` :
passage à `accepted` réservé au destinataire (jamais l'émetteur) depuis
`pending` ; `offer.amount`/`offer.productId`/`senderId` figés ; `rejected` et
`read` restent libres. Vérifié par 6 tests règles sur l'émulateur (accept
destinataire ✓, auto-accept ✗, rejet ✓, falsification montant ✗, read ✓,
non-participant ✗). Règles + `initiatePayment` déployés.

**Montants fractionnaires (demi-francs).** Le frais de protection
(`prix × taux`) n'était pas arrondi → un total à 2522,5 FCFA, stocké en double,
qui menaçait de figer `availableAmount` en fractionnaire et de casser le compte.
Le XOF n'a pas de décimales. Correctifs : (1) `finalizePurchase` arrondit
`productPrice`/`walletDeduction`/`totalAmount` — seul point traversé par tous
les canaux (wallet, confirmPayment, webhook) ; (2) `initiatePayment` arrondit le
prix avant les frais et aligne les montants débités/stockés sur le total attendu
(entier) ; (3) client : `_protectionFees` arrondi (aperçu). Déployé
(initiatePayment, confirmPayment, geniusPayWebhook). Scan : 0 solde corrompu ;
1 transaction historique arrondie (cosmétique reçu). Script :
`functions/scripts/reparer_soldes_fractionnaires.js` (idempotent, `--apply`).

**Notation vendeur re-branchée.** La refonte du parcours de livraison (colis
Ablony, suppression du scan QR) avait supprimé la navigation vers l'écran
« Notez votre vendeur », qui suivait l'ancienne confirmation par scan. Le
back-end était intact (page, écriture d'avis unique par achat, trigger
`onReviewCreated` d'agrégation, règles strictes) — seul le point d'entrée
manquait. Rebranché dans `_confirmReception` (reçu) : après confirmation de
réception réussie → `/rate-seller`. Code Dart → actif au prochain build.

## 2026-09-19 — Boosts & prix entiers

**Boosts accumulables — vérifiés et finis.** Infra complète et déployée :
`applyBoost` (consomme 1 crédit, transactionnel), `finalizeBoostPack` (achat de
lots → `boostCredits`), solde gelé dans les règles, UI (solde, utiliser un
crédit, acheter un lot). Masqués sur Android (volontaire : vendre des boosts via
GeniusPay au lieu de Play Billing violerait la politique Play). Ajout : garde
« déjà boosté » (ne pas gaspiller un crédit/paiement à re-booster un produit
encore actif) côté client (bouton masqué) ET serveur (`applyBoost` +
branche boost de `initiatePayment`, refus avant tout débit).

**Prix entier imposé en FCFA (seule devise).** Le FCFA n'a pas de centimes ;
un prix à décimale était accepté. Enforcement par la VALEUR (`price % 1 == 0`,
testé : 2000.0 passe, 2000.5 refusé — ne casse pas le client qui écrit un double
entier), sur : création produit, édition produit (vendeur), et montant d'offre
(création message). Filet client : arrondi du prix à la vente ; `make_offer`
avait déjà `digitsOnly`. Vérifié par 8 tests règles + 6 de non-régression sur
l'intégrité des messages. Règles + `applyBoost`/`initiatePayment` déployés.

**Étiquette du colis téléchargeable.** La page d'étiquette (`ParcelLabelPage`)
affichait le QR + le code mais ne permettait que de copier le code — impossible
d'imprimer l'étiquette à coller sur le carton. Ajout d'un bouton « Télécharger
l'étiquette » qui génère un PDF A4 (logo, article, QR dessiné par `pw.Barcode`
— net à l'impression, pas rasterisé — et le code en clair + date limite de
dépôt), partagé/imprimé via `Printing.sharePdf`. Réutilise le pattern du reçu.
Code Dart → actif au prochain build.

**Étiquette épurée + suivi colis admin.** Étiquette PDF réduite au strict :
logo (SVG recoloré en bleu si présent, repli PNG), QR, code — retirés le
wordmark « ABLONY », le sous-titre, le nom du produit et la date de dépôt
(l'étiquette sert après le dépôt aussi). *En attente : un `assets/images/logo.svg`
fourni par le fondateur pour un logo bleu net.* Suivi colis dans l'admin
(`ParcelScanPanel`, onglet « Suivi colis », accessible à tout le staff) : saisir
le code de l'étiquette → `resolveParcel` (état, destination, étapes possibles) →
`recordParcelCheckpoint` pour enregistrer une étape. Règle le « le vendeur a
déposé » (bouton « Marquer déposé » = transition `awaiting_dropoff → dropped_off`,
notifie l'acheteur). Back-end déjà en place et déployé ; seule l'UI admin
manquait. Admin buildé + déployé (ablony-admin.web.app). L'étiquette (Dart) part
au prochain patch/build mobile.

**Logo étiquette (SVG bleu) + livraison.** L'étiquette pointe désormais sur
`assets/icons/logo_full.svg` (le wordmark blanc du splash), recoloré en bleu
`#2385AE` à la volée (`_svgEnBleu`) — net à l'impression. Web rebuildé +
redéployé. Release mobile propre **1.0.0+4** buildée avec TOUT (logique + étiquette
+ logo + icônes correctes) → AAB à envoyer au Store (remplace 1.0.0+3, jamais
publiée). Suivi colis admin déjà en ligne.

**Suivi colis complet (app + admin).** Côté app : la ligne d'état du reçu est
devenue une **frise chronologique** (Déposé → En acheminement → Point relais/
Livraison → Remis) avec horodatage par étape ; une **pastille de statut** de
transit s'affiche sur chaque commande de « Mes ventes et achats ». Alimenté par
un nouveau champ `stepsAt` (map statut→timestamp) écrit par `recordParcelCheckpoint`.
Côté admin : le panneau « Suivi colis » liste désormais les **colis en
circulation** (`listActiveParcels`, tri en mémoire, sans index composite) —
cliquables pour éviter de retaper un code. Fonctions + admin + web déployés.
Reste : build mobile (frise/pastille = Dart) — icônes nouvelles → une release,
pas un patch.

**Boosts : achat web, usage partout (Option A).** Scission de `boostsDisponibles`
(fonctionnalité visible/utilisable partout — appliquer un crédit n'est pas un
achat) et `boostsAchatDisponible` (achat dans l'app : web/desktop seulement ;
Android/iOS renvoient au web sans lien de paiement direct, pour éviter Play
Billing/StoreKit et les règles de « steering »). Sur mobile : solde + « utiliser
un crédit » visibles ; boutons d'achat remplacés par une mention neutre
(`boostBuyOnWeb`). Web **inchangé** (achat + application). Entrées boost
désormais visibles sur mobile pour que les crédits soient utilisables. Coté
serveur `applyBoost` (sans paiement) marche déjà partout. Change Dart → part au
build mobile final ; web non affecté (comportement identique).

**Note/avis sur son propre profil.** Le profil personnel (`profile_page`)
n'affichait ni la note ni les avis (seul le profil public le faisait). Ajout de
`StarRatingDisplay` (note + nombre d'avis) dans l'en-tête, et d'une entrée
« Voir mon profil public » (`/profile/:uid`) pour consulter les avis reçus tels
que les autres les voient. Web redéployé ; part au build mobile final.

**Note moyenne en grand sur le profil perso.** Sur son propre profil
(`profile_page`, onglet Profil), un bloc affiche désormais la note moyenne en
gros (« 4,0 » + grandes étoiles taille 30 + nombre d'avis), depuis l'agrégat
`user.rating`/`reviewsCount` — fiable, sans dépendre de la requête liste d'avis.
Affiché seulement si au moins un avis. Vérifié : l'avis existe bien (rating=4,
reviewsCount=1 sur le compte « vendeur »), la requête liste fonctionne
(index déployé) ; l'écran « vide » venait de regarder le profil d'un compte sans
avis. Web redéployé.

**Vrai bug de l'onglet Évaluations (profil à onglets).** La page du profil
personnel à onglets (`UserListingsPage`, `/profile/my-listings`, atteinte en
cliquant son nom) avait un `_buildEvaluationsTab` **codé en dur** : il affichait
toujours « Pas encore d'évaluations », sans jamais charger les avis. D'où le
vendeur (noté 4) qui voyait « vide ». Corrigé : l'onglet affiche maintenant la
**moyenne en grand** (« 4,0 » + grandes étoiles taille 32) puis la **liste des
avis** (`sellerReviewsProvider`, note + date + article + commentaire). Le bloc
que j'avais mis par erreur sur la page menu (`profile_page`) est retiré. Web
redéployé.

**« Voir mon profil public » réservé aux stars.** L'entrée de menu ajoutée au
profil perso est désormais gardée par `if (user.isStar)` — invisible pour un
membre ordinaire. Les avis restent accessibles à tous via le nom → onglet
Évaluations. Web redéployé.

**Scroll imbriqué fiche produit + suppression notif au swipe.** Fiche produit :
le contenu des onglets (dressing/similaires) était un `TabBarView` de hauteur
fixe 600px avec grilles à scroll interne → conflit de gestes (bloqué en haut de
la grille). Remplacé par le rendu de la grille de l'onglet courant en
`shrinkWrap`/`NeverScrollableScrollPhysics` (elle suit le scroll de la page ;
changement d'onglet via listener + setState). Notifications : chaque tuile
enveloppée dans un `Dismissible` (swipe gauche → `delete`, règles déjà OK), +
SnackBar de confirmation. Web redéployé.

**Recherche — préfixes (Option A).** `searchTokens` inclut désormais les
préfixes de chaque mot (« robe » → ro, rob, robe), mots entiers d'abord (le
plafond, monté à 120, ne tronque jamais un mot complet). → recherche à la frappe
(« chai » trouve « chaise »). Modifié dans `index.js` (`avecPrefixes` +
`onProductWritten` déployé) ET la copie du script `backfill_search_tokens.js`
(relancé `--force` : 11 annonces régénérées). Purement données serveur → actif
web + mobile sans rebuild. Filtres serveur (prix) non faits : Firestore ne
combine pas arrayContainsAny + range prix + orderBy date → resteront pour
Meilisearch.

**Notifications admin (badges de files).** Fonction `adminCounts` (staff,
agrégats `count()` — bon marché) : nombre d'éléments en attente par file
(modération produits `pending`, signalements `open`, retraits `requested`,
litiges `open`, assistance `unreadForStaff>0`). L'admin les affiche en **badges
rouges sur les onglets** (Annonces, Signalements, Litiges, Retraits, Assistance),
rafraîchis à l'ouverture puis toutes les 45 s. Plus besoin d'ouvrir chaque
onglet pour voir s'il y a du nouveau. Fonction + admin déployés.

**Recherche de membres insensible à la casse.** La requête mettait le terme en
minuscules mais comparait au champ `username` (casse préservée) → « Amina » ou
« Jean2 » introuvables. Ajout d'un champ `usernameLower` (écrit par
`UserModel.toFirestore`, donc à la création ET au rename), requête sur ce champ
avec borne ``. Backfill des 24 comptes (`backfill_username_lower.js`).
Règles OK (create en hasAll). Web redéployé ; mobile au build final.

**Frais de livraison par sous-catégorie (Firestore, éditable admin).** Le tarif
d'acheminement vient de la sous-catégorie du produit
(`config/subcategories/items/{id}.deliveryRelayXof/HomeXof`), sinon du défaut
global (`config/delivery`), sinon du repli code. Serveur autoritaire :
`fraisLivraison(method, subcategoryId)` dans `normalizeDeliveryChoice`
(initiatePayment). Fonctions admin `deliveryFees` / `setDeliveryDefault` /
`setSubcategoryDeliveryFee` (admin only). Panneau admin « Frais livraison »
(défaut + recherche/édition par sous-catégorie, ↺ pour revenir au défaut).
Client : `deliveryFeesProvider` (payment_page lit Firestore) → total affiché =
total facturé.
**Contrainte clé : défaut laissé à 1000/1500** pour ne pas casser les clients
mobiles existants (tarif figé) — tout tarif ≠ 1000/1500 leur donnerait « Montant
incohérent » en livraison à domicile. Ne changer le défaut / poser des overrides
qu'une fois le build mobile (lecture Firestore) diffusé et adopté. Web déjà OK.

**Filtres de recherche réparés.** Deux bugs : (1) le clic sur une marque (et la
navigation par catégorie) ouvrait la recherche avec `query: ''` → `searchProducts('')`
renvoyait **vide** → filtre sur rien = rien. Corrigé : une requête vide **parcourt
toutes les annonces en ligne** (isListable, plus récentes d'abord ; index déjà
déployé), les filtres affinent. (2) Les filtres tournent côté client sur la page
chargée → un filtre précis ne trouvait rien s'il n'était pas dans la première
page. Ajout d'un **auto-chargement** quand un filtre est actif et l'écran quasi
vide (gardes anti-boucle : ≥12 filtrés, ≤300 chargés, curseur non nul). Solution
d'attente avant le moteur dédié (Meilisearch). Client → web déployé, mobile au build.

**Lignes info produit cliquables (catégorie/taille/état).** Comme la marque,
les lignes Catégorie, Taille (si renseignée) et État de la section détails
mènent désormais à une recherche filtrée (`_buildDetailRow` accepte un `onTap` ;
route search-results + SearchResultsPage acceptent `size` = `attributeId:index`
et `condition` = `condition.index`). Base = parcours de toutes les annonces +
filtre + auto-chargement (cf. fix filtres). Web déployé, mobile au build.
Pagination home + recherche vérifiée : chargement au scroll, OK.

**Feuille « Filtrer » : valeurs figées + tri.** Le contenu du sheet « Filtrer »
était construit une seule fois (snapshot) : appliquer Taille ou Marque depuis
l'intérieur mettait bien à jour la page, mais la ligne du sheet restait « Tout ».
La ligne « Classer par » restait de même sur « Pertinence » (le tri, lui,
s'appliquait déjà côté résultats). Corrigé : le contenu est enveloppé dans un
`StatefulBuilder` et chaque sous-filtre passe par `_applyFilterChange` (setState
page + rebuild du sheet). Web déployé, mobile au build.

**Temps réel / réactivité (favoris, déconnexion, offres).** Symptômes signalés :
il fallait recharger ou taper deux fois pour voir un favori, une déconnexion ou
une offre pris en compte. Cause principale : la **persistance Firestore n'était
pas activée sur le web** (elle l'est par défaut sur mobile) → une écriture ne
remontait dans les streams qu'après l'aller-retour serveur. Correctifs :
(1) `main.dart` active la persistance + cache illimité sur toutes les plateformes
→ écritures émises depuis le cache local aussitôt (optimiste natif) ; (2) le
bouton favori (`FavToggle`) bascule maintenant en optimiste local et se
réconcilie avec le stream (revient à la vérité serveur en cas d'erreur) ;
(3) déconnexion : le `signOut()` n'était pas attendu et la boîte de confirmation
restait ouverte → on la ferme d'abord, on attend `signOut`, puis on redirige.
Chat/offres/messages sont déjà câblés sur des streams watchés → la persistance
suffit à supprimer la latence perçue. Mobile au build.

**Builds MVP (2026-09-20).** Version `1.0.1+5`. Web : `flutter build web --release`
+ `firebase deploy --only hosting` → https://ablony-a5db9.web.app (persistance
Firestore active en prod). Android : `shorebird release android` → AAB
`build/app/outputs/bundle/release/app-release.aab` (73 Mo), release Shorebird
`1.0.1+5` publiée (patchable via `shorebird patch --platforms=android
--release-version=1.0.1+5`). Reste : upload manuel de l'AAB sur la Play Console ;
iOS non buildé (nécessite macOS/Xcode). Dernière brique MVP identifiée : passage
de GeniusPay en live (Mobile Money Togo/Bénin).

**Contact acheteur au checkout + consentement email modifiable.**
- *Consentement* : la case emails marketing était déjà enregistrée à
  l'inscription (`marketingEmailsEnabled`). Ajout d'une bascule dans
  Réglages › Notifications pour l'activer/désactiver après coup (optimiste,
  via `updateUserProfile`). Ne concerne QUE le promotionnel — les emails de
  sécurité/vérification partent indépendamment.
- *Téléphone de livraison* : au checkout on ne collectait pas le numéro de
  l'acheteur. Désormais obligatoire pour LES DEUX modes (traçabilité) :
  domicile → champ téléphone ajouté au formulaire adresse ; relais → nouvelle
  tuile « Nom et téléphone ». Modèle : `DeliveryAddress.phone` +
  `DeliveryChoice.contactName/contactPhone` (dans `isComplete` et `toJson`).
- *Serveur* : `normalizeDeliveryChoice` capte le contact (NON obligatoire, pour
  ne pas casser les anciens clients) ; `notifyPurchase` le range dans le
  sous-document privé du colis (`parcels/{code}/private/destination`, invisible
  du vendeur) pour les deux modes ; `resolveParcel` renvoie `contact` (nom +
  tél) et la console admin (ParcelScanPanel) l'affiche avec lien `tel:`.
- *UI* : marge basse portée à 160px sous « Détail de la facture » (la dernière
  ligne passait sous le bouton fixe « Valider le paiement »).

**Déploiement (contact + consentement).** Functions déployées (`initiatePayment`,
`confirmPayment`, `geniusPayWebhook`, `resolveParcel` — quelques retries pour un
quota CPU Cloud Run transitoire). Web → https://ablony-a5db9.web.app. Console
admin → https://ablony-admin.web.app. Mobile : Shorebird **Patch 1** sur la
release `1.0.1+5` (canal stable), livré aux installs sur cette version.

**Ramassage à domicile (payé par le vendeur).** Nouvelle option : après une
vente, le vendeur peut demander qu'un agent vienne chercher le colis chez lui au
lieu de le déposer en relais — il paie un frais fixé PAR SOUS-CATÉGORIE.
- *Prix* : mirroir du système de frais de livraison. `fraisRamassage(subcat)` →
  `pickupXof` de la sous-catégorie, sinon `defaultPickupXof` (config/delivery),
  sinon repli code (1500). Admin : `deliveryFees`/`setDeliveryDefault`/
  `setSubcategoryDeliveryFee` gèrent désormais aussi le ramassage ; le panneau
  DeliveryFeesPanel a une colonne « Ramassage ».
- *Paiement* : nouveau `type: "pickup"` dans `initiatePayment` (vérifie que le
  demandeur est le vendeur du colis, impose le montant serveur), finalisé par
  `finalizePickup` (débit payeur, pas de contrepartie — service Ablony) ;
  branché sur les 4 sites de finalisation (wallet immédiat, confirmPayment,
  webhook, rattrapage). Réutilise porte-monnaie + Mobile Money + carte.
- *Enregistrement* : le colis reçoit `pickupRequested`/`pickupFeeXof` (lisible
  des deux parties) ; l'adresse + le téléphone du VENDEUR vont dans le
  sous-document privé `parcels/{code}/private/pickup` (invisible du vendeur ET
  de l'acheteur côté client ; les agents l'obtiennent par `resolveParcel`, qui
  renvoie désormais un objet `pickup`). Console admin (ParcelScanPanel) affiche
  l'adresse + le tél du ramassage avec lien d'appel.
- *UI vendeur* : bouton « Faites-vous récupérer le colis à domicile (payant) »
  sur la page étiquette (tant que le colis est à déposer et qu'aucun ramassage
  n'est déjà demandé). Recycle le formulaire d'adresse (nom+tél+localisation) et
  la page de paiement (mode ramassage). Mobile au prochain build/patch.

**Déploiement (ramassage).** 8 Cloud Functions déployées (initiatePayment,
confirmPayment, geniusPayWebhook, resolveParcel, deliveryFees,
setDeliveryDefault, setSubcategoryDeliveryFee, hourlyTasks) — aucun échec. Web →
ablony-a5db9.web.app. Admin → ablony-admin.web.app. Mobile : Shorebird **Patch 2**
sur `1.0.1+5` (contact acheteur + ramassage à domicile ; aucune icône nouvelle,
pas de tofu).

**File admin « Ramassages » (2026-09-21).** Un ramassage demandé n'était visible
que si un agent scannait pile le colis — personne n'était prévenu. Ajout d'un
onglet admin « Ramassages » avec badge : `adminCounts` renvoie désormais
`pickups` (colis `awaiting_dropoff` + `pickupRequested`, filtré en code, sans
index composite) ; nouvelle fonction `listPendingPickups` (colis à ramasser +
contact + adresse depuis le sous-doc privé). Panneau PickupsQueue : titre,
code, nom + tél (lien tel:), adresse + lien Maps, frais payé. Fonctions
déployées, admin en ligne.

**Notif vendeur « Paiement débloqué » sur confirmation acheteur.** Quand
l'acheteur confirmait la réception, `confirmDelivery` n'envoyait qu'un push
(type `delivery_confirmed`) — aucune notif persistante, le vendeur n'avait pas
de trace. Les autres chemins de libération (délai écoulé, résolution de litige,
release admin) utilisaient déjà `notifyUser` (persiste + push, type
`funds_released`). Aligné `confirmDelivery` sur `notifyUser` avec le montant
libéré. Type `funds_released` déjà géré côté client (router + tile) → serveur
uniquement, aucun build/patch mobile. Fonction déployée.

**Litige vendeur** : Patch Shorebird 4 publié (formulaire vendeur dédié).
