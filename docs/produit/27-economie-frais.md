# 27 — Économie des frais (nyole, protection, recharge, retrait)

Décidé le 2026-10-02, sur des chiffres **mesurés**, pas estimés.

## Ce que prélève nyole — mesuré

Trois paiements réels en Mobile Money (PayDunya) :

| Payé | Disponible au reversement | Prélevé |
|---:|---:|---:|
| 200 F | 190 F | 5,0 % |
| 500 F | 475 F | 5,0 % |
| **900 F** | **855 F** | **5,0 %** |

**5 % exactement, sans part fixe, sans frais de passerelle en plus.**

L'absence de part fixe est le point décisif face à GeniusPay, dont la grille
(100 F + 11 % chez PaiementPro) écrase les petits montants :

| Sur 500 F | Coût | Taux |
|---|---:|---:|
| GeniusPay | 155 F | **31 %** |
| nyole | 25 F | **5 %** |

Sur une place de marché d'occasion où la majorité des articles sont petits,
l'écart n'est pas discutable.

**Non mesuré : la carte.** Elle passe par Stripe, pas PayDunya. À vérifier
avant de compter sur du volume carte.

## Protection acheteur : 6 %

Le prélèvement s'applique à **tout ce qui transite** — prix, protection, et
livraison. D'où un piège : le taux plancher n'est pas 5 % mais **5,27 %**
(0,05 ÷ 0,95), puisque nyole prélève aussi sur la protection elle-même. Fixer
6 % en croyant gagner 1 point, c'est en gagner 0,7.

Avec la livraison facturée de sorte que le livreur touche le net dû (voir
ci-dessous), la marge est :

```
marge = prix × (0,95 × taux − 0,05)
```

À 6 % → **0,007 × prix**, soit 0,7 %, positif à tous les montants.

### La livraison devait être neutralisée

Sans correction, la livraison transitant par le même tuyau se faisait prélever
5 % que personne ne couvrait :

```
marge = 0,007 × prix − 0,05 × livraison
```

→ rentable seulement au-dessus de **7,14 × la livraison** (7 150 F en relais,
14 300 F à domicile). En dessous, chaque vente perdait de l'argent — c'est-à-dire
sur la majorité du catalogue.

Deux correctifs possibles : une part fixe sur la protection (écartée, trop
lourde sur les petits montants — 150 F sur un article à 500 F, c'est 30 %), ou
**majorer la livraison facturée** pour que le livreur touche le montant dû
après prélèvement. C'est la seconde qui est retenue.

## Recharge : gratuite

L'utilisateur paie 2 000, il reçoit 2 000.

Contre-intuitif mais vérifié : **la recharge gratuite ne coûte rien de plus que
le paiement direct.** C'est le même argent qui traverse nyole une seule fois.

- Paiement direct : marge **0,7 %**
- Recharge gratuite puis achat au solde : marge **0,66 %**

Ce qu'on y gagne sans rien sacrifier : un message limpide (« je paie 2 000,
j'ai 2 000 » — là où « j'ai 1 900 » ressemble à du vol sur un marché où la
confiance est l'obstacle principal), un solde **captif**, et un paiement
instantané aux achats suivants.

## Retrait : 5 %

L'ancienne grille (100 F + 1 %) était **sous le coût réel** : 200 F facturés
sur un retrait de 10 000, contre 245 F pour sortir l'argent de nyole (2,5 % au
Togo). Chaque versement perdait de l'argent.

À 5 %, le retrait couvre son coût et dégage ~2,6 % — **c'est lui qui porte
l'essentiel du modèle**, la protection ne laissant que 0,7 %.

| Retiré | Frais | Net |
|---:|---:|---:|
| 2 000 F | 100 F (5,0 %) | 1 900 F |
| 10 000 F | 500 F (5,0 %) | 9 500 F |
| 50 000 F | 2 500 F (5,0 %) | 47 500 F |
| 500 000 F | 25 000 F (5,0 %) | 475 000 F |

**Pas de plafond.** Un plafond à 5 000 F avait été posé, puis retiré : le coût
de sortie étant lui-même proportionnel (2,5 %), plafonner les frais ouvrait une
zone de perte au-delà de 200 000 F — 12 500 F de coût pour 5 000 F facturés sur
un retrait de 500 000.

**La réserve à garder en tête :** à 5 %, on est plus près d'une commission que
de frais de transfert, et c'est ressenti au moment le plus sensible — quand le
vendeur touche son argent. D'où l'affichage du net **avant** validation. Si les
vendeurs regimbent, c'est le premier taux à revoir.

## La boucle recharge → retrait

`requestWithdrawal` ne distingue pas l'argent rechargé de l'argent gagné : même
pot. Recharge gratuite + retrait possible = on peut faire entrer puis ressortir
de l'argent, en laissant à Ablony les 5 % de l'entrée.

Ce n'est **pas exploitable pour un gain** : qui fait l'aller-retour perd 5 % au
retrait, donc personne ne s'en sert comme service de transfert. Et les 5 %
récupérés à la sortie compensent ceux absorbés à l'entrée.

**La forme propre reste à faire** : séparer le solde en deux — l'argent rechargé
(dépensable seulement) et l'argent gagné par des ventes (retirable). Ça
supprime la boucle à la racine au lieu de la compenser, et évite de ressembler
à un service de transfert d'argent, qui est une activité réglementée.
**À faire après le lancement.**

## Transition du taux de protection (5 % → 6 %)

Les clients déjà installés portent 5 % en dur. Exiger 6 % côté serveur ferait
échouer **tous** leurs achats avec « montant incohérent ». Le serveur accepte
donc les deux totaux, et facture celui qui a été affiché — faire payer 6 % à
qui en a vu 5 % serait pire que l'écart de marge.

À retirer (`PROTECTION_RATE_LEGACY`) quand le parc installé aura basculé.

## Marge totale par vente

| Poste | Marge |
|---|---:|
| Protection acheteur (6 %) | 0,7 % du prix |
| Retrait vendeur (5 %) | ~2,6 % du prix |
| **Total** | **~3,3 %** |

## Reste à faire

- Mesurer le taux réel **sur la carte** (Stripe), non vérifié.
- Séparer solde rechargé / solde gagné.
- Confirmer le coût réel de sortie de nyole sur un reversement effectif
  (2,5 % annoncé pour le Togo, jamais mesuré).


## Comptabilité — séparer l'argent d'Ablony de celui des membres

Ajouté le 2026-10-09. Onglet « Comptabilité » dans l'admin.

Tout transite par un compte nyole unique, qui mélange l'argent d'Ablony et
celui des membres. Le risque n'est pas de mal estimer un chiffre d'affaires :
**c'est de retirer l'argent de quelqu'un d'autre.**

D'où le sens du calcul : on part de ce qu'on **doit**, et le retirable est ce
qui dépasse. Une erreur fait alors retirer trop peu plutôt que trop.

**Passif** (jamais retirable) = porte-monnaie des membres + séquestre vendeurs
+ retraits demandés non versés. Lu dans les porte-monnaie eux-mêmes, qui font
foi — aucun journal parallèle, donc aucune dérive.

**Revenus** = protection acheteur + frais de retrait + boosts. La livraison et
les ramassages sont présentés à part : encaissés pour le compte de qui livre,
ce ne sont pas des gains.

**Retirable** = solde nyole (saisi à la main, leur API ne l'expose pas) −
passif.

### La ventilation est figée à la transaction, jamais reconstituée

`partAblony()` écrit la ventilation sur la transaction au moment où la vente se
dénoue. Deux raisons.

**La justesse.** `amount` ne veut pas dire la même chose selon le cas : sur un
achat **mixte** il ne porte que la part mobile money, le reste étant dans
`walletDeduction` ; sur un **boost** il porte le prix entier. Un calcul fait
après coup sur `amount` perdait **la totalité de la commission** d'un achat
mixte — vérifié : 0 F au lieu de 600 F sur une vente à 10 000 F.

**Le principe.** Les taux changent (protection passée de 5 % à 6 %). Une
comptabilité qui se recalcule au taux du jour réécrit le passé.

Les ventes antérieures à cette ventilation sont comptées à part
(`ventesSansVentilation`), pour qu'un écart reste visible plutôt que fondu dans
le total.
