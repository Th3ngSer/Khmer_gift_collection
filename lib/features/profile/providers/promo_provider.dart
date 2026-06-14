import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/promo_repository.dart';
import '../../../data/models/coupon.dart';

final promoRepositoryProvider = Provider((ref) => PromoRepository());

final activePromotionsProvider = FutureProvider<List<Coupon>>((ref) async {
  final repository = ref.watch(promoRepositoryProvider);
  return repository.fetchActivePromotions();
});
