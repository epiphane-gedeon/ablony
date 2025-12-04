import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subcategory.dart';

/// Modèle Firestore pour Subcategory.
///
/// Gère la conversion entre l'entité Subcategory et les documents Firestore.
class SubcategoryModel {
  /// Convertit un document Firestore en entité Subcategory
  static Subcategory fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Subcategory(
      id: snapshot.id,
      name: data['name'] as String,
      parentId: data['parentId'] as String,
      children: List<String>.from(data['children'] ?? []),
      attributes: List<String>.from(data['attributes'] ?? []),
      order: data['order'] as int?,
      iconUrl: data['iconUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit une entité Subcategory en Map pour Firestore
  static Map<String, dynamic> toFirestore(Subcategory subcategory) {
    return {
      'name': subcategory.name,
      'parentId': subcategory.parentId,
      'children': subcategory.children,
      'attributes': subcategory.attributes,
      'order': subcategory.order,
      'iconUrl': subcategory.iconUrl,
      'isActive': subcategory.isActive,
      'createdAt': Timestamp.fromDate(subcategory.createdAt),
      'updatedAt': Timestamp.fromDate(subcategory.updatedAt),
    };
  }

  /// Crée une entité Subcategory depuis une Map
  static Subcategory fromMap(Map<String, dynamic> data, String id) {
    return Subcategory(
      id: id,
      name: data['name'] as String,
      parentId: data['parentId'] as String,
      children: List<String>.from(data['children'] ?? []),
      attributes: List<String>.from(data['attributes'] ?? []),
      order: data['order'] as int?,
      iconUrl: data['iconUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
