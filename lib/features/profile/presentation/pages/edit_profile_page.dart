import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../sell/data/services/image_upload_service.dart';
import '../../../sell/presentation/widgets/image_picker_grid.dart';

/// Modifier son profil.
///
/// Photo, nom affiché, ville. Rien d'autre : le pseudonyme sert d'identifiant
/// public et l'adresse e-mail a son propre écran, où l'état de vérification
/// compte autant que la valeur.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nom = TextEditingController();
  final _ville = TextEditingController();
  List<dynamic> _photo = [];
  bool _initialise = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    _ville.dispose();
    super.dispose();
  }

  Future<void> _enregistrer(String uid) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      String? photoUrl;
      // La grille rend des `XFile` : filtrer sur `File` ne trouvait jamais
      // rien, et la photo de profil n'était donc jamais envoyée.
      final fichier = _photo.whereType<XFile>().firstOrNull;

      // Trois situations à distinguer, et non deux : une nouvelle photo, la
      // photo inchangée (son adresse est encore dans la grille), ou la photo
      // retirée (la grille est vide alors que le compte en avait une).
      // Confondre les deux dernières rendait tout retrait impossible.
      final gardeSonAdresse = _photo.whereType<String>().isNotEmpty;
      final avaitUnePhoto =
          ref.read(currentUserProvider).value?.photoUrl != null;
      final effacer = fichier == null && !gardeSonAdresse && avaitUnePhoto;

      if (fichier != null) {
        photoUrl = await ref
            .read(imageUploadServiceProvider)
            .uploadProfileImage(uid: uid, file: fichier);
      }

      await ref.read(authRepositoryProvider).updateUserProfile(
            uid: uid,
            displayName: _nom.text.trim().isEmpty ? null : _nom.text.trim(),
            city: _ville.text.trim().isEmpty ? null : _ville.text.trim(),
            photoUrl: photoUrl,
            effacerPhoto: effacer,
          );

      // Le fichier n'est supprimé qu'une fois le profil enregistré : dans
      // l'ordre inverse, un échec d'enregistrement laisserait un compte
      // pointant vers une image qui n'existe plus.
      if (effacer) {
        await ref.read(imageUploadServiceProvider).deleteProfileImage(uid);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editProfileSaved)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profil = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: profil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          // Une seule fois : recharger à chaque reconstruction écraserait ce
          // que la personne est en train de taper.
          if (!_initialise) {
            _initialise = true;
            _nom.text = user.displayName ?? '';
            _ville.text = user.city ?? '';
            if (user.photoUrl != null) _photo = [user.photoUrl!];
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.editProfilePhoto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ImagePickerGrid(
                images: _photo,
                maxImages: 1,
                onImagesChanged: (images) => setState(() => _photo = images),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nom,
                enabled: !_envoi,
                decoration: InputDecoration(
                  labelText: l10n.editProfileDisplayName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ville,
                enabled: !_envoi,
                decoration: InputDecoration(
                  labelText: l10n.editProfileCity,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 16),
                Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _envoi ? null : () => _enregistrer(user.uid),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.editProfileSave),
              ),
            ],
          );
        },
      ),
    );
  }
}
