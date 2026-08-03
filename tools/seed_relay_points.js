/**
 * Seed de la collection `relayPoints` (points relais de livraison).
 * Coordonnées générées aléatoirement autour de Lomé et Cotonou — à
 * remplacer par de vraies adresses/coordonnées quand elles seront connues.
 *
 * Utilisation : node tools/seed_relay_points.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Génère un point aléatoire à ~1-6 km autour d'un centre-ville.
function jitter(center, maxKm) {
  const kmPerDegreeLat = 111;
  const kmPerDegreeLng = 111 * Math.cos((center.lat * Math.PI) / 180);
  const dLat = ((Math.random() - 0.5) * 2 * maxKm) / kmPerDegreeLat;
  const dLng = ((Math.random() - 0.5) * 2 * maxKm) / kmPerDegreeLng;
  return { lat: center.lat + dLat, lng: center.lng + dLng };
}

const LOME = { lat: 6.1256, lng: 1.2221 };
const COTONOU = { lat: 6.3703, lng: 2.3912 };

const relayPoints = [
  {
    name: 'Point Relais Lomé Centre',
    address: '12 Avenue de la Libération, Lomé',
    city: 'Lomé',
    hours: 'Lun-Sam: 8h-18h',
    ...jitter(LOME, 2),
  },
  {
    name: 'Relais Express Tokoin',
    address: '45 Rue du Commerce, Tokoin',
    city: 'Lomé',
    hours: 'Lun-Ven: 9h-17h',
    ...jitter(LOME, 4),
  },
  {
    name: 'Point Relais Hédzranawoé',
    address: '23 Boulevard Circulaire, Hédzranawoé',
    city: 'Lomé',
    hours: 'Lun-Sam: 8h-19h',
    ...jitter(LOME, 5),
  },
  {
    name: 'Relais Agoè',
    address: '67 Route Nationale, Agoè',
    city: 'Lomé',
    hours: 'Lun-Dim: 8h-20h',
    ...jitter(LOME, 6),
  },
  {
    name: 'Point Relais Cotonou Centre',
    address: 'Avenue Steinmetz, Cotonou',
    city: 'Cotonou',
    hours: 'Lun-Sam: 8h-18h',
    ...jitter(COTONOU, 2),
  },
  {
    name: 'Relais Express Akpakpa',
    address: 'Route des Pêches, Akpakpa, Cotonou',
    city: 'Cotonou',
    hours: 'Lun-Ven: 9h-17h',
    ...jitter(COTONOU, 4),
  },
];

async function seed() {
  console.log('🚀 Seed de relayPoints...\n');
  for (const point of relayPoints) {
    const { lat, lng, ...rest } = point;
    const doc = {
      ...rest,
      latitude: lat,
      longitude: lng,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const ref = await db.collection('relayPoints').add(doc);
    console.log(`   ✅ ${point.name} (${ref.id}) — ${lat.toFixed(4)}, ${lng.toFixed(4)}`);
  }
  console.log('\n✅ Terminé.');
  process.exit(0);
}

seed().catch((error) => {
  console.error('❌ Erreur:', error);
  process.exit(1);
});
