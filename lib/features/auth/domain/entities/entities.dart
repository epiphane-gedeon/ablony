/// Barrel file pour les entités du domaine auth
///
/// Ce fichier permet d'importer toutes les entités en une seule ligne :
/// ```dart
/// import 'package:ablony/features/auth/domain/entities/entities.dart';
/// ```
///
/// Au lieu de :
/// ```dart
/// import 'package:ablony/features/auth/domain/entities/user.dart';
/// import 'package:ablony/features/auth/domain/entities/auth_provider.dart';
/// import 'package:ablony/features/auth/domain/entities/country.dart';
/// ```

export 'auth_provider.dart';
export 'country.dart';
export 'user.dart';
