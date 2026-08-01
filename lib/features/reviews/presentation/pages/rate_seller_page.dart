import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/review_provider.dart';
import '../widgets/star_rating.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/buttons.dart';

/// Page proposée à l'acheteur juste après un achat finalisé, pour noter
/// le vendeur (1 à 5 étoiles + commentaire optionnel).
class RateSellerPage extends ConsumerStatefulWidget {
  final String transactionRef;
  final String sellerId;
  final String productId;
  final String productTitle;

  const RateSellerPage({
    super.key,
    required this.transactionRef,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
  });

  @override
  ConsumerState<RateSellerPage> createState() => _RateSellerPageState();
}

class _RateSellerPageState extends ConsumerState<RateSellerPage> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(reviewRepositoryProvider);
      await repository.submitReview(
        transactionRef: widget.transactionRef,
        sellerId: widget.sellerId,
        productId: widget.productId,
        productTitle: widget.productTitle,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      context.go('/messages');
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGenericMsg(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rateSellerPageTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => context.go('/messages'),
            child: Text(l10n.skip),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.celebration_outlined, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.rateSellerHeadline(widget.productTitle),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              StarRatingInput(
                value: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.rateSellerCommentHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: l10n.rateSellerSubmitButton,
                isLoading: _isSubmitting,
                onPressed: _rating == 0 ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
