# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Ablony is a Flutter marketplace app (C2C second-hand goods, Vinted-style) targeting Togo and Benin. Flutter/Dart frontend (Android/iOS/Web/desktop) backed by Firebase (Firestore, Auth, Storage, App Check) plus a small Node.js Cloud Functions backend in `functions/` for payments and reCAPTCHA verification.

## Commands

```bash
# Install deps
flutter pub get

# Regenerate localizations after editing lib/l10n/*.arb (required before those keys compile)
flutter gen-l10n

# Run app
flutter run
flutter run -d <device-id>

# Lint / static analysis (uses flutter_lints via analysis_options.yaml)
flutter analyze
dart fix --apply

# Tests — there is no test/ directory and no tests currently exist in this repo

# Build
flutter build apk
flutter build ios
flutter build web

# Firebase emulators (Auth :9099, Firestore :8080, Storage :9199, Functions :5001, UI :4001)
firebase emulators:start

# Deploy
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions
firebase functions:log
```

Cloud Functions (`functions/`, Node 22):
```bash
cd functions
npm run lint     # eslint .
npm run serve    # firebase emulators:start --only functions
npm run deploy
npm run logs
```

Firebase project: `ablony-a5db9`, region `europe-west1` (Firestore) / `us-central1` (functions, per `firebase_options.dart` comment — verify with `firebase functions:log` if uncertain).

## Architecture

### Feature-driven Clean Architecture

Each module under `lib/features/<name>/` is layered independently:
- `domain/` — pure Dart entities and repository interfaces (no Flutter/Firebase imports)
- `data/` — models + repository implementations (Firebase calls live here)
- `application/` — Riverpod providers / state notifiers (business logic orchestration)
- `presentation/` — pages and widgets

Not every feature has all four layers (many are UI-only, e.g. `sell`, `messages` are partly placeholder). `lib/features/auth/` and `lib/features/product/` are the most complete reference implementations for the full-layer pattern.

`lib/core/` holds cross-cutting infrastructure: `config/` (Firebase emulator toggle), `exceptions/`, `navigation/` (GoRouter setup), `providers/` (global Riverpod providers: theme, locale, auth state), `theme/`, `layout/` (bottom-nav shell), `services/` (e.g. `payment_service.dart`).

`lib/shared/widgets/` holds cross-feature reusable UI (buttons, `product_card.dart`, inputs, filter chips).

### Navigation (`lib/core/navigation/app_router.dart`)

GoRouter with a single global `redirect` function driven by `authStateProvider` (Firebase auth stream) and `isProfileCompleteProvider` (username + country set). Three states drive redirection: unauthenticated → `/onboarding`; authenticated + incomplete profile → forced onto `/auth/username` or `/auth/country`; authenticated + complete → bounced off onboarding/auth/splash to `/home`. The `redirect` fires only via `refreshListenable: notifier` (a `RouterNotifier`), not on every navigation. Main app screens (`/home`, `/search`, `/sell`, `/messages`, `/profile`) live inside a `StatefulShellRoute.indexedStack` for persistent bottom-nav state; `/sell` itself is a no-op route — actual sell UI is a bottom sheet (`sell_bottom_sheet.dart`), not a page.

### State management

Riverpod throughout: `Provider` for repository/service instances, `FutureProvider` for one-shot async reads, `StreamProvider` for realtime Firestore listeners, `StateNotifierProvider` for mutable flow state (e.g. registration, paginated product lists).

### Error handling

All thrown errors should be typed `AppException` subclasses from `lib/core/exceptions/` (hierarchy: `AuthException`, `ProductException`, `DatabaseException`, `StorageException`, each with specific subtypes like `UsernameTakenException`, `ProductNotFoundException`, `NetworkException`). Repositories catch `FirebaseException` and convert via `handleFirebaseException()`; never throw a bare `Exception()`. Exceptions carry `.userMessage` (localized) and `.technicalMessage`, and expose `.showAsSnackBar(context)` / `.showAsDialog(context)` for UI display. See `GESTION_EXCEPTIONS.md` for the full pattern and examples.

### Firestore data model

Top-level collections: `users`, `products`, `categories` (nested `subcategories` with dynamic per-category `attributes` map), `usernames` (uniqueness reservation, written transactionally alongside user creation), `messages/{conversationId}` (subcollection of messages), `reviews`. Security rules in `firestore.rules` enforce: public read on users/products/categories, owner-only writes, participant-only access on messages, field-level validation (e.g. price > 0, 1–6 images). Composite indexes are declared in `firestore.indexes.json` — new compound queries (e.g. filter + orderBy) need a matching index added there before they'll work against production.

### Payments

`lib/core/services/payment_service.dart` calls two deployed 2nd-gen Cloud Run HTTPS functions directly by URL (not via the Firebase Functions SDK): `initiatePayment` and `confirmPayment`. Both are implemented in `functions/index.js` alongside `geniusPayWebhook`, wrapping the GeniusPay payment provider (sandbox/live keys read from `functions/.env`, gitignored). `confirmPayment` is responsible for debiting the buyer wallet, crediting the seller's `pendingAmount`, and marking the product sold — treat it as the source of truth for transaction finalization, not the client.

### Localization

`lib/l10n/app_fr.arb` (template/default) and `app_en.arb`. Always reference strings via `AppLocalizations.of(context)!.key`, never hardcode UI text. Add new keys to both ARB files, then run `flutter gen-l10n` to regenerate `lib/l10n/generated/app_localizations.dart` before referencing a new key in code.

### Firebase emulators vs production

`lib/core/config/firebase_config.dart` gates emulator usage (`FirebaseConfig.useEmulators`, currently hardcoded `false`) and provides platform-specific emulator hosts (Android emulator needs `10.0.2.2`, not `localhost`). Flip this when developing against local emulators.
