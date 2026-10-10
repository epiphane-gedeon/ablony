/* Service worker des notifications push sur le web.
 *
 * **Pourquoi ce fichier doit exister.** Le SDK Firebase Messaging enregistre
 * `/firebase-messaging-sw.js` avant de demander un jeton. Sans lui,
 * `getToken()` échoue et aucun jeton web n'est jamais enregistré : le
 * navigateur demande bien la permission, l'utilisateur l'accorde, et rien
 * n'arrive jamais — ni bannière, ni son.
 *
 * L'absence était d'autant plus difficile à voir que la réécriture SPA de
 * Firebase Hosting (`** → /index.html`) répondait **200** à cette adresse,
 * avec le HTML de l'application. Pas de 404 dans l'onglet réseau : une page
 * HTML servie en `text/html`, que le navigateur refuse d'enregistrer comme
 * service worker. Le fichier existant désormais réellement, Hosting le sert
 * avant toute réécriture.
 *
 * **Portée.** Le SDK enregistre ce worker sous
 * `/firebase-cloud-messaging-push-scope`, et non à la racine : il ne rentre
 * donc pas en conflit avec `flutter_service_worker.js`, qui occupe `/`. Un
 * même scope n'admet qu'un service worker, le second remplaçant le premier.
 *
 * **Compat et non modulaire** : un service worker ne peut pas charger de
 * module ES par `importScripts`.
 */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// Mêmes valeurs que `FirebaseOptions.web` dans lib/firebase_options.dart.
// Elles sont publiques par conception : ce fichier est servi à tout visiteur.
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
 * lui-même. Ce gestionnaire ne sert qu'à ceux qui n'en portent pas — et à
 * garantir qu'une notification reste affichée dans ce cas plutôt que d'être
 * silencieusement ignorée. */
messaging.onBackgroundMessage(function (payload) {
  if (payload.notification) return; // déjà affichée par le SDK

  const data = payload.data || {};
  const titre = data.title || 'Ablony';
  self.registration.showNotification(titre, {
    body: data.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: data.type || 'ablony',
    data: data,
  });
});

/* Un appui ouvre l'onglet Ablony déjà ouvert s'il y en a un, plutôt que d'en
 * empiler un nouveau à chaque notification. */
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
