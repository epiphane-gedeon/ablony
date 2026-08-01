import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Upload les photos envoyées dans une conversation vers Firebase Storage.
/// Structure de stockage : `chat_images/{conversationId}/{senderId}/{timestamp}.jpg`
/// (le `senderId` fait partie du chemin car les règles Storage ne peuvent
/// pas vérifier l'appartenance à une conversation via Firestore — seul le
/// segment de chemin `{senderId}` peut être comparé à `request.auth.uid`).
class ChatImageUploadService {
  final FirebaseStorage _storage;

  ChatImageUploadService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadChatImage({
    required File image,
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

    final snapshot = await ref.putFile(image, metadata);
    return snapshot.ref.getDownloadURL();
  }
}

final chatImageUploadServiceProvider = Provider<ChatImageUploadService>((ref) {
  return ChatImageUploadService();
});
