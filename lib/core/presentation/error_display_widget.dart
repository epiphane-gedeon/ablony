/// Fichier: core/presentation/error_display_widget.dart
/// Description: Widgets réutilisables pour afficher les erreurs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_handler.dart';

/// Widget pour afficher une erreur avec retry
class ErrorDisplay extends StatelessWidget {
  final Exception error;
  final VoidCallback? onRetry;
  final Widget? icon;

  const ErrorDisplay({super.key, required this.error, this.onRetry, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'erreur
            icon ??
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),

            // Titre
            Text(
              ErrorHandler.getErrorTitle(error),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message d'erreur
            Text(
              ErrorHandler.getErrorMessage(error),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Bouton Réessayer (si disponible et retryable)
            if (onRetry != null && error.canRetry)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),

            // Bouton Fermer / OK
            if (onRetry == null || !error.canRetry)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher les erreurs de chargement
class ErrorLoadingWidget extends StatelessWidget {
  final Exception error;
  final VoidCallback onRetry;

  const ErrorLoadingWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ErrorDisplay(
        error: error,
        onRetry: onRetry,
        icon: const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.red),
      ),
    );
  }
}

/// Widget pour afficher un message d'erreur compacte
class CompactErrorBanner extends StatelessWidget {
  final Exception error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const CompactErrorBanner({
    super.key,
    required this.error,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ErrorHandler.getErrorTitle(error),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.red[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ErrorHandler.getErrorMessage(error),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onRetry != null && error.canRetry)
            TextButton(onPressed: onRetry, child: const Text('Réessayer'))
          else if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}

/// Extension pratique sur AsyncValue de Riverpod
extension AsyncValueErrorDisplay on AsyncValue {
  /// Widget pour afficher une erreur ou le contenu
  Widget whenErrorOrLoading<T>({
    required Widget Function(T data) builder,
    required VoidCallback onRetry,
    Widget? loadingWidget,
  }) {
    return when(
      loading: () =>
          loadingWidget ?? const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          ErrorDisplay(error: error as Exception, onRetry: onRetry),
      data: (data) => builder(data as T),
    );
  }
}
