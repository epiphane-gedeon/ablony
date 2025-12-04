import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';

/// Types de champs de saisie prédéfinis.
/// Détermine automatiquement le type de clavier et les options de validation.
enum InputType {
  /// Texte standard (nom, prénom, etc.)
  text,

  /// Adresse email avec clavier email et validation
  email,

  /// Mot de passe (masqué avec option de visibilité)
  password,

  /// Numéro de téléphone avec clavier numérique
  phone,

  /// Nombre avec clavier numérique
  number,

  /// URL avec clavier URL
  url,

  /// Texte multiligne (description, commentaire)
  multiline,
}

/// Widget réutilisable pour les champs de saisie (TextField/TextFormField).
///
/// Ce widget encapsule un TextFormField avec un style cohérent dans toute l'app.
/// Il permet de personnaliser l'apparence et le comportement du champ.
///
/// **Fonctionnalités :**
/// - Label personnalisable
/// - Placeholder (hintText)
/// - Validation avec message d'erreur
/// - Styles personnalisables (couleurs, bordures, etc.)
/// - Support des icônes (prefix et suffix)
/// - Gestion du focus
/// - Support du mot de passe (obscureText)
/// - Limite de caractères
///
/// **Exemple d'utilisation :**
/// ```dart
/// Input(
///   label: 'Nom d\'utilisateur',
///   placeholder: 'john-doe',
///   controller: _usernameController,
///   validator: (value) {
///     if (value == null || value.isEmpty) {
///       return 'Champ obligatoire';
///     }
///     return null;
///   },
///   onChanged: (value) => print(value),
/// )
/// ```
class Input extends StatefulWidget {
  /// Type du champ de saisie (texte, email, password, etc.)
  /// Détermine automatiquement le clavier et les options.
  final InputType type;

  /// Libellé affiché au-dessus du champ.
  final String? label;

  /// Texte d'aide affiché dans le champ vide (placeholder).
  final String? placeholder;

  /// Contrôleur pour gérer le texte du champ.
  final TextEditingController? controller;

  /// Fonction de validation du champ.
  /// Retourne null si valide, sinon retourne le message d'erreur.
  final String? Function(String?)? validator;

  /// Callback appelé à chaque changement de texte.
  final void Function(String)? onChanged;

  /// Callback appelé quand l'utilisateur soumet le champ (touche Entrée).
  final void Function(String)? onSubmitted;

  /// Rayon des coins des bordures (en pixels).
  final double borderRadius;

  /// Couleur du texte saisi.
  final Color? textColor;

  /// Couleur de la bordure normale (non focus).
  final Color? borderColor;

  /// Couleur de la bordure en focus.
  final Color? focusedBorderColor;

  /// Couleur de la bordure en cas d'erreur.
  final Color? errorBorderColor;

  /// Couleur de fond du champ.
  final Color? fillColor;

  /// Message d'erreur à afficher (si non null, le champ est en erreur).
  /// Alternative à la validation via validator.
  final String? errorLabel;

  /// Icône affichée au début du champ (à gauche).
  final Widget? prefixIcon;

  /// Icône affichée à la fin du champ (à droite).
  final Widget? suffixIcon;

  /// Action du bouton du clavier (Suivant, Terminé, etc.).
  final TextInputAction? textInputAction;

  /// Masquer le texte (pour les mots de passe).
  final bool obscureText;

  /// Activer/désactiver le champ.
  final bool enabled;

  /// Activer/désactiver la correction automatique.
  final bool autocorrect;

  /// Activer/désactiver les suggestions.
  final bool enableSuggestions;

  /// Nombre maximum de lignes (1 = une ligne, null = illimité).
  final int? maxLines;

  /// Nombre maximum de caractères.
  final int? maxLength;

  /// Afficher le compteur de caractères.
  final bool showCounter;

  /// Liste de formateurs d'entrée (pour filtrer/formater le texte).
  final List<TextInputFormatter>? inputFormatters;

  /// Padding interne du champ.
  final EdgeInsets? contentPadding;

  /// Taille de la police du texte.
  final double? fontSize;

  /// Style du label.
  final TextStyle? labelStyle;

  /// Style du placeholder.
  final TextStyle? placeholderStyle;

  /// Activer la validation automatique selon le type (email, phone, etc.).
  /// Si true et qu'aucun validator n'est fourni, un validateur par défaut
  /// sera appliqué selon le type du champ.
  final bool autoValidate;

  const Input({
    super.key,
    this.type = InputType.text,
    this.label,
    this.placeholder,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.borderRadius = 12,
    this.textColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.fillColor,
    this.errorLabel,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.inputFormatters,
    this.contentPadding,
    this.fontSize,
    this.labelStyle,
    this.placeholderStyle,
    this.autoValidate = true,
  });

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  /// Gère la visibilité du mot de passe
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    // Masquer le texte par défaut si c'est un password
    _obscureText = widget.type == InputType.password || widget.obscureText;
  }

  /// Détermine le type de clavier selon le type du champ
  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case InputType.email:
        return TextInputType.emailAddress;
      case InputType.phone:
        return TextInputType.phone;
      case InputType.number:
        return TextInputType.number;
      case InputType.url:
        return TextInputType.url;
      case InputType.multiline:
        return TextInputType.multiline;
      case InputType.text:
      case InputType.password:
        return TextInputType.text;
    }
  }

  /// Détermine le nombre de lignes selon le type
  int? _getMaxLines() {
    if (widget.maxLines != null) return widget.maxLines;
    return widget.type == InputType.multiline ? null : 1;
  }

  /// Retourne le validateur automatique selon le type du champ
  /// Utilisé uniquement si autoValidate est true et qu'aucun validator custom n'est fourni
  String? Function(String?)? _getAutoValidator() {
    if (!widget.autoValidate) return null;

    switch (widget.type) {
      case InputType.email:
        return Validators.email;
      case InputType.phone:
        return Validators.phone;
      case InputType.url:
        return Validators.url;
      case InputType.number:
        return (value) => Validators.number(value);
      case InputType.password:
        return Validators.password;
      case InputType.text:
      case InputType.multiline:
        // Pas de validation automatique pour le texte libre
        return null;
    }
  }

  /// Crée l'icône de suffixe (ex: bouton pour afficher/masquer le password)
  Widget? _getSuffixIcon() {
    if (widget.suffixIcon != null) return widget.suffixIcon;

    // Bouton pour afficher/masquer le mot de passe
    if (widget.type == InputType.password) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs par défaut depuis le thème
    final defaultTextColor = widget.textColor ?? Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final defaultBorderColor = widget.borderColor ?? Theme.of(context).dividerColor;
    final defaultFocusedBorderColor =
        widget.focusedBorderColor ?? Theme.of(context).colorScheme.primary;
    final defaultErrorBorderColor = widget.errorBorderColor ?? Theme.of(context).colorScheme.error;
    final defaultFillColor = widget.fillColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ============================================================
        // LABEL (SI FOURNI)
        // ============================================================
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style:
                widget.labelStyle ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: defaultTextColor,
                ),
          ),
          const SizedBox(height: 8),
        ],

        // ============================================================
        // CHAMP DE SAISIE
        // ============================================================
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _obscureText,
          keyboardType: _getKeyboardType(),
          textInputAction: widget.textInputAction,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          maxLines: _getMaxLines(),
          maxLength: widget.showCounter ? widget.maxLength : null,
          inputFormatters: widget.inputFormatters,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: defaultTextColor,
            fontSize: widget.fontSize,
          ),
          decoration: InputDecoration(
            // Placeholder
            hintText: widget.placeholder,
            hintStyle:
                widget.placeholderStyle ??
                TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: widget.fontSize,
                ),

            // Icônes
            prefixIcon: widget.prefixIcon,
            suffixIcon: _getSuffixIcon(),

            // Remplissage
            filled: true,
            fillColor: widget.enabled ? defaultFillColor : Colors.grey.shade100,

            // Message d'erreur personnalisé
            errorText: widget.errorLabel,
            errorStyle: TextStyle(color: defaultErrorBorderColor, fontSize: 12),
            errorMaxLines: 3, // Permet d'afficher les messages d'erreur sur plusieurs lignes

            // Padding interne
            contentPadding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            // Compteur de caractères
            counterText: widget.showCounter ? null : '',

            // ============================================================
            // BORDURES
            // ============================================================

            // Bordure normale
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: defaultBorderColor),
            ),

            // Bordure activée (enabled)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: defaultBorderColor),
            ),

            // Bordure en focus
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: defaultFocusedBorderColor,
                width: 2,
              ),
            ),

            // Bordure d'erreur
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: defaultErrorBorderColor),
            ),

            // Bordure d'erreur en focus
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: defaultErrorBorderColor, width: 2),
            ),

            // Bordure désactivée
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),

          // ============================================================
          // CALLBACKS
          // ============================================================
          validator: widget.validator ?? _getAutoValidator(),
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
        ),
      ],
    );
  }
}
