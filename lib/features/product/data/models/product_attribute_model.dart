import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_attribute.dart';

/// Modèle Firestore pour ProductAttribute.
///
/// Gère la conversion entre l'entité ProductAttribute et les documents Firestore.
class ProductAttributeModel {
  /// Convertit un document Firestore en entité ProductAttribute
  static ProductAttribute fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return ProductAttribute(
      id: snapshot.id,
      name: data['name'] as String,
      type: _parseAttributeType(data['type'] as String),
      values: List<String>.from(data['values'] ?? []),
      isRequired: data['isRequired'] as bool? ?? false,
      helpText: data['helpText'] as String?,
      order: data['order'] as int?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit une entité ProductAttribute en Map pour Firestore
  static Map<String, dynamic> toFirestore(ProductAttribute attribute) {
    return {
      'name': attribute.name,
      'type': _attributeTypeToString(attribute.type),
      'values': attribute.values,
      'isRequired': attribute.isRequired,
      'helpText': attribute.helpText,
      'order': attribute.order,
      'isActive': attribute.isActive,
      'createdAt': Timestamp.fromDate(attribute.createdAt),
      'updatedAt': Timestamp.fromDate(attribute.updatedAt),
    };
  }

  /// Crée une entité ProductAttribute depuis une Map
  static ProductAttribute fromMap(Map<String, dynamic> data, String id) {
    return ProductAttribute(
      id: id,
      name: data['name'] as String,
      type: _parseAttributeType(data['type'] as String),
      values: List<String>.from(data['values'] ?? []),
      isRequired: data['isRequired'] as bool? ?? false,
      helpText: data['helpText'] as String?,
      order: data['order'] as int?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Parse le type d'attribut depuis une string
  static AttributeType _parseAttributeType(String type) {
    switch (type) {
      case 'select':
        return AttributeType.select;
      case 'multiSelect':
        return AttributeType.multiSelect;
      case 'text':
        return AttributeType.text;
      case 'number':
        return AttributeType.number;
      case 'boolean':
        return AttributeType.boolean;
      default:
        return AttributeType.select;
    }
  }

  /// Convertit le type d'attribut en string
  static String _attributeTypeToString(AttributeType type) {
    switch (type) {
      case AttributeType.select:
        return 'select';
      case AttributeType.multiSelect:
        return 'multiSelect';
      case AttributeType.text:
        return 'text';
      case AttributeType.number:
        return 'number';
      case AttributeType.boolean:
        return 'boolean';
    }
  }
}
