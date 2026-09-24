# Transporteurs / livraison — Lomé (démarrage)

> Recherche pour choisir un ou plusieurs prestataires de livraison à **Lomé**
> pour le lancement d'Ablony (une seule ville pour commencer).
> Objectif : tarifs raisonnables, compatible avec notre modèle **points relais +
> grille de prix fixe**, et si possible **Mobile Money**.
>
> _MàJ après vérification : plusieurs acteurs listés au départ (Launship Box,
> Mivadoo, Lomé Relay, Dɔm La) n'ont **aucune trace d'activité après ~2022** →
> considérés **inactifs**. La Poste et Gozem **ne conviennent pas** (retenu par
> le fondateur). La section ci-dessous ne garde que les acteurs **actifs vérifiés**._

---

## Rappel de notre modèle

- Le vendeur dépose le colis en **point relais** ; Ablony achemine ; l'acheteur
  retire au relais **ou** se fait livrer à domicile (payant).
- Prix de livraison **fixe**, posé **par sous-catégorie** (nos sous-catégories
  sont corrélées à la taille → proxy du coût transporteur, façon Vinted).
- Objectif : **frais Ablony (par sous-catégorie) = tarif transporteur de la
  tranche + marge**.

---

## 💡 Point stratégique

Nous avons **déjà** construit l'outillage d'un **réseau de points relais**
(admin : ajouter/modifier/désactiver/supprimer des relais). Donc nous n'avons
**pas besoin qu'un prestataire nous apporte des relais** :

> **Ablony peut ÊTRE son propre réseau de relais** — on recrute des boutiques
> comme points relais (via l'admin) — et on utilise un coursier seulement pour
> le **transport** (relais→relais, relais→domicile).

Cela simplifie la recherche : il suffit d'un **coursier fiable + suivi**, pas
d'un réseau de relais clé en main.

---

## Prestataires ACTIFS (vérifiés)

### 🥇 ChapChap — `chapchap.tg`
- **Actif**, basé à Lomé. Livraison de **plis et colis géolocalisés**, à la
  demande, **pour les professionnels**, avec **suivi temps réel**.
- **Orienté entreprises** : interface de gestion des envois, planification,
  suivi, et **API documentée** → **intégration possible pour une marketplace**.
- **Porte-à-porte** (pas de points relais publics) → complète bien notre propre
  réseau de relais.
- Grille tarifaire **non publique** → à demander.
- **Contacts** : ☎ **+228 90 31 97 18** · ✉️ **contact@chapchap.tg** ·
  WhatsApp (`wa.me/message/JYEPAGJKQUBZD1`) · formulaire `chapchap.tg/contact`.
- **Adresse** : 56M3+485 ChapChap Togo — GLC Services, Lomé.

### 🟡 Kaba Delivery
- Active (2025). À l'origine **food** (200+ restaurants), s'est étendue au
  **Bénin** avec de l'**expédition de colis transfrontalier Togo↔Bénin**.
- Intéressant vu notre cible **Togo + Bénin**. À sonder pour le colis (pas que
  le repas).

### 🔧 KeyOps Tech — solution KOTscan (⚠️ pas un transporteur)
- **Techno de suivi**, pas un livreur : position **+ identité du livreur** en
  temps réel, greffée sur des transporteurs partenaires. A scalé avec La Poste
  Mali (500 → 30 000 livraisons).
- Pertinent non comme coursier mais comme **couche de tracking / preuve de
  remise par un tiers** — ce qui correspond exactement au « scan par un agent
  tiers de confiance » de notre modèle de livraison.
- CEO : Olivier Mercuriot. Pas de grille/contact direct trouvés.

### En analyse / à vérifier
- **Colis Express Togo** (S.T.L.D) — présence surtout Facebook, infos 2025 peu
  disponibles ; en cours d'analyse par le fondateur.
- **Anaxar** — transport de marchandises / déménagement / livraison (Lomé +
  Burkina/Mali/Niger). Plutôt fret.
- **« Votre coursier »** (app Google Play `com.votrecoursiertg`) — coursier à la
  demande, à évaluer.

---

## Recommandation

1. **Transport → ChapChap** : actif, Lomé, suivi temps réel, **API** pour
   intégration marketplace. Les contacter pour la grille + les conditions + la
   doc API.
2. **Relais → Ablony lui-même** : recruter des boutiques comme points relais
   (l'outil admin existe déjà). Commencer avec **1–2 relais** à Lomé.
3. **Bénin (plus tard) → Kaba Delivery** pour le transfrontalier.
4. **Tracking/preuve de remise (option) → KeyOps/KOTscan** si on veut une couche
   de scan par tiers prête à l'emploi.

---

## À faire / questions ouvertes

- [ ] Contacter **ChapChap** : grille tarifaire, **doc API**, conditions
      marketplace (enlèvement, remise, responsabilité perte/casse, délais),
      moyens de paiement/reversement (Mobile Money ?).
- [ ] Décider : Ablony recrute ses **propres relais** (boutiques) → combien au
      lancement, quelle rémunération du relais.
- [ ] Sonder **Kaba** pour le colis (et le transfrontalier Bénin).
- [ ] Finir l'analyse de **Colis Express Togo**.
- [ ] Une fois la grille transporteur connue → la mapper sur nos
      **sous-catégories** (`deliveryRelayXof` / `deliveryHomeXof` en admin).

---

## Modèle de message de prise de contact

> Version pour **ChapChap** (coursier + API, porte-à-porte). Adaptable aux
> autres.

**Objet : Partenariat livraison + API — Ablony (marketplace) × ChapChap**

Bonjour,

Je vous contacte au sujet d'un partenariat de livraison à Lomé.

Nous lançons **Ablony**, une application de vente entre particuliers d'articles
de seconde main (type Vinted) au Togo (puis Bénin). Nous gérons nous-mêmes un
**réseau de points relais** ; nous cherchons un partenaire **coursier fiable
avec suivi** pour acheminer les colis (relais → relais, et relais → domicile).

Votre service géolocalisé avec suivi temps réel, et surtout votre **API pour les
entreprises**, correspondent à ce que nous cherchons pour **automatiser** la
création des courses depuis notre plateforme.

Nous démarrons sur **Lomé uniquement**, avec des volumes modestes au lancement
puis une montée en charge progressive.

Pourriez-vous nous communiquer :

1. Votre **grille tarifaire** (par taille/poids et par zone), pour du
   relais→relais et du relais→domicile ;
2. Votre **documentation API** et les modalités d'intégration (création de
   course, suivi, webhooks de statut) ;
3. Vos **conditions** (enlèvement/remise, responsabilité en cas de perte ou
   casse, délais) ;
4. Vos **modalités de paiement / reversement** (Mobile Money, facturation).

Je reste disponible pour un échange (appel, WhatsApp ou rendez-vous).

Bien cordialement,
**[Nom]** — Ablony
📞 [téléphone] · ✉️ [email]

---

## Sources

- ChapChap : https://chapchap.tg/
- Togo First — Chap Chap démarre ses activités : https://www.togofirst.com/fr/tic/0104-7591-chap-chap-un-nouveau-service-de-livraison-demarre-ses-activites-au-togo
- Togo First — KeyOps Tech (tracking digitalisé) : https://www.togofirst.com/fr/logistique/2501-7145-keyops-tech-va-lancer-ses-activites-de-tracking-digitalise-de-colis-au-togo
- Techs.tg — Kaba Delivery s'exporte au Bénin : https://techs.tg/2025/03/19/kaba-delivery-la-startup-togolaise-sexporte-au-benin/
- Colis Express Togo (Facebook) : https://www.facebook.com/colisexpresstogo/
