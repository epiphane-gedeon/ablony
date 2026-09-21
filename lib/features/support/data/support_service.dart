import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// L'assistance : un fil de discussion entre un membre et l'équipe Ablony.
///
/// Volontairement à part des conversations entre membres, qui sont adossées à
/// une annonce. Y greffer l'assistance aurait demandé d'inventer un produit
/// fictif, et mélangé deux choses qui n'ont ni les mêmes destinataires, ni les
/// mêmes règles d'accès, ni la même durée de vie.
///
/// L'identifiant du fil **est** celui du membre : un fil par personne,
/// retrouvable sans requête.
class SupportService {
  SupportService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Utilisateur non authentifié');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _fil(String uid) =>
      _db.collection('support').doc(uid);

  /// Les messages du fil, du plus ancien au plus récent.
  Stream<List<SupportMessage>> messages([String? userId]) {
    return _fil(userId ?? _uid)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(SupportMessage.depuis).toList());
  }

  /// Envoie un message, en créant le fil au besoin.
  ///
  /// Le fil porte un résumé (dernier message, date, non-lus) : la console
  /// d'administration liste ainsi les demandes sans avoir à ouvrir chaque
  /// conversation.
  Future<void> envoyer({required String texte, XFile? image}) async {
    final uid = _uid;
    final texteNet = texte.trim();
    if (texteNet.isEmpty && image == null) return;

    String? imageUrl;
    if (image != null) {
      final chemin = 'support/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(chemin);
      // `putData` et non `putFile` : ce dernier passe par `dart:io`, absent du
      // web — or c'est précisément depuis un navigateur qu'on écrit le plus
      // souvent au support après un paiement resté en attente.
      await ref.putData(
        await image.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      imageUrl = await ref.getDownloadURL();
    }

    final maintenant = FieldValue.serverTimestamp();

    await _fil(uid).set({
      'userId': uid,
      'lastMessage': texteNet.isEmpty ? '📎 Pièce jointe' : texteNet,
      'lastMessageAt': maintenant,
      'lastSenderId': uid,
      // Ce que l'équipe n'a pas encore lu. Remis à zéro quand elle répond.
      'unreadForStaff': FieldValue.increment(1),
      'status': 'open',
      'updatedAt': maintenant,
    }, SetOptions(merge: true));

    await _fil(uid).collection('messages').add({
      'senderId': uid,
      'text': texteNet,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': maintenant,
    });
  }

  /// Marque comme lus les messages de l'équipe.
  Future<void> marquerLu() async {
    await _fil(_uid).set(
      {'unreadForUser': 0},
      SetOptions(merge: true),
    );
  }
}

/// Un message du fil d'assistance.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final String? imageUrl;

  static SupportMessage depuis(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    return SupportMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      text: d['text'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      // `serverTimestamp` est nul le temps que le serveur réponde : on affiche
      // alors l'heure locale plutôt qu'un trou dans la liste.
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService();
});

/// Le fil du membre connecté, en direct.
final supportMessagesProvider = StreamProvider<List<SupportMessage>>((ref) {
  return ref.watch(supportServiceProvider).messages();
});
