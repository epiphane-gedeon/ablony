import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Upload les photos envoyées dans une conversation vers Firebase Storage.
/// Structure de stockage : `chat_images/{conversationId}/{senderId}/{timestamp}.jpg`
/// (le `senderId` fait partie du chemin car les règles Storage ne peuvent
/// pas vérifier l'appartenance à une conversation via Firestore — seul le
/// segment de chemin `{senderId}` peut être comparé à `request.auth.uid`).
class ChatImageUploadService {
  final FirebaseStorage _storage;

  ChatImageUploadService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Dépose l'image et renvoie son URL de téléchargement.
  ///
  /// L'envoi passe par `putData` et non `putFile` : `putFile` s'appuie sur
  /// `dart:io`, indisponible sur le web, où l'envoi d'image échouait donc
  /// systématiquement. Lire les octets marche partout — c'est déjà ce que fait
  /// l'envoi des photos d'annonce.
  Future<String> uploadChatImage({
    required XFile image,
    required String conversationId,
    required String senderId,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'chat_images/$conversationId/$senderId/$fileName';
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': senderId, 'conversationId': conversationId},
    );

    final snapshot = await ref.putData(await image.readAsBytes(), metadata);
    return snapshot.ref.getDownloadURL();
  }
}

final chatImageUploadServiceProvider = Provider<ChatImageUploadService>((ref) {
  return ChatImageUploadService();
});
