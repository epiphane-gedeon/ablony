import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/report_reason.dart';
import '../providers/report_provider.dart';

/// Signaler un membre.
///
/// Distinct du blocage, et proposé juste après : bloquer règle mon problème,
/// signaler porte le problème à Ablony. Confondre les deux, c'est soit une
/// personne qui subit en silence, soit une équipe qui ne sait rien.
class ReportUserDialog extends ConsumerStatefulWidget {
  const ReportUserDialog({
    super.key,
    required this.reportedUserId,
    required this.username,
  });

  final String reportedUserId;
  final String username;

  static Future<void> show(
    BuildContext context, {
    required String reportedUserId,
    required String username,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ReportUserDialog(
        reportedUserId: reportedUserId,
        username: username,
      ),
    );
  }

  @override
  ConsumerState<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends ConsumerState<ReportUserDialog> {
  ReportReason? _motif;
  final _commentaire = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  String _libelle(AppLocalizations l10n, ReportReason motif) {
    switch (motif) {
      case ReportReason.counterfeit:
        return l10n.reportReasonCounterfeit;
      case ReportReason.inappropriate:
        return l10n.reportReasonInappropriate;
      case ReportReason.scam:
        return l10n.reportReasonScam;
      case ReportReason.other:
        return l10n.reportReasonOther;
    }
  }

  Future<void> _envoyer() async {
    if (_motif == null) return;
    setState(() => _envoi = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(reportRepositoryProvider).submitUserReport(
            reportedUserId: widget.reportedUserId,
            reason: _motif!,
            comment: _commentaire.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportSuccessMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGenericMsg(e.toString()))),
      );
      setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text('${l10n.reportUser} ${widget.username}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioGroup<ReportReason>(
              groupValue: _motif,
              onChanged: (v) {
                if (_envoi) return;
                setState(() => _motif = v);
              },
              child: Column(
                children: ReportReason.values
                    .map(
                      (motif) => RadioListTile<ReportReason>(
                        value: motif,
                        title: Text(_libelle(l10n, motif)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentaire,
              enabled: !_envoi,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.reportCommentHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _envoi ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _envoi || _motif == null ? null : _envoyer,
          child: _envoi
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.reportUser),
        ),
      ],
    );
  }
}
