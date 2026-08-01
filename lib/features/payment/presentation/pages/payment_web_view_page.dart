import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Page affichant le formulaire de paiement sécurisé (carte bancaire) dans une WebView in-app
class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const PaymentWebViewPage({
    super.key,
    required this.url,
    this.title = 'Paiement sécurisé par carte',
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
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
