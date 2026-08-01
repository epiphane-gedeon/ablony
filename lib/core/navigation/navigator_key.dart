import 'package:flutter/widgets.dart';

/// Clé de navigation racine, utilisée pour naviguer ou afficher une
/// notification (SnackBar) depuis en dehors de l'arbre de widgets
/// (ex : handlers de notifications push FCM).
final rootNavigatorKey = GlobalKey<NavigatorState>();
