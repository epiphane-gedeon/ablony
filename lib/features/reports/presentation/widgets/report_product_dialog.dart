import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/report_reason.dart';
import '../providers/report_provider.dart';

/// Boîte de dialogue permettant à un acheteur de signaler un article
/// (contrefaçon, contenu inapproprié, arnaque potentielle...).
class ReportProductDialog extends ConsumerStatefulWidget {
  final String productId;
  final String productTitle;
  final String sellerId;

  const ReportProductDialog({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.sellerId,
  });

  static Future<void> show(
    BuildContext context, {
    required String productId,
    required String productTitle,
    required String sellerId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ReportProductDialog(
        productId: productId,
        productTitle: productTitle,
        sellerId: sellerId,
      ),
    );
  }

  @override
  ConsumerState<ReportProductDialog> createState() => _ReportProductDialogState();
}

class _ReportProductDialogState extends ConsumerState<ReportProductDialog> {
  ReportReason? _selectedReason;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, ReportReason reason) {
    switch (reason) {
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

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context)!;
    try {
      final repository = ref.read(reportRepositoryProvider);
      await repository.submitReport(
        productId: widget.productId,
        productTitle: widget.productTitle,
        sellerId: widget.sellerId,
        reason: _selectedReason!,
        comment: _commentController.text,
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
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.reportDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...ReportReason.values.map(
              (reason) => RadioListTile<ReportReason>(
                value: reason,
                groupValue: _selectedReason,
                onChanged: _isSubmitting ? null : (value) => setState(() => _selectedReason = value),
                title: Text(_reasonLabel(l10n, reason)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              enabled: !_isSubmitting,
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
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _isSubmitting || _selectedReason == null ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.reportSubmitButton),
        ),
      ],
    );
  }
}
