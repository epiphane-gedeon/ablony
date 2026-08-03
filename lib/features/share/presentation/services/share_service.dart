import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/shareable_content.dart';
import '../../domain/share_link_builder.dart';

/// Point d'entrée unique du partage : reçoit n'importe quel [ShareableContent]
/// et ouvre le sheet natif du système avec un texte incluant un lien qui
/// redirige vers le contenu partagé.
class ShareService {
  Future<void> share(BuildContext context, ShareableContent content) async {
    final link = ShareLinkBuilder.build(content);
    final box = context.findRenderObject() as RenderBox?;

    final text = [
      content.title,
      if (content.subtitle != null) content.subtitle!,
      link,
    ].join('\n');

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }
}

final shareServiceProvider = Provider<ShareService>((ref) => ShareService());
