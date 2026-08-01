import 'package:flutter/material.dart';

/// Affiche une note moyenne (0 à 5) sous forme d'étoiles pleines/demi/vides.
/// Lecture seule — utilisé sur la fiche produit et la page de profil.
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewsCount;
  final double size;
  final Color color;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    required this.reviewsCount,
    this.size = 16,
    this.color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(5, (index) {
            final threshold = index + 1;
            IconData icon;
            if (rating >= threshold) {
              icon = Icons.star;
            } else if (rating >= threshold - 0.5) {
              icon = Icons.star_half;
            } else {
              icon = Icons.star_border;
            }
            return Icon(icon, size: size, color: color);
          }),
        ),
        const SizedBox(width: 4),
        Text('($reviewsCount)', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Sélecteur d'étoiles interactif (1 à 5), utilisé pour noter un vendeur.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: () => onChanged(starValue),
          icon: Icon(
            value >= starValue ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: size,
          ),
        );
      }),
    );
  }
}
