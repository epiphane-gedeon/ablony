import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/payment_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../payment/presentation/pages/payment_web_view_page.dart';
import '../../domain/boost_config.dart';

/// Achat de boosts « en réserve » : on en achète plusieurs d'avance et on les
/// dépense plus tard, sur l'annonce de son choix (voir `applyBoost`).
///
/// Aucun produit n'est requis : on remplit un solde (`boostCredits`), on ne met
/// rien en avant ici. Le prix est imposé par le serveur — la quantité, elle,
/// est choisie par l'utilisateur puis validée côté serveur.
class BoostPackSheet extends ConsumerStatefulWidget {
  const BoostPackSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BoostPackSheet(),
    );
  }

  @override
  ConsumerState<BoostPackSheet> createState() => _BoostPackSheetState();
}

class _BoostPackSheetState extends ConsumerState<BoostPackSheet> {
  int _quantite = 1;
  bool _isProcessing = false;

  int get _total => _quantite * kBoostCreditPriceXOF;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _incrementer(int pas) {
    setState(() {
      _quantite = (_quantite + pas).clamp(1, kBoostMaxCreditsPerPurchase);
    });
  }

  Future<void> _handleBuy() async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final result = await context.push(
      '/payment-method/select',
      extra: {'isRecharge': false},
    );
    if (result == null || result is! Map<String, dynamic>) return;
    final method = result['method'] as String?;
    final phone = result['phoneNumber'] as String?;
    if (method == null) return;

    if (method == 'wallet') {
      final available = user.wallet?.availableAmountInXOF ?? 0;
      if (available < _total) {
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
        amount: _total.toDouble(),
        paymentMethod: paymentMethod,
        phone: phone,
        name: user.displayName,
        email: user.email,
        description: 'Achat de $_quantite boost(s) Ablony',
        type: 'boostpack',
        quantity: _quantite,
      );

      if (responseData['status'] == 'completed' ||
          responseData['completed'] == true) {
        await _onSuccess();
        return;
      }

      final paymentUrl = responseData['paymentUrl'] as String?;
      final reference = responseData['reference'] as String?;
      if (!mounted) return;

      if (paymentUrl != null) {
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) =>
                PaymentWebViewPage(url: paymentUrl, reference: reference),
          ),
        );
        if (!mounted) return;
        if (paid == true && reference != null) {
          await paymentService.confirmPayment(reference: reference);
          if (!mounted) return;
          await _onSuccess();
        } else {
          setState(() => _isProcessing = false);
        }
      } else {
        setState(() => _isProcessing = false);
        _showError('Impossible d\'initier le paiement (URL manquante)');
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception:', '').trim();
      if (mounted) setState(() => _isProcessing = false);
      _showError(
        message.contains('insuffisant')
            ? l10n.boostInsufficientBalance
            : message,
      );
    }
  }

  Future<void> _onSuccess() async {
    // La réserve a grandi côté serveur : on relit le profil.
    ref.invalidate(currentUserProvider);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final quantite = _quantite;
    setState(() => _isProcessing = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.boostPackSuccess(quantite)),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
              Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.boostPackTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.boostPackDescription(kBoostDurationHours),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          // Sélecteur de quantité
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.boostPackQuantity,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: (_isProcessing || _quantite <= 1)
                        ? null
                        : () => _incrementer(-1),
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '$_quantite',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: (_isProcessing ||
                            _quantite >= kBoostMaxCreditsPerPurchase)
                        ? null
                        : () => _incrementer(1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.boostPackTotal,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_total FCFA',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: l10n.boostPackBuy(_quantite, _total),
            isLoading: _isProcessing,
            onPressed: _isProcessing ? null : _handleBuy,
          ),
        ],
      ),
    );
  }
}
