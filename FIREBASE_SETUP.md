# 🔥 Guide de Configuration Firebase pour Ablony

## ✅ Déjà fait
- ✅ Projet Firebase créé : `ablony-a5db9`
- ✅ Firestore activé et règles de sécurité déployées
- ✅ Index Firestore créés
- ✅ Configuration Flutter ajoutée (`google-services.json`, `firebase_options.dart`)

## 📋 À faire maintenant

### 1️⃣ Activer Firebase Authentication

**Console Firebase :** https://console.firebase.google.com/project/ablony-a5db9/authentication/providers

#### A. Google Sign-In ⚡ (Recommandé - le plus simple)

1. Va dans **Authentication > Sign-in method**
2. Clique sur **Google**
3. Active **Enable**
4. Ajoute un **Email de support** (ton email)
5. Clique sur **Enregistrer**

**Android (facultatif pour tester) :**
- Ajoute ton SHA-1 dans les paramètres du projet
- Commande : `cd android && ./gradlew signingReport`

**iOS :**
- Ajouter l'URL Scheme dans `ios/Runner/Info.plist` :
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.googleusercontent.apps.2762433205-XXXXX</string>
      </array>
    </dict>
  </array>
  ```

---

#### B. Facebook Login 📘 (Optionnel)

1. **Créer une app Facebook Developers :**
   - Va sur https://developers.facebook.com/apps
   - Clique sur **Create App**
   - Choisis **Consumer** comme type d'app
   - Nom : `Ablony`

2. **Récupérer les credentials :**
   - Dans le dashboard Facebook, note :
     - **App ID** (ex: 123456789012345)
     - **App Secret** (dans Settings > Basic)

3. **Configurer Firebase :**
   - Va dans **Authentication > Sign-in method**
   - Clique sur **Facebook**
   - Active **Enable**
   - Colle **App ID** et **App Secret**
   - Copie l'**OAuth redirect URI** fournie par Firebase
   - Retourne dans Facebook Developers > Produits > Facebook Login > Paramètres
   - Colle l'URI dans **Valid OAuth Redirect URIs**
   - Enregistre

4. **Configurer Android :**
   - Ajoute dans `android/app/src/main/res/values/strings.xml` :
     ```xml
     <string name="facebook_app_id">TON_APP_ID</string>
     <string name="fb_login_protocol_scheme">fbTON_APP_ID</string>
     ```
   - Ajoute dans `android/app/src/main/AndroidManifest.xml` :
     ```xml
     <meta-data 
       android:name="com.facebook.sdk.ApplicationId" 
       android:value="@string/facebook_app_id"/>
     ```

5. **Configurer iOS :**
   - Ajoute dans `ios/Runner/Info.plist` :
     ```xml
     <key>CFBundleURLTypes</key>
     <array>
       <dict>
         <key>CFBundleURLSchemes</key>
         <array>
           <string>fbTON_APP_ID</string>
         </array>
       </dict>
     </array>
     <key>FacebookAppID</key>
     <string>TON_APP_ID</string>
     <key>FacebookDisplayName</key>
     <string>Ablony</string>
     ```

---

#### C. Apple Sign-In 🍎 (Obligatoire pour iOS)

1. Va dans **Authentication > Sign-in method**
2. Clique sur **Apple**
3. Active **Enable**
4. Enregistre

**Configuration Xcode (iOS uniquement) :**
- Ouvre `ios/Runner.xcworkspace` dans Xcode
- Sélectionne le projet > Target Runner > Signing & Capabilities
- Clique sur **+ Capability**
- Ajoute **Sign in with Apple**

---

#### D. Email/Password 📧 (Optionnel - pour plus tard)

1. Va dans **Authentication > Sign-in method**
2. Clique sur **Email/Password**
3. Active **Enable**
4. Enregistre

---

### 2️⃣ Vérifier Firestore Database

**Console Firestore :** https://console.firebase.google.com/project/ablony-a5db9/firestore

1. Vérifie que la base de données est créée (normalement fait automatiquement)
2. Tu devrais voir les règles déployées dans l'onglet **Rules**
3. Vérifie les index dans l'onglet **Indexes**

**Collections qui seront créées automatiquement :**
- `users` : Profils utilisateurs
- `usernames` : Réservation des noms d'utilisateur (unicité)

---

### 3️⃣ Tester l'inscription

Une fois Google Sign-In activé, tu peux tester :

1. Lance l'app : `flutter run`
2. L'app affiche le splash → redirige vers onboarding
3. Clique sur **S'inscrire**
4. Clique sur **Continuer avec Google**
5. Sélectionne ton compte Google
6. Tu arrives sur la page Username ✅

**Vérifier dans Firebase :**
- Va dans **Authentication > Users**
- Tu devrais voir ton compte créé
- Va dans **Firestore Database**
- Tu devrais voir les documents créés dans `users` et `usernames`

---

## 🚀 Commandes rapides

```bash
# Déployer les règles Firestore
firebase deploy --only firestore

# Voir les logs Firebase
firebase functions:log

# Lister les projets
firebase projects:list

# Changer de projet
firebase use <project-id>
```

---

## 📱 Prochaines étapes (après tests)

1. [ ] Ajouter les vraies images de logo dans `assets/images/`
2. [ ] Tester Facebook et Apple Sign-In
3. [ ] Créer la HomePage (destination finale après inscription)
4. [ ] Ajouter les traductions i18n (actuellement en français hardcodé)
5. [ ] Intégrer un vrai service de captcha (reCAPTCHA)

---

## 🐛 Problèmes courants

**"Error: Google Sign-In failed"**
→ Vérifie que Google Sign-In est bien activé dans Firebase Console

**"PlatformException(sign_in_failed)"**
→ Sur Android : Vérifie le SHA-1 dans les paramètres Firebase
→ Sur iOS : Vérifie l'URL Scheme dans Info.plist

**"Missing GoogleService-Info.plist"**
→ Télécharge le fichier depuis Firebase Console > Project Settings > iOS app

**"Firestore permission denied"**
→ Redéploie les règles : `firebase deploy --only firestore`

---

## 📚 Documentation

- [Firebase Auth Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Facebook Auth Flutter](https://pub.dev/packages/flutter_facebook_auth)
- [Apple Sign-In Flutter](https://pub.dev/packages/sign_in_with_apple)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
