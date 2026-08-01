import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';

/// Affiche un bottom sheet proposant "Prendre une photo" / "Choisir depuis
/// la galerie", puis retourne le fichier sélectionné (ou `null` si annulé).
Future<File?> pickImageFromSourceSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(l10n.imageSourceCameraOption),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.imageSourceGalleryOption),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;

  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(
    source: source,
    imageQuality: 85,
    maxWidth: 1920,
    maxHeight: 1920,
  );

  if (pickedFile == null) return null;
  return File(pickedFile.path);
}
