import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/review_repository.dart';
import '../../domain/models/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

final sellerReviewsProvider = StreamProvider.family<List<Review>, String>((
  ref,
  sellerId,
) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.watchReviewsForSeller(sellerId);
});
