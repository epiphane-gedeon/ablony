import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ablony/features/product/data/repositories/category_repository_impl.dart';
import 'package:ablony/features/product/domain/repositories/category_repository.dart';
import 'package:ablony/features/product/domain/entities/category.dart';
import 'package:ablony/features/product/domain/entities/subcategory.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final subcategoriesProvider = FutureProvider.family<List<Subcategory>, String>((ref, String parentId) async {
  return ref.watch(categoryRepositoryProvider).getSubcategoriesByParent(parentId);
});
