import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category.dart';

/// Modèle Firestore pour Category.
///
/// Gère la conversion entre l'entité Category et les documents Firestore.
class CategoryModel {
  /// Convertit un document Firestore en entité Category
  static Category fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Category(
      id: snapshot.id,
      name: data['name'] as String,
      children: List<String>.from(data['children'] ?? []),
      order: data['order'] as int?,
      iconUrl: data['iconUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit une entité Category en Map pour Firestore
  static Map<String, dynamic> toFirestore(Category category) {
    return {
      'name': category.name,
      'children': category.children,
      'order': category.order,
      'iconUrl': category.iconUrl,
      'isActive': category.isActive,
      'createdAt': Timestamp.fromDate(category.createdAt),
      'updatedAt': Timestamp.fromDate(category.updatedAt),
    };
  }

  /// Crée une entité Category depuis une Map
  static Category fromMap(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: data['name'] as String,
      children: List<String>.from(data['children'] ?? []),
      order: data['order'] as int?,
      iconUrl: data['iconUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
