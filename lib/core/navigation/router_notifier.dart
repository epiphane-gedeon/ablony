import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/providers.dart';

/// Un [Listenable] qui notifie ses auditeurs lorsque l'état d'authentification ou de profil change.
///
/// Ce notificateur est utilisé par GoRouter pour réévaluer les redirections
/// sans avoir à recréer toute l'instance du routeur, ce qui évite le "restart" de l'app.
///
/// Il écoute les changements sur [authStateProvider] et [isProfileCompleteProvider]
/// et appelle [notifyListeners] lorsque l'un d'eux change.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Écouter les changements d'état d'authentification
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    // Écouter les changements de l'état de complétion du profil
    _ref.listen(isProfileCompleteProvider, (_, __) => notifyListeners());
  }
}

/// Provider pour le [RouterNotifier].
///
/// Ce provider crée une instance unique du notificateur qui sera
/// utilisée par le [routerProvider].
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});
