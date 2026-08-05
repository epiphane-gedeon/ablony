import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/payment_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../payment/presentation/pages/payment_web_view_page.dart';
import '../../domain/boost_config.dart';
import '../../domain/entities/entities.dart';
import '../providers/product_provider.dart';

/// Bottom sheet permettant à un vendeur de booster son propre produit
/// (mise en avant payante de 48h, voir `BOOST_CONFIG` dans functions/index.js).
///
/// Un seul bouton "Payer" — comme pour la recharge du wallet, on choisit
/// d'abord le montant (ici fixe), puis on est redirigé vers l'écran de
/// choix du moyen de paiement (`/payment-method/select`).
class BoostBottomSheet extends ConsumerStatefulWidget {
  final Product product;

  const BoostBottomSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BoostBottomSheet(product: product),
    );
  }

  @override
  ConsumerState<BoostBottomSheet> createState() => _BoostBottomSheetState();
}

class _BoostBottomSheetState extends ConsumerState<BoostBottomSheet> {
  bool _isProcessing = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handlePay() async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    // Comme pour la recharge du wallet : montant déjà fixé, on redirige
    // directement vers le choix du moyen de paiement.
    final result = await context.push('/payment-method/select', extra: {'isRecharge': false});

    if (result == null || result is! Map<String, dynamic>) return;
    final method = result['method'] as String?;
    final phone = result['phoneNumber'] as String?;
    if (method == null) return;

    if (method == 'wallet') {
      final available = user.wallet?.availableAmountInXOF ?? 0;
      if (available < kBoostPriceXOF) {
        _showError(l10n.boostInsufficientBalance);
        return;
      }
    }

    if (!mounted) return;
    await _pay(method, phone: phone);
  }

  Future<void> _pay(String paymentMethod, {String? phone}) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final responseData = await paymentService.initiatePayment(
        userId: user.uid,
        amount: kBoostPriceXOF.toDouble(),
        paymentMethod: paymentMethod,
        phone: phone,
        name: user.displayName,
        email: user.email,
        description: 'Boost produit Ablony : ${widget.product.title}',
        type: 'boost',
        productId: widget.product.id,
      );

      if (responseData['status'] == 'completed' ||
          responseData['completed'] == true) {
        await _onBoostSuccess();
        return;
      }

      final paymentUrl = responseData['paymentUrl'] as String?;
      final reference = responseData['reference'] as String?;

      if (!mounted) return;

      if (paymentUrl != null) {
        final paymentCompleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => PaymentWebViewPage(url: paymentUrl),
          ),
        );

        if (!mounted) return;

        if (paymentCompleted == true && reference != null) {
          await paymentService.confirmPayment(reference: reference);
          if (!mounted) return;
          await _onBoostSuccess();
        } else {
          setState(() => _isProcessing = false);
        }
      } else {
        setState(() => _isProcessing = false);
        _showError('Impossible d\'initier le paiement (URL manquante)');
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception:', '').trim();
      setState(() => _isProcessing = false);
      _showError(
        message.contains('insuffisant') ? l10n.boostInsufficientBalance : message,
      );
    }
  }

  Future<void> _onBoostSuccess() async {
    ref.invalidate(activeBoostedProductsProvider);
    ref.invalidate(productStreamByIdProvider(widget.product.id));
    ref.invalidate(sellerProductsProvider(widget.product.sellerId));

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isProcessing = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.boostSuccess), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isActivelyBoosted = widget.product.isBoosted &&
        (widget.product.boostExpiresAt?.isAfter(DateTime.now()) ?? false);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.bolt, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.boostSheetTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.boostSheetDescription(kBoostDurationHours),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (isActivelyBoosted) ...[
            const SizedBox(height: 8),
            Text(
              l10n.boostAlreadyActive(
                DateFormat('dd/MM/yyyy HH:mm').format(widget.product.boostExpiresAt!),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prix',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$kBoostPriceXOF FCFA',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: l10n.boostPay,
            isLoading: _isProcessing,
            onPressed: _isProcessing ? null : _handlePay,
          ),
        ],
      ),
    );
  }
}
