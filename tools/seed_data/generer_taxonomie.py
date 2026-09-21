#!/usr/bin/env python3
"""Génère categories.json, subcategories.json et attributes.json.

L'arborescence est déclarée ici sous forme compacte, puis dépliée aux trois
niveaux qu'attend l'application : catégorie → sous-catégorie → feuille. Écrire
les 200 entrées à la main serait illisible et se désynchroniserait au premier
ajout ; la déclaration ci-dessous tient sur un écran et reste relisible.

Après exécution :   dart run tools/seed_categories.dart
puis                node tools/import_to_firestore.js
"""
import json
import pathlib

ICI = pathlib.Path(__file__).parent

# ── Jeux d'attributs, par nature d'article ──────────────────────────────
HAUT = ["condition", "brand", "size_haut", "color", "material"]
BAS = ["condition", "brand", "size_bas", "color", "material"]
ROBE = ["condition", "brand", "size_haut", "color", "material", "dress_length"]
CHAUSSURE = ["condition", "brand", "size_chaussures", "color", "material"]
SAC = ["condition", "brand", "color", "material", "bag_type"]
BIJOU = ["condition", "brand", "color", "material", "jewelry_type"]
MONTRE = ["condition", "brand", "color", "material", "watch_movement"]
ACCESSOIRE = ["condition", "brand", "color", "material"]
# Le pagne, le bazin ou le boubou sont le plus souvent cousus sur mesure :
# imposer une marque n'aurait aucun sens, la matière en dit bien plus.
TRADITIONNEL = ["condition", "size_haut", "color", "material"]
TISSU = ["condition", "color", "material"]
ENFANT = ["condition", "brand", "size_enfant", "color", "material"]
ENFANT_PIEDS = ["condition", "brand", "size_chaussures_enfant", "color", "material"]
PUERICULTURE = ["condition", "brand", "color"]
JOUET = ["condition", "brand", "color"]
TECH = ["condition", "tech_brand", "color"]
TECH_STOCK = ["condition", "tech_brand", "storage", "color"]
LIVRE = ["condition", "book_language", "book_format"]
LIVRE_SCOLAIRE = ["condition", "book_language", "school_level"]
MEDIA = ["condition", "book_language"]
CHEVEUX = ["condition", "hair_type", "hair_length", "color"]
BEAUTE = ["condition", "brand"]
MAISON = ["condition", "brand", "color", "material"]
SPORT = ["condition", "brand", "color"]

# ── L'arborescence ──────────────────────────────────────────────────────
# (id, nom, [ (id, nom, attributs, [ (id, nom) ... ]) ... ])
ARBRE = [
 ("femme", "Femme", [
   ("hauts_femme", "Hauts", HAUT, [
     ("chemisier_femme", "Chemise & chemisier"), ("tshirt_femme", "T-shirt"),
     ("debardeur_femme", "Débardeur"), ("top_femme", "Top & blouse"),
     ("pull_femme", "Pull & gilet"), ("sweat_femme", "Sweat & hoodie")]),
   # Une robe n'est pas un bas : elle était rangée sous « Bas », ce qui la
   # rendait introuvable et forçait une taille de pantalon.
   ("robes_femme", "Robes", ROBE, [
     ("robe_jour_femme", "Robe de jour"), ("robe_soiree_femme", "Robe de soirée"),
     ("robe_ceremonie_femme", "Robe de cérémonie"),
     ("combinaison_femme", "Combinaison")]),
   ("bas_femme", "Bas", BAS, [
     ("pantalon_femme", "Pantalon"), ("jean_femme", "Jean"),
     ("jupe_femme", "Jupe"), ("short_femme", "Short"),
     ("legging_femme", "Legging")]),
   ("vestes_femme", "Vestes & manteaux", HAUT, [
     ("veste_femme", "Veste"), ("blazer_femme", "Blazer"),
     ("manteau_femme", "Manteau"), ("impermeable_femme", "Imperméable")]),
   ("traditionnel_femme", "Tenues traditionnelles", TRADITIONNEL, [
     ("kaba_femme", "Kaba & complet pagne"), ("bazin_femme", "Bazin"),
     ("boubou_femme", "Boubou"), ("ensemble_wax_femme", "Ensemble wax"),
     ("tissu_pagne_femme", "Pagne & tissu au mètre")]),
   ("chaussures_femme", "Chaussures", CHAUSSURE, [
     ("baskets_femme", "Baskets"), ("sandales_femme", "Sandales"),
     ("talons_femme", "Talons"), ("ballerines_femme", "Ballerines"),
     ("mules_femme", "Mules & claquettes"), ("bottes_femme", "Bottes")]),
   ("sacs_femme", "Sacs", SAC, [
     ("sac_main_femme", "Sac à main"), ("sac_dos_femme", "Sac à dos"),
     ("pochette_femme", "Pochette"), ("sac_voyage_femme", "Sac de voyage")]),
   ("accessoires_femme", "Accessoires", ACCESSOIRE, [
     ("bijoux_femme", "Bijoux", BIJOU), ("montre_femme", "Montre", MONTRE),
     ("ceinture_femme", "Ceinture"), ("foulard_femme", "Foulard & écharpe"),
     ("lunettes_femme", "Lunettes"), ("chapeau_femme", "Chapeau & bonnet")]),
   ("lingerie_femme", "Lingerie & nuit", HAUT, [
     ("soutien_femme", "Soutien-gorge"), ("culotte_femme", "Culotte"),
     ("pyjama_femme", "Pyjama & nuisette")]),
   ("sport_femme", "Sport", SPORT, [
     ("tenue_sport_femme", "Tenue de sport"),
     ("basket_sport_femme", "Chaussures de sport", CHAUSSURE)]),
 ]),

 ("homme", "Homme", [
   ("hauts_homme", "Hauts", HAUT, [
     ("chemise_homme", "Chemise"), ("tshirt_homme", "T-shirt"),
     ("polo_homme", "Polo"), ("pull_homme", "Pull & gilet"),
     ("sweat_homme", "Sweat & hoodie")]),
   ("bas_homme", "Bas", BAS, [
     ("pantalon_homme", "Pantalon"), ("jean_homme", "Jean"),
     ("short_homme", "Short"), ("jogging_homme", "Jogging")]),
   ("vestes_homme", "Vestes & manteaux", HAUT, [
     ("veste_homme", "Veste"), ("blazer_homme", "Blazer & costume"),
     ("manteau_homme", "Manteau")]),
   ("traditionnel_homme", "Tenues traditionnelles", TRADITIONNEL, [
     ("boubou_homme", "Boubou"), ("bazin_homme", "Bazin"),
     ("agbada_homme", "Agbada"), ("chemise_wax_homme", "Chemise wax"),
     ("tissu_pagne_homme", "Pagne & tissu au mètre")]),
   ("chaussures_homme", "Chaussures", CHAUSSURE, [
     ("baskets_homme", "Baskets"), ("sandales_homme", "Sandales & claquettes"),
     ("mocassins_homme", "Mocassins"), ("ville_homme", "Chaussures de ville"),
     ("bottes_homme", "Bottes")]),
   ("accessoires_homme", "Accessoires", ACCESSOIRE, [
     ("montre_homme", "Montre", MONTRE), ("ceinture_homme", "Ceinture"),
     ("casquette_homme", "Casquette & chapeau"),
     ("lunettes_homme", "Lunettes"), ("portefeuille_homme", "Portefeuille"),
     ("sac_homme", "Sac", SAC)]),
   ("sport_homme", "Sport", SPORT, [
     ("tenue_sport_homme", "Tenue de sport"),
     ("maillot_homme", "Maillot de foot"),
     ("basket_sport_homme", "Chaussures de sport", CHAUSSURE)]),
 ]),

 ("enfants", "Enfants", [
   ("bebe", "Bébé (0-2 ans)", ENFANT, [
     ("body_bebe", "Body & pyjama"), ("ensemble_bebe", "Ensemble"),
     ("manteau_bebe", "Manteau & veste"),
     ("chaussons_bebe", "Chaussons", ENFANT_PIEDS)]),
   ("fille", "Fille (2-16 ans)", ENFANT, [
     ("haut_fille", "Hauts"), ("robe_fille", "Robes"),
     ("bas_fille", "Bas"), ("veste_fille", "Vestes & manteaux"),
     ("traditionnel_fille", "Tenue traditionnelle"),
     ("chaussures_fille", "Chaussures", ENFANT_PIEDS)]),
   ("garcon", "Garçon (2-16 ans)", ENFANT, [
     ("haut_garcon", "Hauts"), ("bas_garcon", "Bas"),
     ("veste_garcon", "Vestes & manteaux"),
     ("traditionnel_garcon", "Tenue traditionnelle"),
     ("chaussures_garcon", "Chaussures", ENFANT_PIEDS)]),
   ("ecole", "École", ENFANT, [
     ("uniforme_ecole", "Uniforme scolaire"),
     ("cartable_ecole", "Cartable & sac", PUERICULTURE),
     ("fournitures_ecole", "Fournitures", PUERICULTURE)]),
   ("puericulture", "Puériculture", PUERICULTURE, [
     ("poussette", "Poussette"), ("siege_auto", "Siège auto"),
     ("lit_bebe", "Lit & couffin"), ("porte_bebe", "Porte-bébé"),
     ("repas_bebe", "Repas & biberons"),
     ("baignoire_bebe", "Bain & toilette")]),
   ("jouets", "Jouets", JOUET, [
     ("eveil_jouet", "Jeux d'éveil"), ("poupee_jouet", "Poupées & peluches"),
     ("voiture_jouet", "Voitures & circuits"),
     ("societe_jouet", "Jeux de société"),
     ("construction_jouet", "Jeux de construction"),
     ("exterieur_jouet", "Jeux d'extérieur")]),
 ]),

 ("electronique", "Électronique", [
   ("telephonie", "Téléphones & tablettes", TECH_STOCK, [
     ("smartphone", "Smartphone"), ("telephone_simple", "Téléphone simple"),
     ("tablette", "Tablette"),
     ("accessoire_telephone", "Coques & protections", TECH)]),
   ("informatique", "Informatique", TECH_STOCK, [
     ("ordinateur_portable", "Ordinateur portable"),
     ("ordinateur_bureau", "Ordinateur de bureau"),
     ("imprimante", "Imprimante", TECH),
     ("peripherique", "Clavier, souris & écran", TECH),
     ("stockage", "Clé USB & disque dur")]),
   ("audio", "Audio", TECH, [
     ("ecouteurs", "Écouteurs"), ("casque_audio", "Casque"),
     ("enceinte", "Enceinte & baffle"), ("radio", "Radio"),
     ("sono", "Sono & micro")]),
   ("image", "TV, photo & vidéo", TECH, [
     ("televiseur", "Téléviseur"), ("decodeur", "Décodeur & antenne"),
     ("videoprojecteur", "Vidéoprojecteur"),
     ("appareil_photo", "Appareil photo"), ("camera", "Caméra")]),
   ("jeux_video", "Jeux vidéo", TECH, [
     ("console", "Console"), ("jeu_video", "Jeu"),
     ("manette", "Manette & accessoires")]),
   ("energie", "Énergie & charge", TECH, [
     ("chargeur", "Chargeur & câble"),
     ("batterie_externe", "Batterie externe"),
     ("panneau_solaire", "Panneau solaire"),
     ("lampe_solaire", "Lampe solaire"),
     ("onduleur", "Onduleur & stabilisateur"),
     ("groupe_electrogene", "Groupe électrogène")]),
 ]),

 ("livres", "Livres & médias", [
   ("livres_scolaires", "Livres scolaires", LIVRE_SCOLAIRE, [
     ("manuel_scolaire", "Manuel scolaire"),
     ("cahier_exercices", "Cahier d'exercices"),
     ("annales", "Annales & préparation examens"),
     ("dictionnaire", "Dictionnaire", LIVRE)]),
   ("litterature", "Littérature", LIVRE, [
     ("roman", "Roman"), ("litterature_africaine", "Littérature africaine"),
     ("poesie_theatre", "Poésie & théâtre"), ("essai", "Essai")]),
   ("pratique", "Pratique & savoir", LIVRE, [
     ("developpement_personnel", "Développement personnel"),
     ("cuisine_livre", "Cuisine"), ("sante_livre", "Santé & bien-être"),
     ("informatique_livre", "Informatique & langues"),
     ("business_livre", "Business & entrepreneuriat")]),
   ("religion", "Religion & spiritualité", LIVRE, [
     ("bible", "Bible & étude biblique"), ("coran", "Coran & islam"),
     ("spiritualite", "Spiritualité")]),
   ("bd_jeunesse", "BD & jeunesse", LIVRE, [
     ("bd", "Bande dessinée"), ("manga", "Manga"),
     ("livre_enfant", "Livre pour enfants")]),
   ("medias", "Musique & films", MEDIA, [
     ("cd", "CD"), ("dvd", "DVD & films"),
     ("magazine", "Revues & magazines")]),
 ]),

 ("maison", "Maison", [
   ("cuisine", "Cuisine", MAISON, [
     ("ustensile", "Ustensiles & vaisselle"),
     ("marmite", "Marmites & casseroles"),
     ("petit_electromenager", "Petit électroménager", TECH),
     ("rangement_cuisine", "Rangement")]),
   ("electromenager", "Électroménager", TECH, [
     ("refrigerateur", "Réfrigérateur & congélateur"),
     ("machine_laver", "Machine à laver"),
     ("ventilateur", "Ventilateur & climatiseur"),
     ("fer_repasser", "Fer à repasser"),
     ("micro_onde", "Micro-ondes & four")]),
   ("linge_maison", "Linge de maison", MAISON, [
     ("draps", "Draps & couvertures"), ("serviettes", "Serviettes"),
     ("rideaux", "Rideaux"), ("nappe", "Nappes")]),
   ("decoration", "Décoration", MAISON, [
     ("tableau", "Tableaux & cadres"), ("luminaire", "Luminaires"),
     ("tapis", "Tapis"), ("objet_deco", "Objets déco"),
     ("artisanat", "Artisanat local")]),
   ("meubles", "Meubles", MAISON, [
     ("canape", "Canapé & fauteuil"), ("table", "Table & chaises"),
     ("lit", "Lit & matelas"), ("armoire", "Armoire & rangement"),
     ("bureau_meuble", "Bureau")]),
 ]),

 ("beaute", "Beauté & soins", [
   ("cheveux", "Cheveux", CHEVEUX, [
     ("meches", "Mèches & tissages"), ("perruque", "Perruques"),
     ("soin_cheveux", "Soins capillaires", BEAUTE),
     ("accessoire_cheveux", "Accessoires cheveux", BEAUTE)]),
   ("maquillage", "Maquillage", BEAUTE, [
     ("teint", "Fond de teint & poudre"), ("levres", "Rouge à lèvres"),
     ("yeux", "Yeux & sourcils"), ("ongles", "Ongles & vernis"),
     ("pinceaux", "Pinceaux & accessoires")]),
   ("parfums", "Parfums", BEAUTE, [
     ("parfum_femme", "Parfum femme"), ("parfum_homme", "Parfum homme"),
     ("encens", "Encens & brumes")]),
   ("soins_corps", "Soins", BEAUTE, [
     ("soin_visage", "Visage"), ("soin_corps", "Corps"),
     ("savon", "Savons & gommages"), ("huile", "Huiles & beurres naturels")]),
 ]),

 ("sport_loisirs", "Sport & loisirs", [
   ("equipement_sport", "Équipement", SPORT, [
     ("ballon", "Ballons"), ("musculation", "Musculation & fitness"),
     ("velo", "Vélo & trottinette"), ("raquette", "Raquettes")]),
   ("plein_air", "Plein air", SPORT, [
     ("camping", "Camping"), ("peche", "Pêche"), ("plage", "Plage & piscine")]),
   ("instruments", "Musique", SPORT, [
     ("guitare", "Guitare"), ("clavier_musique", "Clavier & piano"),
     ("percussion", "Djembé & percussions"),
     ("instrument_autre", "Autres instruments")]),
 ]),
]

# ── Attributs ───────────────────────────────────────────────────────────
#
# ⚠️ CES LISTES SONT EN AJOUT SEUL.
#
# Les annonces ne stockent pas la valeur choisie mais son **indice** dans le
# tableau (`condition: 1`, `brand: 5`…). Insérer une valeur au milieu, en
# retirer une ou simplement réordonner décale donc silencieusement le sens de
# toutes les annonces déjà publiées : un « Excellent état » deviendrait
# « Neuf sans étiquette » sans que rien ne le signale.
#
# Règle : on ajoute **à la fin**, jamais ailleurs. L'ordre d'affichage n'est
# pas idéal, mais il est juste — et c'est ce qui compte tant que l'indice fait
# foi. (Le jour où l'on stockera la valeur elle-même plutôt que sa position,
# cette contrainte tombera et les listes pourront être remises en ordre.)
ATTRIBUTS = [
 ("condition", "État", ["Neuf avec étiquette", "Excellent état", "Bon état",
   "Satisfaisant", "Usé",
   # ajouts
   "Neuf sans étiquette", "Pour pièces"], True,
   "État général du produit"),
 ("brand", "Marque", ["Nike", "Adidas", "Zara", "H&M", "Gucci", "Prada",
   "Louis Vuitton", "Dior", "Chanel", "Hermès", "Lacoste", "Tommy Hilfiger",
   "Calvin Klein", "Ralph Lauren", "Versace", "Armani", "Burberry",
   "Balenciaga", "Off-White", "Supreme", "Autre",
   # ajouts
   "Sans marque", "Puma", "Levi's"], False,
   "Choisissez « Sans marque » si l'article n'en porte pas"),
 ("tech_brand", "Marque", ["Samsung", "Tecno", "Infinix", "itel", "Xiaomi",
   "Apple", "Nokia", "Huawei", "Oppo", "Vivo", "Realme", "Google", "OnePlus",
   "HP", "Dell", "Lenovo", "Asus", "Acer", "Toshiba", "LG", "Sony", "Philips",
   "JBL", "Binatone", "Nasco", "Autre"], True, "Marque de l'appareil"),
 ("size_haut", "Taille", ["XS", "S", "M", "L", "XL", "XXL", "XXXL",
   # ajouts
   "Taille unique"], True, None),
 ("size_bas", "Taille", ["28", "30", "32", "34", "36", "38", "40", "42", "44",
   "46",
   # ajouts
   "48", "50"], True, None),
 ("size_chaussures", "Pointure", [str(n) for n in range(35, 48)], True, None),
 ("size_enfant", "Taille", ["Prématuré", "0-3 mois", "3-6 mois", "6-12 mois",
   "12-18 mois", "18-24 mois", "2 ans", "3 ans", "4 ans", "5 ans", "6 ans",
   "7 ans", "8 ans", "10 ans", "12 ans", "14 ans", "16 ans"], True, None),
 ("size_chaussures_enfant", "Pointure", [str(n) for n in range(16, 40)], True,
   None),
 ("color", "Couleur", ["Noir", "Blanc", "Gris", "Beige", "Marron", "Bleu",
   "Bleu marine", "Bleu clair", "Rouge", "Rose", "Violet", "Vert",
   "Vert kaki", "Jaune", "Orange", "Multicolore", "Doré", "Argenté",
   # ajouts
   "Bordeaux", "Imprimé wax"], True, None),
 ("material", "Matière", ["Coton", "Polyester", "Laine", "Soie", "Lin", "Jean",
   "Cuir", "Daim", "Synthétique", "Velours", "Cachemire", "Viscose", "Autre",
   # ajouts
   "Wax", "Bazin", "Pagne tissé", "Bois", "Métal", "Plastique", "Verre",
   "Céramique", "Papier"], False, None),
 ("dress_length", "Longueur", ["Court", "Mi-long", "Long"], False, None),
 ("bag_type", "Type de sac", ["Sac à main", "Sac à dos", "Pochette",
   "Tote bag", "Sac bandoulière", "Sac de voyage", "Sacoche"], False, None),
 ("jewelry_type", "Type de bijou", ["Collier", "Bracelet",
   "Boucles d'oreilles", "Bague", "Broche", "Montre bracelet",
   # ajouts
   "Parure"], False, None),
 ("watch_movement", "Mouvement", ["Quartz", "Automatique", "Manuel",
   "Numérique",
   # ajouts
   "Connectée"], False, None),
 ("storage", "Stockage", ["8 Go", "16 Go", "32 Go", "64 Go", "128 Go",
   "256 Go", "512 Go", "1 To", "2 To"], False, "Capacité de stockage"),
 ("book_language", "Langue", ["Français", "Anglais", "Bilingue", "Autre"],
   True, None),
 ("book_format", "Format", ["Broché", "Relié", "Poche", "Grand format"],
   False, None),
 ("school_level", "Niveau", ["Maternelle", "Primaire", "Collège", "Lycée",
   "Université", "Concours & examens"], True, "Niveau scolaire visé"),
 ("hair_type", "Type", ["Naturel (human hair)", "Synthétique", "Brésilien",
   "Péruvien", "Indien", "Autre"], True, None),
 ("hair_length", "Longueur", ["Court (8-12 pouces)", "Moyen (14-18 pouces)",
   "Long (20-24 pouces)", "Très long (26 pouces et +)"], False, None),
]


def generer():
    categories, souscats = [], []

    for ordre_cat, (cid, cnom, niveau1) in enumerate(ARBRE, 1):
        categories.append({
            "id": cid, "name": cnom,
            "children": [s[0] for s in niveau1],
            "order": ordre_cat, "iconUrl": None, "isActive": True,
        })

        for ordre_n1, (sid, snom, attrs_defaut, feuilles) in enumerate(niveau1, 1):
            souscats.append({
                "id": sid, "name": snom, "parentId": cid,
                "children": [f[0] for f in feuilles],
                "attributes": [], "order": ordre_n1,
                "iconUrl": None, "isActive": True,
            })
            for ordre_f, feuille in enumerate(feuilles, 1):
                fid, fnom = feuille[0], feuille[1]
                attrs = feuille[2] if len(feuille) > 2 else attrs_defaut
                souscats.append({
                    "id": fid, "name": fnom, "parentId": sid,
                    "children": [], "attributes": list(attrs),
                    "order": ordre_f, "iconUrl": None, "isActive": True,
                })

    attributs = []
    for ordre, (aid, anom, valeurs, requis, aide) in enumerate(ATTRIBUTS, 1):
        attributs.append({
            "id": aid, "name": anom, "type": "select", "values": valeurs,
            "isRequired": requis, "helpText": aide,
            "order": ordre, "isActive": True,
        })

    # Garde-fou sur les indices : les valeurs déjà publiées doivent rester à
    # la même position. On compare au fichier en place avant de l'écraser.
    ancien = ICI / "attributes.json"
    if ancien.exists():
        avant = {a["id"]: a["values"] for a in json.loads(ancien.read_text())}
        for a in attributs:
            vieux = avant.get(a["id"])
            if not vieux:
                continue
            neuf = a["values"]
            assert neuf[:len(vieux)] == vieux, (
                f"\n⛔ L'attribut « {a['id']} » n'est plus en ajout seul.\n"
                f"   avant : {vieux}\n   après : {neuf[:len(vieux)]}\n"
                "   Les annonces stockent l'indice de la valeur : déplacer ou\n"
                "   retirer une entrée change le sens des annonces publiées.\n"
                "   N'ajoutez qu'à la fin de la liste."
            )

    # Cohérence : tout attribut cité doit exister, tout enfant doit exister.
    connus = {a["id"] for a in attributs}
    ids = {s["id"] for s in souscats}
    for s in souscats:
        for a in s["attributes"]:
            assert a in connus, f"{s['id']} cite un attribut inconnu : {a}"
        for e in s["children"]:
            assert e in ids, f"{s['id']} cite un enfant inconnu : {e}"
    for c in categories:
        for e in c["children"]:
            assert e in ids, f"{c['id']} cite un enfant inconnu : {e}"
    assert len(ids) == len(souscats), "identifiants de sous-catégorie en double"

    for nom, donnees in (("categories", categories),
                         ("subcategories", souscats),
                         ("attributes", attributs)):
        (ICI / f"{nom}.json").write_text(
            json.dumps(donnees, ensure_ascii=False, indent=2) + "\n")

    feuilles = [s for s in souscats if not s["children"]]
    print(f"{len(categories)} catégories, "
          f"{len(souscats) - len(feuilles)} sous-catégories, "
          f"{len(feuilles)} feuilles, {len(attributs)} attributs")
    return categories, souscats, attributs


if __name__ == "__main__":
    generer()
