import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/application/auth_providers.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/custom_checkbox.dart';
import '../../../../shared/widgets/input.dart';
import '../../../../core/responsive/responsive.dart';

/// Page de sélection du mode de paiement
class PaymentMethodPage extends ConsumerStatefulWidget {
  final bool isRecharge;
  const PaymentMethodPage({super.key, this.isRecharge = false});

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  String _selectedMethod = ''; // 'tmoney', 'flooz', 'card', 'wallet'
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour le formulaire de carte
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // Contrôleurs pour les numéros de téléphone mobile money
  final _tmoneyPhoneController = TextEditingController();
  final _floozPhoneController = TextEditingController();

  bool _saveCard = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _tmoneyPhoneController.dispose();
    _floozPhoneController.dispose();
    super.dispose();
  }

  Future<void> _confirmPaymentMethod() async {
    if (_selectedMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un mode de paiement'),
        ),
      );
      return;
    }

    if (_selectedMethod == 'wallet') {
      context.pop({
        'method': 'wallet',
        'phoneNumber': null,
      });
      return;
    }

    // Validation selon le mode de paiement sélectionné
    if (_selectedMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMethod == 'tmoney' && _tmoneyPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre numéro T-Money')),
      );
      return;
    }

    if (_selectedMethod == 'flooz' && _floozPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre numéro Flooz')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Sauvegarder le mode de paiement
      await Future.delayed(const Duration(seconds: 1)); // Simulation

      if (mounted) {
        context.pop({
          'method': _selectedMethod,
          'phoneNumber': _selectedMethod == 'tmoney'
              ? _tmoneyPhoneController.text
              : (_selectedMethod == 'flooz' ? _floozPhoneController.text : null),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = context.layoutWidth();
    final userAsync = ref.watch(currentUserProvider);
    final wallet = userAsync.value?.wallet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modes de paiement'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Porte-monnaie (affiché seulement si ce n'est pas une recharge et que le wallet est activé)
                if (!widget.isRecharge && wallet != null && wallet.isActivated) ...[
                  _buildPaymentCard(
                    title: 'Porte-monnaie Ablony',
                    subtitle: 'Payer avec votre solde (${wallet.availableAmountInXOF.toStringAsFixed(0)} FCFA)',
                    icon: Icons.account_balance_wallet,
                    method: 'wallet',
                    expandedContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solde disponible : ${wallet.availableAmountInXOF.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Le montant sera débité directement de votre porte-monnaie.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // T-Money (Mix by Yas)
                _buildPaymentCard(
                  title: 'T-Money (Mix by Yas)',
                  subtitle: 'Payer avec T-Money',
                  icon: Icons.phone_android,
                  method: 'tmoney',
                  expandedContent: Input(
                    controller: _tmoneyPhoneController,
                    label: 'Numéro de téléphone T-Money',
                    placeholder: 'Ex: 90 00 00 00',
                    type: InputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre numéro';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Flooz (Moov Money)
                _buildPaymentCard(
                  title: 'Flooz (Moov Money)',
                  subtitle: 'Payer avec Flooz',
                  icon: Icons.phone_android,
                  method: 'flooz',
                  expandedContent: Input(
                    controller: _floozPhoneController,
                    label: 'Numéro de téléphone Flooz',
                    placeholder: 'Ex: 96 00 00 00',
                    type: InputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre numéro';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Carte bancaire
                _buildPaymentCard(
                  title: 'Carte bancaire',
                  subtitle: 'Payer par carte bancaire',
                  icon: Icons.credit_card,
                  method: 'card',
                  expandedContent: _buildCardForm(),
                ),
              ],
            ),
          ),

          // Bouton Poursuivre fixé en bas
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: PrimaryButton(
              text: 'Poursuivre',
              onPressed: _isLoading ? null : _confirmPaymentMethod,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardLogo(String assetPath) {
    return Container(
      width: 40,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Icon(Icons.credit_card, size: 16, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildPaymentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String method,
    required Widget expandedContent,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedMethod == method;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.cardColor,
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // En-tête de la carte (toujours visible)
          InkWell(
            onTap: () {
              setState(() {
                _selectedMethod = method;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  // Icône
                  Icon(
                    icon,
                    color: isSelected ? theme.colorScheme.primary : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),

                  // Titre et sous-titre
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flèche ou cercle de sélection
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 24,
                    )
                  else
                    Icon(Icons.chevron_right, color: Colors.grey, size: 24),
                ],
              ),
            ),
          ),

          // Contenu étendu (formulaire) visible uniquement si sélectionné
          if (isSelected) ...[
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(16), child: expandedContent),
          ],
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logos des cartes acceptées
          Row(
            children: [
              _buildCardLogo('assets/icons/mastercard.png'),
              const SizedBox(width: 8),
              _buildCardLogo('assets/icons/visa.png'),
              const SizedBox(width: 8),
              _buildCardLogo('assets/icons/discover.png'),
            ],
          ),
          const SizedBox(height: 20),

          // Nom figurant sur la carte
          Input(
            controller: _cardHolderController,
            label: 'Nom figurant sur la carte',
            placeholder: 'John Doe',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Numéro de carte bancaire
          Input(
            controller: _cardNumberController,
            label: 'Numéro de carte bancaire',
            placeholder: 'Par ex : 1234 1234 1234 1234',
            type: InputType.number,
            suffixIcon: const Icon(Icons.credit_card),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le numéro de carte';
              }
              if (value.replaceAll(' ', '').length < 13) {
                return 'Numéro de carte invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date d'expiration et code de sécurité
          Row(
            children: [
              Expanded(
                child: Input(
                  controller: _expiryController,
                  label: 'Date d\'expiration',
                  placeholder: 'MM / AA',
                  type: InputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Input(
                  controller: _cvvController,
                  label: 'Code de sécurité',
                  placeholder: 'Par ex : 123',
                  type: InputType.number,
                  suffixIcon: const Icon(Icons.info_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    if (value.length < 3) {
                      return 'Invalide';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkbox pour sauvegarder la carte
          CustomCheckbox(
            value: _saveCard,
            onChanged: (value) {
              setState(() {
                _saveCard = value ?? false;
              });
            },
            message:
                'Clique ici pour enregistrer les informations de ta carte bancaire pour payer plus rapidement la prochaine fois. Tu peux supprimer la carte à tout moment dans tes Paramètres > Paiements.',
          ),
        ],
      ),
    );
  }
}
