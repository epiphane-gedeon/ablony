import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../l10n/app_localizations.dart';

/// Conduit l'utilisateur jusqu'au paiement, par le chemin que la plateforme
/// permet.
///
/// Sur mobile, la page de paiement s'ouvre dans une WebView intégrée et l'on
/// suit les redirections pour savoir si ça a abouti.
///
/// Sur le **web**, cette WebView n'existe pas : `webview_flutter` ne déclare
/// qu'Android, iOS et macOS. Le composant s'y affichait donc comme un écran
/// gris vide, et le paiement était impossible depuis un navigateur. On y ouvre
/// la page de paiement dans un nouvel onglet, et on **surveille la transaction
/// en base** : c'est le serveur qui dit si elle a abouti, prévenu par le
/// webhook de GeniusPay. Cela vaut mieux que de se fier au retour de
/// l'utilisateur, qui peut fermer l'onglet à tout moment.
class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String title;

  /// Référence de la transaction à surveiller. Indispensable sur le web, où
  /// l'on ne peut pas observer la navigation de l'onglet ouvert.
  final String? reference;

  const PaymentWebViewPage({
    super.key,
    required this.url,
    this.reference,
    this.title = 'Paiement sécurisé par carte',
  });

  @override
  State<PaymentWebViewPage> createState() =>
      kIsWeb ? _PaiementWebState() : _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Détecter les URLs de callback/redirection de GeniusPay ou Paystack
            // afin de fermer automatiquement la WebView avec le bon résultat.
            if (url.contains('success') || url.contains('completed') || url.contains('callback')) {
              Navigator.of(context).pop(true);
            } else if (url.contains('cancel') || url.contains('failed') || url.contains('error')) {
              Navigator.of(context).pop(false);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('[WebView] Navigation détectée : $url');
            if (url.contains('success') || url.contains('completed') || url.contains('callback')) {
              debugPrint('[WebView] Succès détecté via URL');
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            } else if (url.contains('cancel') || url.contains('failed') || url.contains('error')) {
              debugPrint('[WebView] Annulation/Échec détecté via URL');
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web Resource Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

/// Le parcours de paiement sur navigateur : un onglet, et l'attente du verdict
/// du serveur.
class _PaiementWebState extends State<PaymentWebViewPage> {
  String? _erreur;

  bool _tentativeAutomatique = false;

  /// Au-delà de ce délai sans confirmation, on cesse de faire tourner un
  /// sablier et on explique. Quinze minutes de spinner après un débit, c'est
  /// ce qui fait conclure à un vol — alors que l'argent est simplement en
  /// cours de vérification.
  static const Duration _patience = Duration(seconds: 75);
  Timer? _minuterie;
  bool _tropLong = false;

  @override
  void initState() {
    super.initState();
    _minuterie = Timer(_patience, () {
      if (mounted) setState(() => _tropLong = true);
    });
    // On tente l'ouverture automatique, sans compter dessus : la demande de
    // paiement est asynchrone, donc au moment où l'on arrive ici le clic de
    // l'utilisateur est déjà « consommé » et le navigateur considère la
    // fenêtre comme non sollicitée. Elle est alors bloquée en silence — c'est
    // exactement ce qui donnait l'impression que rien ne se passait.
    //
    // D'où le bouton bien visible ci-dessous : un clic dessus est un geste
    // utilisateur incontestable, qu'aucun navigateur ne bloque.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tentativeAutomatique = true;
      _ouvrirPaiement(silencieux: true);
    });
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  Future<void> _ouvrirPaiement({bool silencieux = false}) async {
    try {
      final ok = await launchUrl(
        Uri.parse(widget.url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted && !silencieux) {
        setState(() => _erreur = AppLocalizations.of(context)!.paymentOpenFailed);
      }
    } catch (e) {
      if (mounted && !silencieux) {
        setState(() => _erreur = AppLocalizations.of(context)!.paymentOpenFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reference = widget.reference;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (reference == null)
                  // Sans référence, rien à surveiller : on se rabat sur la
                  // confirmation manuelle plutôt que d'attendre indéfiniment.
                  _enAttente(l10n, theme, surveille: false)
                else
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .doc(reference)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final statut = snapshot.data?.data()?['status'];
                      if (statut == 'completed' || statut == 'failed') {
                        // Le serveur a tranché : on referme avec son verdict.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.of(context).pop(statut == 'completed');
                          }
                        });
                      }
                      return _enAttente(l10n, theme, surveille: true);
                    },
                  ),
                if (_erreur != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _erreur!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _ouvrirPaiement(),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      _tentativeAutomatique
                          ? l10n.paymentOpenPage
                          : l10n.paymentReopen,
                    ),
                  ),
                ),
                if (_tropLong)
                  TextButton.icon(
                    // Le recours, à portée de main au moment précis où l'on
                    // doute d'avoir été volé. L'envoyer chercher une adresse
                    // e-mail à cet instant, c'est le perdre.
                    onPressed: () {
                      final ref = widget.reference;
                      Navigator.of(context).pop(false);
                      context.pushNamed(
                        'support',
                        extra: ref == null
                            ? null
                            : l10n.supportPaymentPrefill(ref),
                      );
                    },
                    icon: const Icon(Icons.support_agent_outlined, size: 18),
                    label: Text(l10n.supportOpen),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  // « Annuler » serait mensonger une fois le débit passé : on
                  // ne peut plus rien annuler, seulement refermer l'écran.
                  child: Text(_tropLong ? l10n.paymentClose : l10n.paymentCancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _enAttente(
    AppLocalizations l10n,
    ThemeData theme, {
    required bool surveille,
  }) {
    // Passé le délai de patience, on change de discours. Un sablier qui tourne
    // indéfiniment après un débit ne dit rien à personne — sinon que l'argent
    // est parti sans contrepartie. Ici on nomme ce qui se passe, on dit que
    // rien n'est perdu, et on donne la référence à citer.
    if (_tropLong) return _enVerification(l10n, theme);

    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          l10n.paymentWaitingTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          surveille ? l10n.paymentWaitingBody : l10n.paymentWaitingBodyManual,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ],
    );
  }

  /// L'écran de la longue attente : rassurant, et utile.
  Widget _enVerification(AppLocalizations l10n, ThemeData theme) {
    final reference = widget.reference;

    return Column(
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 44,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.paymentVerifyingTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.paymentVerifyingBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.paymentVerifyingDelay,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        if (reference != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                SelectableText(
                  l10n.paymentReference(reference),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.paymentKeepReference,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
