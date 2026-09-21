# Ablony face à Vinted

*Comparaison au 15 septembre 2026. Les fonctionnalités Vinted citées sont
vérifiées sur leur centre d'aide et la documentation publique — sources en fin
de document.*

---

## Ce que la comparaison doit servir, et ce qu'elle ne doit pas

Vinted compte plus de 75 millions de membres et opère dans une vingtaine de
pays européens plus les États-Unis. Copier sa liste de fonctionnalités serait
une erreur de méthode : la moitié répond à des contraintes qui ne sont pas les
vôtres — réseaux de transporteurs européens, comptes professionnels, TVA
intracommunautaire.

Ce tableau sert à **repérer ce qui manque et qui compte au Togo et au Bénin**.
La colonne « pour Ablony » est un jugement, pas un relevé.

---

## Acheter

| Fonctionnalité Vinted | Ablony | Pour Ablony |
|---|---|---|
| Parcourir un catalogue à catégories profondes | ✅ fait | — |
| Filtres (taille, marque, état, couleur, prix) | ✅ fait | — |
| Recherche texte | ⚠️ cassée à l'échelle | **Critique** — voir [C1](03-corrections.md#c1) |
| Recherches sauvegardées + pastille « nouveautés » | ❌ absent | **Élevé** — c'est ce qui fait revenir |
| Favoris | ✅ fait | — |
| Suivre un vendeur | ✅ fait | — |
| Suivre une marque | ❌ absent | Faible — la marque n'est qu'un attribut |
| **Lots** : plusieurs articles d'un vendeur, un seul envoi | ❌ absent | **Élevé** — voir plus bas |
| Remise sur lot automatique | ❌ absent (entrée morte) | Moyen |
| Négocier : offre, contre-offre | ✅ fait | — |
| Recevoir une offre privée du vendeur | ❌ absent | Moyen |
| Protection acheteur (frais + garantie) | ✅ séquestre | Modèle différent, voir plus bas |
| Signaler un problème à la réception | ❌ absent côté app | **Critique** |
| Suivi de commande | ✅ fait | — |
| Historique des achats | ❌ entrée morte | **Élevé** |
| Noter le vendeur | ✅ fait | — |
| Être noté en tant qu'acheteur | ❌ absent | Moyen |

## Vendre

| Fonctionnalité Vinted | Ablony | Pour Ablony |
|---|---|---|
| Publier (photos, catégorie, marque, taille, état) | ✅ fait | — |
| Jusqu'à 20 photos + vidéo | ⚠️ 6 photos, pas de vidéo | Moyen |
| Brouillon | ✅ fait | — |
| Modifier, masquer, supprimer | ✅ fait | — |
| Mise en avant payante | ✅ fait (boost) | — |
| Mise en avant de la boutique entière | ❌ absent | Faible |
| Remise sur lot paramétrable | ❌ absent | Moyen |
| Envoyer une offre privée aux intéressés | ❌ absent | Moyen |
| Mode vacances | ❌ entrée morte | Moyen |
| Étiquette d'expédition | ✅ fait | — |
| Historique des ventes | ❌ entrée morte | **Élevé** |
| Statistiques de boutique | ❌ absent | Faible |
| Compte professionnel | ❌ absent | Hors sujet pour l'instant |

## Argent

| Fonctionnalité Vinted | Ablony | Pour Ablony |
|---|---|---|
| Porte-monnaie et solde | ✅ fait | — |
| Relevé des mouvements | ✅ fait | — |
| Rechargement | ✅ fait | — |
| Retrait vers un compte | ⚠️ « bientôt » | **Critique** — bloqué par une clé d'API |
| Paiement carte | ✅ fait | — |
| Paiement mobile money | ✅ T-Money, Flooz | **Avantage Ablony** |
| Remboursement d'un achat | ⚠️ serveur uniquement | **Critique** |

## Communauté et sécurité

| Fonctionnalité Vinted | Ablony | Pour Ablony |
|---|---|---|
| Messagerie | ✅ fait | — |
| Notifications push | ✅ fait | — |
| **Boîte de notifications dans l'app** | ❌ absent | **Élevé** |
| Signaler une annonce | ⚠️ création seule côté Firebase | **Élevé** |
| Signaler un membre | ❌ absent | Moyen |
| **Bloquer un membre** | ❌ absent | **Élevé** — question de sécurité |
| Centre d'aide | ❌ entrée morte | Moyen |
| Parrainage | ❌ entrée morte | Faible |
| Pages légales | ⚠️ en cours (WebView) | Moyen — obligation légale |

---

## Trois écarts qui méritent d'être discutés, pas seulement listés

### Le lot est plus important chez vous que chez Vinted

Chez Vinted, le lot fait gagner quelques euros de port. Chez vous, la
livraison est un coût réel que vous portez : 1 000 à 1 500 FCFA par colis,
payés à des livreurs que vous employez. Deux articles du même vendeur vers le
même acheteur dans deux colis séparés, c'est **votre marge** qui part deux
fois.

Le lot n'est donc pas un confort d'acheteur : c'est une économie d'opérateur.
C'est l'argument qui devrait le faire remonter dans vos priorités, pas la
comparaison avec Vinted.

### Votre protection acheteur est plus forte, et vous ne le dites nulle part

Vinted prélève des frais de protection (~5 % + fixe) et rembourse si l'article
n'arrive pas ou ne correspond pas. Le transporteur est un tiers, et la preuve
de remise vient de lui.

Chez vous, **c'est Ablony qui achemine**. Vos agents scannent le colis à
chaque étape. La remise n'est pas déclarée par une partie ni attestée par un
prestataire externe : elle est constatée par vous. C'est objectivement plus
solide — et l'application n'en dit pas un mot. Aucun écran n'explique à
l'acheteur pourquoi son argent est en sécurité.

C'est un travail de contenu, pas de code, et il vaut probablement plus que
trois fonctionnalités.

### La recherche sauvegardée est ce qui fait revenir

Sur une place de marché de seconde main, personne ne trouve ce qu'il cherche
du premier coup : le stock est unique et change tous les jours. La recherche
sauvegardée transforme « je n'ai rien trouvé » en « je serai prévenu ». C'est
le mécanisme de rétention le plus rentable de Vinted, et il ne coûte qu'une
requête stockée et une comparaison à la publication.

Vous avez déjà tout ce qu'il faut : le nouveau backend publie
`product.created_for_followers`. Le même mécanisme sert les recherches
sauvegardées.

---

## Ce que Vinted a et qu'il ne faut *pas* copier maintenant

Nommer ce qu'on écarte vaut autant que nommer ce qu'on prend.

- **Comptes professionnels** — suppose une réglementation, une facturation et
  une TVA que vous n'avez pas à traiter aujourd'hui.
- **Mise en avant de la boutique entière** — utile à partir de vingt annonces
  actives ; vos vendeurs n'y sont pas.
- **Suivre une marque** — la marque est un attribut de catégorie chez vous,
  pas une entité. En faire une entité est un chantier de données pour un gain
  faible au démarrage.
- **Dons à une association** — dépend de partenariats qui n'existent pas.
- **Multi-devise et multi-pays** — le XOF couvre le Togo et le Bénin. C'est
  précisément l'avantage de votre périmètre.

---

## Sources

- [How Does Vinted Work? A Comprehensive Guide for 2026 — CLOSO](https://closo.co/blogs/platform-specific-guides/how-does-vinted-work-2)
- [Vinted 2026: Sell & Resell Fashion — CLOSO](https://closo.co/blogs/beginner-guides-how-tos/what-is-vinted-your-ultimate-guide-to-vinted-selling-reselling-in-2026)
- [Vinted Fees Explained — plottdata](https://plottdata.com/blogs/vinted-fees-explained)
- [Vinted Bundle Discount — Vinta.App](https://blog.vinta.app/blog/vinted-bundle-discount-how-to-offer-deals-buyers)
- [How to Negotiate on Vinted — Nibble](https://blog.nibbletechnology.com/how-to-negotiate-on-vinted/)
- [Vinted alerts guide — InstantAlert](https://instantalert.me/en/blog/vinted-alerts-guide)
