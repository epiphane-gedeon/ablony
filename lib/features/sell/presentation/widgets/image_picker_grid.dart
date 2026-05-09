import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../l10n/app_localizations.dart';

/// Widget pour sélectionner et afficher 1-6 photos de produit.
/// Supporte à la fois des fichiers local (File) et des URLs (String).
class ImagePickerGrid extends StatelessWidget {
  /// Liste des images (peut être File ou String URL)
  final List<dynamic> images;

  /// Callback appelé quand les images changent
  final ValueChanged<List<dynamic>> onImagesChanged;

  /// Nombre maximum d'images (par défaut 6)
  final int maxImages;

  const ImagePickerGrid({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 6,
  });

  /// Ouvre le sélecteur d'images
  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    
    try {
      final remainingSlots = maxImages - images.length;
      
      if (remainingSlots <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.maxPhotosReached),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFiles.isNotEmpty) {
        final filesToAdd = pickedFiles
            .take(remainingSlots)
            .map((xFile) => File(xFile.path))
            .toList();

        onImagesChanged([...images, ...filesToAdd]);
      }
    } catch (e) {
      debugPrint('Erreur lors de la sélection d\'images : $e');
    }
  }

  /// Supprime une image à l'index donné
  void _removeImage(int index) {
    final newImages = List<dynamic>.from(images);
    newImages.removeAt(index);
    onImagesChanged(newImages);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canAddMore = images.length < maxImages;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: images.length + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == images.length) {
                return _buildAddButton(context, l10n);
              }
              return _buildImageTile(context, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isFirst = images.isEmpty;

    return InkWell(
      onTap: () => _pickImages(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: isFirst ? 40 : 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addPhotos,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: isFirst ? 14 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(BuildContext context, int index) {
    final theme = Theme.of(context);
    final image = images[index];

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: image is File
              ? Image.file(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Image.network(
                  image as String,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '1',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
