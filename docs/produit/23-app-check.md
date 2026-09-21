# 23 — App Check

**Activé côté client le 16 septembre 2026. L'enforcement reste à armer, dans la console.**

---

## Ce qui est fait

`firebase_app_check` était déjà en dépendance mais n'était jamais activé.
Il l'est maintenant, dans `lib/main.dart`, juste après l'initialisation de
Firebase :

- **Web** — reCAPTCHA v3, avec la clé de site déjà en place
  (`6Le3NxYsAAAAAITnIke4lK2zXMgIFlJSA6FIocL9`) ;
- **Android** — Play Integrity ;
- **iOS / macOS** — App Attest, repli DeviceCheck sur les anciens appareils.

L'activation est enveloppée dans un try/catch : une attestation qui échoue
(émulateur, appareil rooté, réseau coupé) n'empêche jamais le démarrage.

## Ce qui reste, et pourquoi ce n'est pas dans le code

**L'enforcement n'est pas activé.** Tant qu'il ne l'est pas, l'application
envoie des jetons App Check qui sont seulement *observés* — rien n'est refusé.
C'est délibéré, pour la même raison qui traverse tout le projet : l'imposer
maintenant **bloquerait l'application déjà installée**, qui n'envoie aucun
jeton. C'est le piège « durcir le serveur pendant que l'ancien client tourne »,
rencontré sur les signalements et sur le modèle d'annonce.

La marche à suivre, une fois cette version publiée et adoptée (compter deux à
quatre semaines) :

1. **Enregistrer les applications** dans la console Firebase → App Check :
   - Android → fournisseur *Play Integrity* ;
   - iOS → *App Attest* ;
   - Web → *reCAPTCHA v3*, avec la clé de site ci-dessus.
2. **Observer le trafic** quelques jours dans l'onglet App Check : la console
   montre la part d'appels vérifiés. Attendre qu'elle soit proche de 100 %
   avant d'armer quoi que ce soit — c'est la preuve que les vrais appareils
   passent.
3. **Armer l'enforcement**, service par service : d'abord Cloud Functions
   (les parcours d'argent), puis Firestore et Storage. Un service à la fois,
   en surveillant les refus.

Rien de tout cela ne touche au code : App Check est prêt à être exigé, il
suffit de l'exiger côté console quand le trafic le permet.

## Le point de vigilance

Ne pas armer l'enforcement **avant** que la part d'appels vérifiés soit haute.
L'armer trop tôt, c'est refuser les appels des utilisateurs sur l'ancienne
version — soit exactement la panne qu'on cherche à éviter.
