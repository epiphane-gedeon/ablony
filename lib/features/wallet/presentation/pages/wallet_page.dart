import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/dynamic_ui/dynamic_selection_view.dart';
import '../../../../core/presentation/pages/selection_screen.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/info_bubble.dart';
import '../../../../shared/widgets/input.dart';
import '../../../../shared/widgets/selection_tile.dart';
import '../../../auth/application/auth_providers.dart';
import '../../data/nationalities.dart';
import '../../domain/models/wallet.dart';
import '../../../../l10n/app_localizations.dart';

/// Page du porte-monnaie utilisateur
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final wallet = userAsync.value?.wallet;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myWallet),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // Montant en attente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.pendingAmount,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      wallet != null
                          ? '${wallet.pendingAmountInXOF.toStringAsFixed(0)} FCFA'
                          : '0 FCFA',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InfoBubble(
                      message: AppLocalizations.of(context)!.pendingAmountInfo,
                      link: TextButton(
                        onPressed: () {
                          // TODO: Naviguer vers la page d'aide
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)!.helpPageComingSoon),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.learnMore,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      displayDuration: 5,
                      iconColor: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Montant disponible - grand affichage
          Column(
            children: [
              Text(
                wallet != null
                    ? '${wallet.availableAmountInXOF.toStringAsFixed(0)} FCFA'
                    : '0 FCFA',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.availableAmount,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Bouton "Activer le porte-monnaie" (affiché seulement si non activé)
          if (wallet == null || !wallet.isActivated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PrimaryButton(
                text: AppLocalizations.of(context)!.activateWallet,
                onPressed: () => _openWalletSetup(context),
              ),
            ),

          // Boutons Recharger et Retirer (affichés seulement si le wallet est activé)
          if (wallet != null && wallet.isActivated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: AppLocalizations.of(context)!.topUpWallet,
                      onPressed: () {
                        // TODO: Implémenter la recharge
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.topUpComingSoon),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      text: AppLocalizations.of(context)!.withdrawWallet,
                      onPressed: () {
                        // TODO: Implémenter le retrait
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.withdrawalComingSoon),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80), // Espace pour la nav bar
        ],
      ),
    );
  }

  void _openWalletSetup(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const _WalletSetupForm()));
  }
}

class _WalletSetupForm extends ConsumerStatefulWidget {
  const _WalletSetupForm();

  @override
  ConsumerState<_WalletSetupForm> createState() => _WalletSetupFormState();
}

class _WalletSetupFormState extends ConsumerState<_WalletSetupForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _selectedNationality;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _showNationalityPicker(BuildContext context) {
    final userAsync = ref.read(currentUserProvider);
    final userCountryCode = userAsync.value?.country.code;

    final nationalityConfig = {
      'type': 'list',
      'dataSource': 'nationalities',
      'itemKey': 'code',
      'itemLabel': 'name',
      'itemIcon': 'emoji',
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectionScreen(
          title: AppLocalizations.of(context)!.nationality,
          content: DynamicSelectionView(
            config: nationalityConfig,
            dataSources: {
              'nationalities': (_) async {
                final allNationalities = Nationalities.all.toList();

                // Si l'utilisateur a un pays, on le met en premier
                if (userCountryCode != null) {
                  // Trouver la nationalité correspondant au pays de l'utilisateur
                  final userNationalityIndex = allNationalities.indexWhere(
                    (n) => n['code'] == userCountryCode,
                  );

                  if (userNationalityIndex != -1) {
                    final userNationality = allNationalities.removeAt(
                      userNationalityIndex,
                    );
                    allNationalities.insert(0, userNationality);
                  }
                }

                return allNationalities;
              },
            },
            onResult: (item) {
              if (item != null) {
                Navigator.of(context).pop();
                setState(() {
                  _selectedNationality = item['name'] as String;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showBirthDatePicker(BuildContext context) async {
    final initialDate = _selectedBirthDate ?? DateTime(1990, 1, 1);
    final firstDate = DateTime(1900);
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.walletConfig),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prénom
            Input(
              controller: _firstNameController,
              label: AppLocalizations.of(context)!.accountHolderFirstName,
              placeholder: 'John',
              type: InputType.text,
            ),

            const SizedBox(height: 16),

            // Nom de famille
            Input(
              controller: _lastNameController,
              label: AppLocalizations.of(context)!.accountHolderLastName,
              placeholder: 'Doe',
              type: InputType.text,
            ),

            const SizedBox(height: 16),

            // Nationalité
            SelectionTile(
              label: AppLocalizations.of(context)!.nationality,
              value: _selectedNationality,
              placeholder: AppLocalizations.of(context)!.selectNationalityPlaceholder,
              onTap: () => _showNationalityPicker(context),
              isRequired: true,
            ),

            const SizedBox(height: 16),

            // Date de naissance
            SelectionTile(
              label: AppLocalizations.of(context)!.birthDate,
              value: _selectedBirthDate != null
                  ? '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}'
                  : null,
              placeholder: '01/01/1990',
              onTap: () => _showBirthDatePicker(context),
              isRequired: true,
            ),

            const SizedBox(height: 16),

            const Spacer(),

            // Bouton
            PrimaryButton(
              text: AppLocalizations.of(context)!.activateWallet,
              onPressed: () => _activateWallet(context),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _activateWallet(BuildContext context) async {
    // Validation des champs
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterFirstName)),
      );
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterLastName)),
      );
      return;
    }

    if (_selectedNationality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectNationality)),
      );
      return;
    }

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectBirthDate),
        ),
      );
      return;
    }

    try {
      // Récupérer l'utilisateur actuel
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer l'objet Wallet
      final wallet = Wallet(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        nationality: _selectedNationality!,
        birthDate: _selectedBirthDate!,
        availableAmount: 0, // Initialiser à 0
        pendingAmount: 0, // Initialiser à 0
        isActivated: true,
        activatedAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore via le repository
      await ref
          .read(authRepositoryProvider)
          .updateUserProfile(uid: user.uid, wallet: wallet);

      // Invalider le provider pour recharger les données
      ref.invalidate(currentUserProvider);

      if (context.mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.walletActivatedSuccess),
            backgroundColor: Colors.green,
          ),
        );

        // Retour à la page du wallet
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGenericMsg(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
