import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/cities.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/providers.dart';
import '../../domain/entities/country.dart';

/// Étape « ville » de l'inscription, juste après le pays.
///
/// Deux usages, une seule page :
/// - **Nouvelle inscription** : la ville termine l'inscription
///   (`completeRegistration`) et crée le compte.
/// - **Backfill** : un compte existant sans ville (créé avant cette étape) est
///   renvoyé ici ; on met simplement à jour son profil.
///
/// La ville est enregistrée sous deux formes : le libellé affiché (« Lomé ») et
/// une clé normalisée (« lome ») pour les comparaisons (géo-focus du lancement).
class CitySelectionPage extends ConsumerStatefulWidget {
  const CitySelectionPage({super.key});

  @override
  ConsumerState<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends ConsumerState<CitySelectionPage> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Le pays de référence : celui choisi à l'étape précédente, sinon celui du
  /// compte (backfill), sinon le pays de lancement.
  Country _country() {
    final reg = ref.read(registrationProvider).country;
    final user = ref.read(currentUserProvider).value?.country;
    return reg ?? user ?? FeatureFlags.paysParDefaut;
  }

  Future<void> _select(CityOption option) async {
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider).value;

      // Compte déjà créé (backfill) → simple mise à jour.
      if (currentUser != null && currentUser.username.isNotEmpty) {
        await ref.read(authRepositoryProvider).updateUserProfile(
              uid: currentUser.uid,
              city: option.label,
              cityKey: option.key,
            );
        if (mounted) context.go('/home');
        return;
      }

      // Nouvelle inscription → la ville termine la création du compte.
      final notifier = ref.read(registrationProvider.notifier);
      notifier.setCity(option.label, option.key);
      final user = await notifier.completeRegistration();
      if (!mounted) return;
      if (user != null) {
        ref.read(analyticsServiceProvider).logSignUp(user.authProvider.name);
        context.go('/home');
      } else {
        setState(() => _isLoading = false);
        final raison = ref.read(registrationProvider).errorMessage;
        _showError(raison ?? AppLocalizations.of(context)!.cityErrorGeneric);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e is AppException ? e.message : e.toString();
      _showError(message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final villes = citiesForCountry(_country());

    final q = normalizeCityKey(_query);
    final filtrees = q.isEmpty
        ? villes
        : villes.where((c) => c.key.contains(q)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cityPickTitle), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.cityPickSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              enabled: !_isLoading,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.citySearchHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.separated(
              itemCount: filtrees.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final ville = filtrees[i];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(ville.label),
                  onTap: _isLoading ? null : () => _select(ville),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
