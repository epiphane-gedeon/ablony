Analyse complète — Ablony

Synthèse de 4 audits menés en parallèle (auth/navigation, produit/vente/recherche, paiement/wallet/livraison, messagerie/social) + les points de sécurité déjà identifiés précédemment.


---

🔴 Bloquants critiques (à faire avant tout lancement réel)

1. Retrait des fonds du wallet — totalement absent (client ET serveur, wallet_page.dart:158 affiche juste "bientôt disponible"). Un vendeur accumule de l'argent qu'il ne peut jamais encaisser. C'est le plus gros chantier restant — UI + Cloud Function + intégration mobile money/virement.
2. Suppression de compte — absente à tous les niveaux. Obligatoire pour Apple/Google Store.
- 3. CGU / politique de confidentialité — absentes, liens morts dans l'inscription (email_signup_screen.dart:221,230). Obligatoire pour publication store.
4. initiatePayment/confirmPayment sans vérification App Check/ID token côté serveur — contrairement à confirmDelivery qui vérifie bien un token, ces deux endpoints Cloud Run sont appelables par quiconque connaît l'URL.
5. reCAPTCHA mort des deux côtés — token jamais envoyé au backend, fonction serveur verifyRecaptcha entièrement commentée. Inscriptions ouvertes aux bots.
6. Vérifier GENIUSPAY_WEBHOOK_SECRET en prod — le code désactive silencieusement la vérification de signature du webhook si la variable n'est pas configurée (retombe sur un secret placeholder). À confirmer côté functions/.env déployé.
- 7. Mot de passe oublié non branché (login_screen.dart:161) — le backend (sendPasswordResetEmail) existe déjà, personne ne l'appelle. ~15 min de travail, mais bloque définitivement un utilisateur qui perd son mot de passe.

🟠 Fonctionnalités importantes à finir

8. Page Paramètres quasi entièrement décorative — Compte, Paiements, Livraison, Sécurité, Notifications, Confidentialité : tous onTap: () {}. Seuls Langue/Thème/Déconnexion marchent.
9. Adresse de livraison ne persiste rien (add_address_page.dart:61).
10. "Marquer réservé" et "Masquer une annonce" — absents (product_detail_page.dart:880,889), pas de champ ni de méthode.
- 11. Filtre Prix de la recherche — stub "en développement" (search_results_page.dart:1286).
- 12. Recherche non scalable — .get() sur toute la collection produits + filtre côté client. Tiendra pour un petit catalogue, à migrer avant croissance (Algolia/Typesense ou requêtes composites Firestore).
13. Route /notifications non déclarée dans le router — la feature existe (domain/data/presentation complets) mais est inatteignable depuis l'app.
14. Mode de paiement enregistré — UI fictive, ne bloque pas le paiement lui-même, juste pas de sauvegarde pour la prochaine fois.

🟡 Qualité / cohérence (pas bloquant, mais nécessaire pour "fini")

- 15. Le pattern AppException documenté dans CLAUDE.md n'est réellement suivi que dans 4 fichiers (auth, category, product repos). Partout ailleurs (follow, wallet, reviews, reports, messages, notifications — 18+ occurrences sur 11 fichiers) c'est du throw Exception() brut ou carrément aucune gestion d'erreur (message_repository.dart n'a aucun try/catch sur 15+ appels Firestore).
- 16. print() de debug actifs en prod (app_router.dart, auth_providers.dart, product_repository_impl.dart).
17. Boutons visibles mais morts : "Traduire" (fiche produit), icône favoris de la recherche, redirection vers la page marque, bouton "aide" (wallet/settings).
18. Code mort du captcha (page retirée du router, fichiers/état jamais supprimés) — à nettoyer ou vraiment implémenter.
19. Partage sans deep-link natif — un lien partagé rouvre toujours le navigateur, jamais l'app installée.
20. .claude/settings.local.json non versionné mais contenant un mot de passe de keystore en clair — à gitignorer explicitement (déjà signalé plus tôt dans la conversation).

---

En résumé

Le cœur économique (poster une annonce, la vendre, payer, se faire livrer, discuter, négocier, laisser un avis) est réellement bien construit — mieux que la moyenne d'un projet solo à ce stade. Ce qui sépare l'app d'un lancement réel, c'est un petit nombre de chantiers précis mais non négociables : le retrait d'argent, la conformité légale/store, et le durcissement du serveur de paiement — plus un nettoyage de la gestion d'erreurs et des stubs visibles pour que ça ne se voie plus à l'usage.
