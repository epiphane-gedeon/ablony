import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth_providers.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/exceptions/exceptions.dart';

/// État du formulaire de connexion.
///
/// Gère l'état de chargement, les erreurs et le succès de la connexion.
class LoginState {
  /// Indique si une opération de connexion est en cours
  final bool isLoading;

  /// Message d'erreur en cas d'échec de connexion
  final String? errorMessage;

  /// Indique si la connexion a réussi
  final bool isSuccess;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  /// État initial (aucune connexion en cours)
  factory LoginState.initial() => const LoginState();

  /// Crée une copie avec certains champs modifiés
  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Nullable pour reset l'erreur
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Controller pour gérer la logique de connexion.
///
/// Ce controller gère l'état de connexion et appelle le repository
/// pour authentifier l'utilisateur avec email/password.
///
/// **Utilisation :**
/// ```dart
/// final loginState = ref.watch(loginControllerProvider);
/// final loginController = ref.read(loginControllerProvider.notifier);
///
/// await loginController.login(
///   email: 'user@example.com',
///   password: 'password123',
/// );
/// ```
class LoginController extends Notifier<LoginState> {
  late final AuthRepository _authRepository;

  @override
  LoginState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return LoginState.initial();
  }

  /// Connecte l'utilisateur avec email et mot de passe.
  ///
  /// **Paramètres :**
  /// - [email] : Email ou username de l'utilisateur
  /// - [password] : Mot de passe
  ///
  /// **Retour :**
  /// - `true` si la connexion réussit
  /// - `false` en cas d'erreur (message dans state.errorMessage)
  ///
  /// **Exemple :**
  /// ```dart
  /// final success = await loginController.login(
  ///   email: 'user@example.com',
  ///   password: 'password123',
  /// );
  /// if (success) {
  ///   // Navigation automatique via AppRouter
  /// }
  /// ```
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.signInWithEmail(email: email, password: password);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Envoie un email de réinitialisation de mot de passe.
  ///
  /// Absorbe volontairement [UserNotFoundException] : l'appelant doit
  /// toujours afficher le même message générique de succès, qu'un compte
  /// existe ou non avec cet email, pour ne pas permettre à quelqu'un de
  /// deviner quels emails sont inscrits sur la plateforme (énumération de
  /// comptes). Les autres erreurs (réseau, etc.) sont propagées normalement.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email: email);
    } on UserNotFoundException {
      // Volontairement ignoré — voir la doc ci-dessus.
    }
  }

  /// Réinitialise l'état du controller.
  ///
  /// Utilisé quand on quitte l'écran de connexion.
  void reset() {
    state = LoginState.initial();
  }
}

/// Provider pour le LoginController.
///
/// Utilise NotifierProvider pour gérer l'état de connexion.
final loginControllerProvider =
    NotifierProvider<LoginController, LoginState>(LoginController.new);
