/* Service worker des notifications push sur le web.
 *
 * Le SDK Firebase Messaging enregistre `/firebase-messaging-sw.js` avant de
 * délivrer un jeton. Sans ce fichier, `getToken()` échoue et aucun jeton web
 * n'est enregistré : le navigateur demande la permission, l'utilisateur
 * l'accorde, et rien n'arrive jamais.
 *
 * Piège à connaître : la réécriture SPA de Firebase Hosting (`** →
 * /index.html`) répond **200** à cette adresse quand le fichier n'existe pas,
 * en servant le HTML de l'application. Pas de 404 dans l'onglet réseau — une
 * réponse d'apparence saine, que le navigateur refuse d'enregistrer comme
 * service worker parce qu'elle est en `text/html`. Le fichier existant, il est
 * servi avant toute réécriture.
 *
 * **Ce worker n'est enregistré que si quelqu'un demande les notifications**
 * depuis les réglages. Rien ici ne s'exécute à l'ouverture de l'application :
 * une version précédente le faisait et en empêchait le chargement sur iPhone.
 *
 * Portée : le SDK l'enregistre sous `/firebase-cloud-messaging-push-scope`, et
 * non à la racine, où `flutter_service_worker.js` officie — un même scope
 * n'admet qu'un service worker.
 *
 * Compat et non modulaire : un service worker ne charge pas de module ES par
 * `importScripts`.
 */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// Mêmes valeurs que `FirebaseOptions.web` dans lib/firebase_options.dart.
// Publiques par conception : ce fichier est servi à tout visiteur.
firebase.initializeApp({
  apiKey: 'AIzaSyBrBZLMWdxDa6mhXMRfMWQwqwBJRkTKeoc',
  appId: '1:2762433205:web:f214f935e6543ed33ad4fc',
  messagingSenderId: '2762433205',
  projectId: 'ablony-a5db9',
  authDomain: 'ablony-a5db9.firebaseapp.com',
  storageBucket: 'ablony-a5db9.firebasestorage.app',
});

const messaging = firebase.messaging();

/* Les messages portant une charge `notification` sont affichés par le SDK
 * lui-même. Ce gestionnaire ne sert qu'aux autres — pour qu'un message de
 * données ne passe pas inaperçu. */
messaging.onBackgroundMessage(function (payload) {
  if (payload.notification) return;

  const data = payload.data || {};
  self.registration.showNotification(data.title || 'Ablony', {
    body: data.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: data.type || 'ablony',
    data: data,
  });
});

/* Un appui reprend l'onglet Ablony déjà ouvert s'il y en a un, plutôt que
 * d'en empiler un nouveau à chaque notification. */
self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const cible = (event.notification.data && event.notification.data.link) || '/';
  event.waitUntil(
      self.clients.matchAll({type: 'window', includeUncontrolled: true})
          .then(function (fenetres) {
            for (const f of fenetres) {
              if ('focus' in f) return f.focus();
            }
            if (self.clients.openWindow) return self.clients.openWindow(cible);
          }),
  );
});
