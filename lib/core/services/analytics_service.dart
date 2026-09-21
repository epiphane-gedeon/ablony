import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le suivi de comportement, en un seul endroit.
///
/// Des méthodes typées plutôt que des chaînes d'événements dispersées : le nom
/// d'un événement mal orthographié une fois sur deux donne deux courbes au lieu
/// d'une, et on ne s'en aperçoit que trois mois plus tard. Ici, chaque
/// événement a une méthode, et le nom n'existe qu'une fois.
///
/// Firebase Analytics est gratuit et sans plafond : on peut logger sans se
/// soucier du coût. On ne logge donc que ce qui répond à une vraie question,
/// pas tout — une donnée qu'on ne regardera jamais est du bruit, pas un coût.
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  /// Un compte vient d'être créé. `method` : google, facebook, apple, email.
  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  /// Une recherche a été lancée. Le terme nourrit « ce que les gens cherchent »
  /// dans la console — l'un des rapports les plus utiles d'une place de marché.
  Future<void> logSearch(String terme) =>
      _analytics.logSearch(searchTerm: terme);

  /// Une fiche produit a été ouverte. Alimente l'entonnoir vue → achat.
  Future<void> logViewItem({
    required String productId,
    String? category,
    double? price,
  }) =>
      _analytics.logViewItem(
        currency: 'XOF',
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemCategory: category,
            price: price,
          ),
        ],
      );

  /// Une annonce a été mise en vente.
  Future<void> logListingCreated({String? category, double? price}) =>
      _analytics.logEvent(
        name: 'listing_created',
        parameters: {
          if (category != null) 'category': category,
          if (price != null) 'price': price,
        },
      );

  /// Un achat a été finalisé.
  Future<void> logPurchase({
    required String transactionRef,
    required double amount,
  }) =>
      _analytics.logPurchase(
        currency: 'XOF',
        value: amount,
        transactionId: transactionRef,
      );

  /// Un retrait a été demandé.
  Future<void> logWithdrawalRequested(double amount) => _analytics.logEvent(
        name: 'withdrawal_requested',
        parameters: {'amount': amount},
      );

  /// Un litige a été ouvert.
  Future<void> logDisputeOpened(String reason) => _analytics.logEvent(
        name: 'dispute_opened',
        parameters: {'reason': reason},
      );

  /// L'observateur de navigation, à brancher sur le routeur : il logge
  /// automatiquement chaque écran visité, sans un appel par page.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(FirebaseAnalytics.instance);
});
