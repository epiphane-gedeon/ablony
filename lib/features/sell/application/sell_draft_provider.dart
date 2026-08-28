import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../product/domain/entities/product_attribute.dart';

/// Brouillon d'une annonce en cours de création (jamais en mode édition).
///
/// Permet de rouvrir le bottom sheet "Vendre" après l'avoir fermé sans
/// publier — par exemple parce que l'utilisateur a été renvoyé sur
/// `/onboarding` faute d'être connecté — sans perdre la saisie en cours.
class SellDraft {
  final String title;
  final String description;
  final String price;

  /// Images sélectionnées : `XFile` (nouvelles photos) ou `String` (URLs,
  /// non utilisé ici puisqu'un brouillon n'existe qu'en mode création).
  final List<dynamic> images;

  final String? selectedCategory;
  final String? selectedCategoryId;
  final String? selectedParentCategoryId;
  final List<ProductAttribute> categoryAttributes;
  final Map<String, dynamic> attributeValues;

  const SellDraft({
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.selectedCategory,
    required this.selectedCategoryId,
    required this.selectedParentCategoryId,
    required this.categoryAttributes,
    required this.attributeValues,
  });

  /// true si le brouillon ne contient aucune saisie utile — dans ce cas on
  /// ne le garde pas en cache, ça évite de traîner un état vide.
  bool get isEmpty =>
      title.isEmpty &&
      description.isEmpty &&
      price.isEmpty &&
      images.isEmpty &&
      selectedCategoryId == null;
}

/// Garde en mémoire le brouillon de la dernière annonce en cours de
/// création, tant que l'application reste ouverte.
///
/// Volontairement **en mémoire seulement**, pas sur disque : les photos pas
/// encore uploadées sont des `XFile` (chemin temporaire natif ou blob web)
/// qui ne survivent de toute façon pas à un redémarrage complet de l'app —
/// les persister n'apporterait rien de plus que ce cache mémoire pour la
/// durée de la session.
class SellDraftNotifier extends Notifier<SellDraft?> {
  @override
  SellDraft? build() => null;

  /// Sauvegarde l'état courant du formulaire. Un brouillon vide efface le
  /// cache plutôt que d'y stocker un état vide.
  void save(SellDraft draft) {
    state = draft.isEmpty ? null : draft;
  }

  /// Efface le brouillon (publication réussie ou effacement explicite par
  /// l'utilisateur).
  void clear() {
    state = null;
  }
}

final sellDraftProvider = NotifierProvider<SellDraftNotifier, SellDraft?>(
  SellDraftNotifier.new,
);
