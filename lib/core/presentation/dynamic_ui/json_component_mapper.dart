import 'package:flutter/material.dart';
import 'package:ablony/shared/widgets/input.dart';

/// Helper to map JSON strings to Dart/Flutter objects
class JsonComponentMapper {
  static IconData getIcon(String? iconName) {
    switch (iconName) {
      case 'euro':
        return Icons.euro;
      case 'search':
        return Icons.search;
      case 'person':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  static InputType getInputType(String? typeName) {
    switch (typeName) {
      case 'number':
        return InputType.number;
      case 'email':
        return InputType.email;
      case 'phone':
        return InputType.phone;
      case 'multiline':
        return InputType.multiline;
      default:
        return InputType.text;
    }
  }
}
