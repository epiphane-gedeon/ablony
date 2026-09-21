import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/image_source_sheet.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../messages/presentation/widgets/message_bubble.dart';
import '../../data/support_service.dart';

/// Écrire à l'équipe Ablony, depuis l'application.
///
/// Sert surtout quand quelque chose a mal tourné avec de l'argent : un débit
/// sans contrepartie, un paiement resté en attente. Ces situations se règlent
/// en montrant une preuve — d'où l'envoi de photos, et non un simple formulaire
/// de contact.
///
/// Le fil est permanent : la personne retrouve ce qu'elle a écrit et ce qu'on
/// lui a répondu, ce qu'un courriel dans la nature ne garantit pas.
class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key, this.messageInitial});

  /// Texte pré-rempli, quand on arrive depuis un écran qui sait déjà de quoi
  /// il s'agit — un paiement bloqué, par exemple, dont on connaît la référence.
  final String? messageInitial;

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  final _saisie = TextEditingController();
  final _defilement = ScrollController();
  XFile? _piece;
  Uint8List? _apercu;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    if (widget.messageInitial != null) _saisie.text = widget.messageInitial!;
    ref.read(supportServiceProvider).marquerLu();
  }

  @override
  void dispose() {
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  Future<void> _choisirImage() async {
    final image = await pickImageFromSourceSheet(context);
    if (image == null) return;
    final octets = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _piece = image;
      _apercu = octets;
    });
  }

  Future<void> _envoyer() async {
    if (_saisie.text.trim().isEmpty && _piece == null) return;
    setState(() => _envoi = true);
    try {
      await ref.read(supportServiceProvider).envoyer(
            texte: _saisie.text,
            image: _piece,
          );
      if (!mounted) return;
      _saisie.clear();
      setState(() {
        _piece = null;
        _apercu = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final moi = ref.watch(authStateProvider).value?.uid;
    final messages = ref.watch(supportMessagesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (liste) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_defilement.hasClients) {
                    _defilement.jumpTo(_defilement.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _defilement,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: liste.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) return _Accueil(vide: liste.isEmpty);
                    final m = liste[i - 1];
                    return MessageBubble(
                      isMe: m.senderId == moi,
                      text: m.text.isEmpty ? null : m.text,
                      imageUrl: m.imageUrl,
                    );
                  },
                );
              },
            ),
          ),
          if (_apercu != null) _apercuPiece(theme),
          _barreSaisie(l10n, theme),
        ],
      ),
    );
  }

  Widget _apercuPiece(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(_apercu!, height: 56, width: 56,
                fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _piece = null;
              _apercu = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _barreSaisie(AppLocalizations l10n, ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              tooltip: l10n.supportAttach,
              onPressed: _envoi ? null : _choisirImage,
            ),
            Expanded(
              child: TextField(
                controller: _saisie,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.supportHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _envoi ? null : _envoyer,
              icon: _envoi
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce qu'on lit en arrivant : à quoi sert ce fil, et sous quel délai.
///
/// Annoncer le délai évite la seconde déception — celle de l'attente sans
/// repère, après celle qui a motivé le message.
class _Accueil extends StatelessWidget {
  const _Accueil({required this.vide});

  final bool vide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent_outlined,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.supportWelcomeTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              vide ? l10n.supportWelcomeEmpty : l10n.supportWelcomeDelay,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
