import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../l10n/app_localizations.dart';

/// Page générique pour afficher une page web externe (CGU, politique de
/// confidentialité, à propos, etc.) sans quitter l'app.
///
/// `webview_flutter` n'a d'implémentation que sur Android/iOS (pas de
/// `webview_flutter_web`, ni de support desktop dans ce projet — voir
/// pubspec.lock) : y afficher une [WebViewPage] sur ces plateformes
/// planterait au runtime. [open] gère donc lui-même la bascule : WebView
/// intégrée sur mobile, ouverture dans le navigateur système ailleurs (sur
/// le web, l'app tourne déjà dans un navigateur, un nouvel onglet est le
/// comportement normal).
///
/// **Utilisation :**
/// ```dart
/// WebViewPage.open(context, url: AppUrls.termsOfService, title: l10n.termsTitle);
/// ```
class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({super.key, required this.url, required this.title});

  /// Point d'entrée unique — à appeler partout où l'app doit afficher une
  /// page web externe.
  static Future<void> open(
    BuildContext context, {
    required String url,
    required String title,
  }) async {
    final canEmbed =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (canEmbed) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WebViewPage(url: url, title: title)),
      );
      return;
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _hasError = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _hasError ? _buildError(context) : _buildWebView(),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              widget.url,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(widget.url),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(AppLocalizations.of(context)!.openInBrowser),
            ),
          ],
        ),
      ),
    );
  }
}
