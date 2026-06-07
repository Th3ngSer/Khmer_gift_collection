import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/models/review.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository());

final productReviewsProvider = FutureProvider.family<List<Review>, String>((ref, productId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.fetchReviewsForProduct(productId);
});
