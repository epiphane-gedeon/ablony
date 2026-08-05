import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/dynamic_ui/dynamic_selection_view.dart';
import '../../../../core/presentation/pages/selection_screen.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/utils/category_translator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../product/presentation/providers/category_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';

/// Page de recherche et navigation dans les catégories. principales et offre
/// un raccourci vers la fonctionnalité de saisie texte.
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header / Fausse barre de recherche
            GestureDetector(
              onTap: () {
                context.push('/searching');
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.searchPlaceholder,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Grille des catégories
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.errorGenericMsg(error.toString()),
                  ),
                ),
                data: (categories) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final gridWidth = constraints.maxWidth > ContentWidth.grid
                          ? ContentWidth.grid
                          : constraints.maxWidth;

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ContentWidth.grid,
                          ),
                          child: GridView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.pagePadding,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      ResponsiveGrid.categoryColumns(gridWidth),
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.2,
                                ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final translatedName =
                                  CategoryTranslator.translate(
                                    l10n,
                                    category.id,
                                    category.name,
                                  );

                              return InkWell(
                                onTap: () => _openCategorySelection(
                                  context,
                                  ref,
                                  category.id,
                                  translatedName,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[900]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.dividerColor.withOpacity(
                                        0.05,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        translatedName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Recherche récursive du nom de catégorie par ID pour l'affichage final
  Future<String?> _findCategoryName(
    WidgetRef ref,
    String categoryId,
    String? parentId,
  ) async {
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final subcats = await categoryRepo.getSubcategoriesByParent(parentId ?? '');

    for (final subcat in subcats) {
      if (subcat.id == categoryId) {
        return subcat.name;
      }
      if (subcat.isBranch) {
        final foundName = await _findCategoryName(ref, categoryId, subcat.id);
        if (foundName != null) {
          return foundName;
        }
      }
    }
    return null;
  }

  void _openCategorySelection(
    BuildContext context,
    WidgetRef ref,
    String parentId,
    String parentName,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final config = {
      'type': 'list',
      'dataSource': 'subcategories',
      'fetchParam': parentId,
      'parentName': parentName,
      'itemKey': 'id',
      'itemLabel': 'name',
      'nextAction': 'navigate_recursive',
      'multiSelect': true,
      'maxSelection': 1, // Comportement Radio button
      'showAllOption': true, // Afficher "Tous"
    };

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/category-search'),
        builder: (context) => SelectionScreen(
          title: parentName,
          content: DynamicSelectionView(
            config: config,
            dataSources: {
              'subcategories': (pId) async {
                final subcats = await ref
                    .read(categoryRepositoryProvider)
                    .getSubcategoriesByParent(pId ?? '');
                return subcats
                    .map(
                      (sub) => {
                        'id': sub.id,
                        'name': CategoryTranslator.translate(
                          l10n,
                          sub.id,
                          sub.name,
                        ),
                        'hasChildren': sub.isBranch,
                      },
                    )
                    .toList();
              },
            },
            onResult: (res) {
              if (res != null && res['selectedIds'] != null) {
                Navigator.of(context).pop(res);
              }
            },
          ),
        ),
      ),
    );

    if (result != null) {
      String finalCategoryId = parentId;
      String finalCategoryName = parentName;

      if (result['selectedIds'] != null) {
        final selectedIds = result['selectedIds'] as List<dynamic>;
        if (selectedIds.isNotEmpty) {
          final selectedId = selectedIds.first as String;

          if (selectedId != parentId) {
            finalCategoryId = selectedId;
            // Trouver le vrai nom de la catégorie (car it might be deep)
            final foundName = await _findCategoryName(
              ref,
              selectedId,
              parentId,
            );
            if (foundName != null) {
              finalCategoryName = CategoryTranslator.translate(
                l10n,
                selectedId,
                foundName,
              );
            }
          }
        }
      }

      // Navigue vers les résultats de recherche avec la catégorie présélectionnée
      if (context.mounted) {
        context.push(
          '/search-results',
          extra: {
            'query': '',
            'categoryId': finalCategoryId,
            'categoryName': finalCategoryName,
          },
        );
      }
    }
  }
}
