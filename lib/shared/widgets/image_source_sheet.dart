import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';

/// Affiche un bottom sheet proposant "Prendre une photo" / "Choisir depuis
/// la galerie", puis retourne l'image sélectionnée (ou `null` si annulé).
///
/// On rend un [XFile], et non un `File` de `dart:io` : sur le web, `path` n'est
/// qu'une URL `blob:` et `dart:io` n'y fonctionne pas — construire un `File`
/// faisait échouer tout envoi d'image depuis le navigateur. [XFile] expose
/// `readAsBytes()`, qui marche sur toutes les plateformes.
Future<XFile?> pickImageFromSourceSheet(BuildContext context) async {
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

  return pickedFile;
}
