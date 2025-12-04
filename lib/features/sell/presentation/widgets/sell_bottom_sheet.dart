import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../shared/widgets/selection_tile.dart';
import '../widgets/image_picker_grid.dart';

/// Bottom sheet plein écran pour créer une annonce.
///
/// Permet à l'utilisateur de :
/// - Ajouter 1-6 photos
/// - Saisir titre et description
/// - Sélectionner catégorie, état, prix
/// - Remplir les attributs dynamiques selon la catégorie
class SellBottomSheet extends StatefulWidget {
  const SellBottomSheet({super.key});

  /// Affiche le bottom sheet en plein écran
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SellBottomSheet(),
    );
  }

  @override
  State<SellBottomSheet> createState() => _SellBottomSheetState();
}

class _SellBottomSheetState extends State<SellBottomSheet> {
  // Form state
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  List<File> _selectedImages = [];
  String? _selectedCategory;
  String? _selectedCondition;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight, // Plein écran
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // AppBar
          _buildAppBar(context, theme, l10n),

          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grille de photos
                  ImagePickerGrid(
                    images: _selectedImages,
                    onImagesChanged: (newImages) {
                      setState(() => _selectedImages = newImages);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 8,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),

                  const SizedBox(height: 16),

                  // Titre
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.productTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: l10n.productTitleHint,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.productDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: l10n.productDescriptionHint,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Divider
                  Divider(
                    height: 1,
                    thickness: 8,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),

                  // Catégorie
                  SelectionTile(
                    label: l10n.category,
                    value: _selectedCategory,
                    placeholder: l10n.selectCategory,
                    onTap: () {
                      // TODO: Navigate to category selection
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sélection de catégorie - À implémenter'),
                        ),
                      );
                    },
                    isRequired: true,
                  ),

                  // État
                  SelectionTile(
                    label: l10n.condition,
                    value: _selectedCondition,
                    onTap: () => _showConditionPicker(context, theme, l10n),
                    isRequired: true,
                  ),

                  // Prix
                  SelectionTile(
                    label: l10n.price,
                    value: _priceController.text.isEmpty
                        ? null
                        : '${_priceController.text} FCFA',
                    placeholder: l10n.priceHint,
                    onTap: () => _showPricePicker(context, theme, l10n),
                    isRequired: true,
                  ),

                  const SizedBox(height: 32),

                  // TODO: Attributs dynamiques selon catégorie

                  const SizedBox(height: 80), // Espace pour le bouton
                ],
              ),
            ),
          ),

          // Bouton Publier (fixe en bas)
          _buildPublishButton(context, theme, l10n),
        ],
      ),
    );
  }

  /// Construit l'AppBar
  Widget _buildAppBar(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              l10n.sellTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Pour centrer le titre
        ],
      ),
    );
  }

  /// Construit le bouton Publier
  Widget _buildPublishButton(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canPublish() ? _handlePublish : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.publish,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Affiche le sélecteur d'état
  void _showConditionPicker(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConditionOption(context, l10n.conditionNew, theme),
            _buildConditionOption(context, l10n.conditionExcellent, theme),
            _buildConditionOption(context, l10n.conditionGood, theme),
            _buildConditionOption(context, l10n.conditionFair, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionOption(BuildContext context, String condition, ThemeData theme) {
    final isSelected = _selectedCondition == condition;
    
    return ListTile(
      title: Text(condition),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        setState(() => _selectedCondition = condition);
        Navigator.pop(context);
      },
    );
  }

  /// Affiche le sélecteur de prix
  void _showPricePicker(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    final controller = TextEditingController(text: _priceController.text);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.price,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.priceHint,
                suffixText: 'FCFA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _priceController.text = controller.text;
                  });
                  Navigator.pop(context);
                },
                child: Text(l10n.validate),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Vérifie si on peut publier
  bool _canPublish() {
    return _selectedImages.isNotEmpty &&
        _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _selectedCategory != null &&
        _selectedCondition != null &&
        _priceController.text.isNotEmpty;
  }

  /// Gère la publication
  void _handlePublish() {
    // TODO: Implémenter la création du produit
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Publication du produit - À implémenter'),
      ),
    );
  }
}
