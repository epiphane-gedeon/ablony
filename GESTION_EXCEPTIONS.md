## 🎯 Système de Gestion des Exceptions - Guide d'utilisation

### 📁 Structure des fichiers

```
lib/core/
├── exceptions/
│   ├── app_exceptions.dart       # Classes d'exceptions personnalisées
│   └── exceptions.dart           # Barrel file (export)
├── presentation/
│   ├── error_handler.dart        # Utilitaires pour afficher les erreurs
│   └── error_display_widget.dart # Widgets réutilisables
└── providers/
    └── error_logger.dart         # Service de logging des erreurs
```

---

### 🚀 Utilisation

#### 1️⃣ **Exceptions personnalisées dans les repositories**

```dart
// ✅ BON - Utiliser les exceptions spécifiques
if (!isAvailable) {
  throw UsernameTakenException(username: username);
}

try {
  // ...
} on FirebaseException catch (e, stackTrace) {
  throw handleFirebaseException(e, stackTrace: stackTrace);
} catch (e, stackTrace) {
  throw UnknownException(
    message: 'Erreur lors de...',
    originalException: e as Exception?,
    stackTrace: stackTrace,
  );
}

// ❌ MAUVAIS - Utiliser Exception générique
throw Exception('Username déjà utilisé');
```

#### 2️⃣ **Afficher les erreurs dans l'UI**

```dart
// Option 1: SnackBar
error.showAsSnackBar(context);

// Option 2: Dialogue
await error.showAsDialog(context, onRetry: () {
  // Réessayer l'action
});

// Option 3: Widget personnalisé
ErrorDisplay(
  error: error,
  onRetry: () => ref.refresh(productsProvider),
)

// Option 4: Utiliser ErrorHandler directement
ErrorHandler.showError(context, error);
```

#### 3️⃣ **Utiliser dans les providers Riverpod**

```dart
final productsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    return await ref.watch(productRepositoryProvider).getProducts();
  } on ProductNotFoundException catch (e) {
    // Traiter spécifiquement
    throw e;
  } on AppException {
    // Propager (UI gère l'affichage)
    rethrow;
  }
});

// Dans le widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  return ref.watch(productsProvider).when(
    loading: () => const CircularProgressIndicator(),
    error: (error, stackTrace) => ErrorDisplay(
      error: error as Exception,
      onRetry: () => ref.refresh(productsProvider),
    ),
    data: (products) => ListView(
      children: products.map((p) => ProductTile(product: p)).toList(),
    ),
  );
}
```

#### 4️⃣ **Logging des erreurs**

```dart
try {
  // ...
} catch (e, stackTrace) {
  final error = UnknownException(
    message: 'Erreur',
    originalException: e as Exception?,
    stackTrace: stackTrace,
  );
  
  // Log dans la console (debug) et envoyer à service (prod)
  await ErrorLogger.logException(
    error,
    stackTrace: stackTrace,
    context: {
      'userId': currentUser.id,
      'route': '/products',
      'action': 'getProducts',
    },
  );
}
```

#### 5️⃣ **Obtenir des infos sur l'erreur**

```dart
Exception error = UsernameTakenException(username: 'john');

// Titre
print(error.getTitle()); // "Pseudo non disponible"

// Message
print(error.getErrorMessage()); // "Le pseudo \"john\" est déjà utilisé"

// Code d'erreur
print(error.getCode()); // "USERNAME_TAKEN"

// Vérifie si c'est une erreur critique
if (error.isCritical) {
  // Déconnecter l'utilisateur
}

// Vérifie si on peut réessayer
if (error.canRetry) {
  // Afficher un bouton "Réessayer"
}
```

---

### 📋 Hiérarchie des Exceptions

```
AppException (base)
├── AuthException
│   ├── NotAuthenticatedException
│   ├── InvalidCredentialsException
│   ├── UsernameTakenException
│   ├── EmailAlreadyUsedException
│   ├── WeakPasswordException
│   ├── UserDisabledException
│   └── IncompleteProfileException
│
├── ProductException
│   ├── ProductNotFoundException
│   ├── ProductAccessDeniedException
│   ├── InvalidProductDataException
│   ├── InvalidPriceException
│   ├── InvalidImagesException
│   ├── CategoryNotFoundException
│   └── ProductAlreadySoldException
│
├── DatabaseException
│   ├── NetworkException
│   ├── TimeoutException
│   ├── PermissionDeniedException
│   └── QuotaExceededException
│
├── StorageException
│   ├── FileTooLargeException
│   └── UnsupportedFormatException
│
├── ValidationException
│   ├── RequiredFieldException
│   └── InvalidFormatException
│
└── UnknownException
```

---

### 🔧 Créer une nouvelle exception

```dart
// Dans app_exceptions.dart

class MyCustomException extends ProductException {
  final String details;

  MyCustomException({
    required this.details,
    Exception? originalException,
    StackTrace? stackTrace,
  }) : super(
    message: 'Description de l\'erreur: $details',
    code: 'MY_CUSTOM_ERROR',
    originalException: originalException,
    stackTrace: stackTrace,
  );
}

// Utilisation
if (someCondition) {
  throw MyCustomException(details: 'Mon détail');
}
```

---

### 💡 Bonnes pratiques

✅ **À FAIRE**
- Utiliser les exceptions spécifiques appropriées
- Toujours capturer la `StackTrace` et la passer aux exceptions
- Afficher les erreurs `AppException.message` à l'utilisateur
- Utiliser `ErrorHandler.showError()` ou `.showAsSnackBar()`
- Logger les erreurs pour le debugging
- Implémenter des retry pour les erreurs "retryable"

❌ À ÉVITER
- Utiliser `Exception()` générique
- Jeter des exceptions sans `StackTrace`
- Afficher `FirebaseException` directement à l'utilisateur
- Oublier de logger les erreurs
- Afficher des messages techniques aux utilisateurs

---

### 📱 Exemple complet

```dart
// features/product/presentation/products_page.dart

class ProductsPage extends ConsumerWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) {
        // Logger l'erreur
        ErrorLogger.logException(error as Exception, stackTrace: stackTrace);
        
        return Scaffold(
          body: ErrorDisplay(
            error: error as Exception,
            onRetry: () => ref.refresh(productsProvider),
          ),
        );
      },
      data: (products) => Scaffold(
        appBar: AppBar(title: const Text('Produits')),
        body: products.isEmpty
            ? const Center(child: Text('Aucun produit'))
            : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) => ProductTile(
                  product: products[index],
                  onError: (error) => error.showAsSnackBar(context),
                ),
              ),
      ),
    );
  }
}
```

---

### 🔍 Debugging

Pour voir les erreurs détaillées en console, utilisez:

```dart
error.log(); // Affiche toute l'information disponible

// Ou manuellement
ErrorLogger._logToConsole(error, error.stackTrace);
```

Cela affichera:
```
╔════════════════════════════════════════════════════════════╗
║ ❌ ERREUR APPLICATIVE                                      ║
╠════════════════════════════════════════════════════════════╣
║ Type: UsernameTakenException
║ Code: USERNAME_TAKEN
║ Message: Le pseudo "john" est déjà utilisé
║ Cause: PlatformException(already_exists, ...)
║
║ Stack Trace:
║   #0   AuthRepositoryImpl.completeUserProfile
║   #1   AuthProvider.completeProfile
║   ...
╚════════════════════════════════════════════════════════════╝
```
