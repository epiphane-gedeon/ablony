import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Contrôleur pour déclencher le captcha invisible depuis Flutter
class RecaptchaWidgetController {
  void Function()? _executeCaptcha;

  /// Appelé par le widget pour lier la fonction JS
  void bind(void Function() exec) {
    _executeCaptcha = exec;
  }

  /// Méthode à appeler pour déclencher le captcha
  void executeCaptcha() {
    if (_executeCaptcha != null) {
      _executeCaptcha!();
    }
  }
}

/// Widget réutilisable pour afficher Google reCAPTCHA v2.
///
/// Ce widget utilise une WebView pour charger le widget reCAPTCHA
/// de Google et récupérer le token de vérification.
///
/// **Paramètres requis :**
/// - [siteKey] : Votre clé publique reCAPTCHA (obtenue sur Google Cloud Console)
/// - [onVerified] : Callback appelé avec le token quand le captcha est résolu
///
/// **Paramètres optionnels :**
/// - [onError] : Callback appelé en cas d'erreur
/// - [theme] : Thème du captcha ('light' ou 'dark')
///
/// **Exemple d'utilisation :**
/// ```dart
/// RecaptchaWidget(
///   siteKey: 'VOTRE_SITE_KEY',
///   onVerified: (token) {
///     print('Captcha résolu : $token');
///     // Envoyer le token au backend pour vérification
///   },
///   onError: (error) {
///     print('Erreur captcha : $error');
///   },
/// )
/// ```
class RecaptchaWidget extends StatefulWidget {
  /// Clé publique reCAPTCHA (obtenue sur Google Cloud Console)
  final String siteKey;

  /// Callback appelé avec le token quand le captcha est vérifié
  final Function(String token) onVerified;

  /// Callback appelé en cas d'erreur
  final Function(String error)? onError;

  /// Thème du captcha : 'light' ou 'dark'
  final String theme;

  final RecaptchaWidgetController? controller;

  const RecaptchaWidget({
    super.key,
    required this.siteKey,
    required this.onVerified,
    this.onError,
    this.theme = 'light',
    this.controller,
  });

  @override
  State<RecaptchaWidget> createState() => _RecaptchaWidgetState();
}

class _RecaptchaWidgetState extends State<RecaptchaWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!.bind(executeCaptcha);
    }
    _initializeWebView();
  }

  /// Permet de déclencher le captcha invisible depuis Flutter
  void executeCaptcha() {
    _controller.runJavaScript('grecaptcha.execute();');
  }

  /// Initialize la WebView avec le HTML du reCAPTCHA invisible
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'RecaptchaChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_getHtml());
  }

  /// Gère les messages reçus depuis la WebView
  void _handleMessage(String message) {
    if (message.startsWith('TOKEN:')) {
      // Token reCAPTCHA reçu
      final token = message.substring(6);
      widget.onVerified(token);
    } else if (message.startsWith('ERROR:')) {
      // Erreur reCAPTCHA
      final error = message.substring(6);
      if (widget.onError != null) {
        widget.onError!(error);
      }
    }
  }

  /// Génère le HTML pour afficher le reCAPTCHA v2 invisible
  String _getHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  <style>
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background-color: transparent;
    }
    #recaptcha-container {
      display: flex;
      justify-content: center;
      align-items: center;
    }
    #invisible-btn {
      display: none;
    }
  </style>
</head>
<body>
  <div id="recaptcha-container">
    <form id="recaptcha-form" action="javascript:void(0);">
      <button id="invisible-btn" type="submit">Invisible</button>
      <div class="g-recaptcha"
           data-sitekey="${widget.siteKey}"
           data-theme="${widget.theme}"
           data-size="invisible"
           data-callback="onRecaptchaSuccess"
           data-error-callback="onRecaptchaError"
           data-expired-callback="onRecaptchaExpired">
      </div>
    </form>
  </div>

  <script>
    function onRecaptchaSuccess(token) {
      RecaptchaChannel.postMessage('TOKEN:' + token);
    }
    function onRecaptchaError() {
      RecaptchaChannel.postMessage('ERROR:Erreur lors de la vérification');
    }
    function onRecaptchaExpired() {
      RecaptchaChannel.postMessage('ERROR:Le captcha a expiré');
    }
    // Permet d'exécuter le captcha invisible depuis Flutter
    window.executeCaptcha = function() {
      grecaptcha.execute();
    }
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView avec le reCAPTCHA
        WebViewWidget(controller: _controller),

        // Indicateur de chargement
        if (_isLoading) Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
