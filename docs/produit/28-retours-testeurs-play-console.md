# 28 — Retours des testeurs (réponse Play Console)

Rédigé le 2026-10-03 pour la question : « Fournissez un résumé des commentaires
que vous avez reçus des testeurs. Indiquez comment vous les avez recueillis. »

> ⚠️ **À vérifier avant envoi.** Les thèmes ci-dessous sont déduits des
> correctifs réellement livrés (git + journal d'avancement), pas des messages
> WhatsApp eux-mêmes, auxquels je n'ai pas accès. Relis chaque point : ce qui
> part chez Google doit correspondre à ce que les testeurs ont dit, pas à ce
> qu'on suppose. Les champs entre crochets sont à compléter par toi.

---

## Texte proposé (à coller dans le formulaire)

**Comment les commentaires ont été recueillis**

Les tests se sont déroulés avec un groupe restreint de testeurs au Togo,
recrutés dans notre entourage direct à Lomé. Les retours ont été recueillis de
façon individuelle, par **messages privés WhatsApp** : chaque testeur disposait
du contact direct de l'équipe et signalait librement ce qu'il rencontrait, au
moment où il le rencontrait. Nous avons privilégié ce canal parce qu'il est
celui que nos utilisateurs emploient déjà quotidiennement, et qu'il permet
d'obtenir des captures d'écran et des précisions immédiatement, dans un
échange conversationnel. [Nombre de testeurs : X] [Période : du … au …]

**Synthèse des commentaires reçus**

Les retours ont porté sur quatre domaines.

*1. Recherche et navigation.* C'est le sujet le plus signalé. Les testeurs
rapportaient qu'une recherche lancée depuis une marque ou une catégorie ne
renvoyait aucun résultat, et que le panneau « Filtrer » continuait d'afficher
« Tout » alors qu'un filtre venait d'être appliqué — avec un doute sur le fait
que le filtre soit réellement pris en compte. Plusieurs ont aussi demandé à
pouvoir rebondir depuis les caractéristiques d'une annonce.

*2. Réactivité de l'interface.* Plusieurs testeurs ont signalé devoir recharger
l'écran ou appuyer deux fois pour qu'une action soit prise en compte :
ajout en favori, déconnexion, envoi d'une offre.

*3. Parcours d'achat et de livraison.* Les retours ont porté sur le manque
d'informations de contact au moment de la commande, sur la difficulté à
retrouver un reçu après un paiement, et sur l'intérêt d'une prise en charge du
colis au domicile du vendeur.

*4. Clarté des frais et de la confiance.* Les testeurs ont demandé à voir
clairement ce qui leur serait prélevé avant de valider, en particulier au
moment d'un retrait.

**Ce que nous en avons fait**

Chaque signalement a donné lieu à un correctif livré et vérifié (liste détaillée
en annexe) : réparation complète de la recherche et des filtres, activation de
la persistance locale supprimant les délais perçus, ajout des coordonnées de
contact et d'une option d'enlèvement à domicile, redirection des notifications
vers le reçu concerné, et affichage systématique des frais et du montant net
avant toute validation. Un changement de prestataire de paiement a également
été conduit pour réduire fortement le coût des petites transactions, fréquentes
sur notre marché.

---

## Annexe — correctifs livrés depuis la première mise en ligne

Période couverte : du 13 septembre au 2 octobre 2026.
135 fichiers modifiés, ~24 000 lignes ajoutées.

### Recherche et navigation
- Une recherche lancée depuis une marque ou une catégorie renvoyait **zéro
  résultat** (requête vide traitée comme « aucune annonce »). Une requête vide
  parcourt désormais toutes les annonces en ligne, les filtres affinant ensuite.
- Un filtre précis ne trouvait rien s'il ne figurait pas dans la première page
  chargée. Ajout d'un chargement automatique quand un filtre est actif et que
  l'écran est presque vide.
- Le panneau « Filtrer » affichait encore « Tout » après application d'une
  taille ou d'une marque, et « Pertinence » après changement de tri — son
  contenu n'était construit qu'une fois.
- Les lignes Catégorie, Taille et État d'une annonce sont devenues cliquables
  et mènent à une recherche filtrée.

### Réactivité
- Favori, déconnexion et envoi d'offre demandaient un rechargement ou un double
  appui. Cause : la persistance locale n'était pas activée sur le web. Activée
  partout ; bouton favori rendu optimiste ; déconnexion désormais attendue
  avant redirection.

### Achat, livraison, suivi
- Collecte du nom et du **numéro de téléphone** de l'acheteur au moment de la
  commande, pour la traçabilité du colis.
- Nouvelle option : **enlèvement du colis au domicile du vendeur**.
- Notification de paiement débloqué pour le vendeur.
- Formulaire de litige dédié au vendeur.
- Points relais : sélection automatique quand un seul est actif ; option
  masquée quand aucun ne l'est.
- Clic sur une notification d'achat → ouverture directe du **reçu** concerné.
- Flèche retour du reçu → retour à l'accueil quand l'écran précédent n'existe
  plus (cas du retour de paiement).
- Mode de lancement permettant au vendeur d'**expédier lui-même**, avec preuve
  d'expédition obligatoire et vérification manuelle avant mise en transit.

### Paiement et frais
- Changement de prestataire de paiement. Sur une transaction de 500 F, le coût
  passe de 155 F à 25 F — déterminant sur un marché d'occasion où les montants
  sont faibles.
- Après un paiement sur le web, l'utilisateur atterrissait sur une page
  « introuvable ». Page de retour de paiement ajoutée.
- La carte et la fiche d'un article affichaient un prix protection incluse
  différent de celui facturé au panier. Unifié.
- Frais de retrait et **montant net affichés avant validation**.

### Compte et confidentialité
- Consentement aux e-mails commerciaux **modifiable** depuis le profil.
- Ville demandée à l'inscription, pour n'ouvrir la livraison que là où elle est
  réellement assurée.
- Politique de confidentialité mise à jour (prestataire de paiement réel).

### Partage
- Un lien d'annonce partagé affiche désormais une vignette avec la photo, le
  titre et le prix (WhatsApp, Facebook, etc.).
