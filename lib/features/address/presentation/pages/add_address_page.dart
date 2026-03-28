import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/input.dart';
import '../../../location/data/models/location_data.dart';
import '../../../location/presentation/pages/select_location_page.dart';

/// Page pour ajouter ou modifier une adresse de livraison
class AddAddressPage extends ConsumerStatefulWidget {
  const AddAddressPage({super.key});

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();

  LocationData? _selectedLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  /// Ouvre la page de sélection de localisation
  Future<void> _selectLocation() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(builder: (context) => const SelectLocationPage()),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une localisation')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Sauvegarder l'adresse dans Firestore avec:
      // - _fullNameController.text
      // - _selectedLocation (latitude, longitude, formattedAddress, etc.)
      await Future.delayed(const Duration(seconds: 1)); // Simulation

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Adresse enregistrée')));

        // Retourner une adresse formatée
        final formattedAddress =
            '${_fullNameController.text}, ${_selectedLocation!.formattedAddress}';
        context.pop(formattedAddress);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAddress,
            child: Text(
              'Sauvegarder',
              style: TextStyle(
                color: _isLoading
                    ? theme.disabledColor
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom et prénom
            Input(
              controller: _fullNameController,
              label: 'Nom et prénom',
              placeholder: 'John Doe',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom complet';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Localisation
            Text(
              'Localisation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Bouton pour sélectionner la localisation
            if (_selectedLocation == null)
              OutlinedButton.icon(
                onPressed: _selectLocation,
                icon: const Icon(Icons.location_on),
                label: const Text('Choisir ma localisation'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedLocation!.formattedAddress,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _selectLocation,
                        icon: const Icon(Icons.edit_location_alt, size: 18),
                        label: const Text('Modifier la localisation'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Bouton Sauvegarder
            PrimaryButton(
              text: 'Sauvegarder',
              onPressed: _isLoading ? null : _saveAddress,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
