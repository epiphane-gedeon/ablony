# Tests des règles Firestore

Les règles décident qui peut écrire quoi — c'est-à-dire, ici, qui peut écrire
de l'argent. Elles méritent des tests, et ces tests tournent contre
l'émulateur Firestore : ce sont les vraies règles qui sont appliquées, pas une
relecture de leur texte.

```bash
cd tools/firestore_rules_test
npm install
npm test
```

Demande Node et un JRE : l'émulateur Firestore est écrit en Java. Le port 8099
est choisi pour ne pas heurter le 8080, que le conteneur `ablony_landing`
occupe déjà sur la machine de développement — c'est aussi le port que
`firebase emulators:start` utilise pour Firestore, à savoir si vous lancez les
deux.

Le script appelle `$(command -v node)` et non `node` : le binaire autonome de
`firebase-tools` embarque son propre Node, en CommonJS, qui refuse un module
ES. Avec le chemin explicite, c'est bien le vôtre qui tourne.

## Ce qui est couvert

**Le solde ne se réécrit pas depuis le client.** C'était un trou réel : le
propriétaire pouvait modifier son propre document `users/{uid}`, et les règles
ne validaient le `wallet` que sur ses *types*, jamais sur ses valeurs. Avec son
propre jeton et l'API REST, n'importe qui se mettait dix millions puis
demandait un retrait. Les Cloud Functions calculaient pourtant les soldes
correctement — la porte était simplement ouverte à côté.

**Et ce qui doit continuer de marcher.** L'activation du porte-monnaie écrit
bien le document depuis le client : c'est ainsi que la personne renseigne son
identité. Elle doit pouvoir le faire, en recopiant ses montants tels qu'ils
sont — y compris une vente déjà en attente reçue avant l'activation, qui ne
doit pas être remise à zéro.

## Une curiosité de l'émulateur

Un refus affiche `evaluation error at L…` au lieu d'un simple `false`. Ce
n'est pas un défaut des règles : en forçant les deux branches de
`allow update` à `false`, plus aucune expression ne peut lever, et le message
reste. Le refus, lui, est correct — une règle qui lève refuse.
