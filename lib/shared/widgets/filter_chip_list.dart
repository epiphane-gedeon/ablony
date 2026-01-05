import 'package:flutter/material.dart';

/// Modèle pour un élément de filtre
class FilterItem {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const FilterItem({
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });
}

/// Widget de liste de chips filtrables
///
/// Affiche une liste horizontale de chips avec style Vinted
class FilterChipList extends StatelessWidget {
  final List<FilterItem> items;

  const FilterChipList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildChip(theme, item);
        },
      ),
    );
  }

  Widget _buildChip(ThemeData theme, FilterItem item) {
    final isSelected = item.isSelected;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey[700]! : Colors.grey[400]!),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
