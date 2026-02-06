import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/dynamic_ui/dynamic_selection_view.dart';
import '../../../../core/presentation/pages/selection_screen.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/input.dart';
import '../../../../shared/widgets/selection_tile.dart';
import '../../../auth/domain/entities/country.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon porte-monnaie'),
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
                  'Montant en attente',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '0,00 €',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                '0,00 €',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Montant disponible',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Bouton "Activer le porte-monnaie"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PrimaryButton(
              text: 'Activer le porte-monnaie',
              onPressed: () => _openWalletSetup(context),
            ),
          ),

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

class _WalletSetupForm extends StatefulWidget {
  const _WalletSetupForm();

  @override
  State<_WalletSetupForm> createState() => _WalletSetupFormState();
}

class _WalletSetupFormState extends State<_WalletSetupForm> {
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
          title: 'Nationalité',
          content: DynamicSelectionView(
            config: nationalityConfig,
            dataSources: {
              'nationalities': (_) async {
                return Country.all
                    .map(
                      (c) => {'code': c.code, 'name': c.name, 'emoji': c.flag},
                    )
                    .toList();
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
        title: const Text('Configuration du porte-monnaie'),
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
              label: 'Prénom(s) du titulaire du compte',
              placeholder: 'John',
              type: InputType.text,
            ),

            const SizedBox(height: 16),

            // Nom de famille
            Input(
              controller: _lastNameController,
              label: 'Nom de famille du titulaire du compte',
              placeholder: 'Doe',
              type: InputType.text,
            ),

            const SizedBox(height: 16),

            // Nationalité
            SelectionTile(
              label: 'Nationalité',
              value: _selectedNationality,
              placeholder: 'Sélectionne une nationalité',
              onTap: () => _showNationalityPicker(context),
              isRequired: true,
            ),

            const SizedBox(height: 16),

            // Date de naissance
            SelectionTile(
              label: 'Date de naissance',
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
              text: 'Activer le porte-monnaie',
              onPressed: () {
                // TODO: Gérer l'activation du porte-monnaie
                print(
                  'Données: ${_firstNameController.text} ${_lastNameController.text}, $_selectedNationality, $_selectedBirthDate',
                );
                Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
