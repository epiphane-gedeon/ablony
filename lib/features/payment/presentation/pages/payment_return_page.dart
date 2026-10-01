import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page d'atterrissage après un paiement, quand le fournisseur renvoie le
/// navigateur vers nous.
///
/// Sur mobile, la WebView intercepte ces URLs sans jamais les charger : cette
/// page n'y sert jamais. Sur le web en revanche, le paiement s'ouvre dans un
/// **autre onglet** et le fournisseur l'y redirige pour de bon — sans route
/// correspondante, l'utilisateur tombait sur « Page non trouvée » juste après
/// avoir payé. De tous les moments où afficher une erreur, c'est le pire :
/// l'argent vient de partir.
///
/// Le verdict ne se décide pas ici. L'onglet d'origine surveille la
/// transaction en base et affiche le vrai résultat ; cette page n'a qu'à
/// rassurer et dire que l'onglet peut être fermé.
class PaymentReturnPage extends StatelessWidget {
  const PaymentReturnPage({super.key, required this.reussi});

  /// Vrai pour l'URL de succès, faux pour celle d'abandon.
  final bool reussi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reussi ? Icons.check_circle_outline : Icons.info_outline,
                  size: 56,
                  color: reussi
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  reussi ? 'Paiement envoyé' : 'Paiement interrompu',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  // On ne proclame pas « réussi » : à cet instant seule la
                  // confirmation du serveur fait foi, et elle arrive dans
                  // l'autre onglet. Annoncer un succès ici puis le contredire
                  // ailleurs serait pire que de ne rien dire.
                  reussi
                      ? 'Vous pouvez fermer cet onglet et revenir à Ablony : '
                          'la confirmation s\'y affiche automatiquement.'
                      : 'Aucun montant n\'a été prélevé. Vous pouvez fermer '
                          'cet onglet et réessayer depuis Ablony.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Retour à Ablony'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
