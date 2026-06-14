import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewRepository {
  final _supabase = Supabase.instance.client;
  
  // Local cache to show submitted reviews immediately during testing
  static final List<Review> _localCache = [];

  Future<List<Review>> fetchReviewsForProduct(String productId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*')
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      
      final dbList = (response as List).map((json) => Review.fromJson(json)).toList();
      
      // Combine DB results with local cache for this product
      final productLocal = _localCache.where((r) => r.productId == productId).toList();
      final combined = [...productLocal, ...dbList];

      if (combined.isEmpty) {
        return _getMockData(productId);
      }
      return combined;
    } catch (e) {
      print('Supabase Fetch Error: $e');
      return _getMockData(productId);
    }
  }

  Future<void> submitReview(Review review) async {
    // 1. Attempt to save to Supabase
    try {
      await _supabase.from('reviews').insert({
        'customer_id': review.customerId,
        'product_id': review.productId,
        'rating': review.rating,
        'review_text': review.reviewText,
        'photo_url': review.photoUrl,
      });
    } catch (e) {
      // 2. If it fails (e.g. no login), we still add to local cache for testing
      print('Supabase Insert Error: $e');
      _localCache.insert(0, review);
    }
    
    // Also add to local cache so user sees it immediately after invalidate
    if (!_localCache.any((r) => r.id == review.id)) {
      _localCache.insert(0, review);
    }
  }

  Future<void> deleteReview(String id) async {
    try {
      // 1. Attempt DB delete
      await _supabase.from('reviews').delete().eq('id', id);
    } catch (e) {
      print('Supabase Delete Error: $e');
    }
    // 2. Always remove from local cache for immediate UI feedback
    _localCache.removeWhere((r) => r.id == id);
  }

  List<Review> _getMockData(String productId) {
    return [
      Review(
        id: 'mock_1',
        customerId: 'u1',
        productId: productId,
        rating: 5,
        reviewText: 'Absolutely stunning quality! The detail in the silk weaving is incredible.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        userName: 'Sokha Mean',
        userAvatar: 'https://i.pravatar.cc/150?u=u1',
        isVerified: true,
      ),
      Review(
        id: 'mock_2',
        customerId: 'u2',
        productId: productId,
        rating: 4,
        reviewText: 'Beautiful piece. It arrived safely and looks even better in person.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        userName: 'Dara Keo',
        userAvatar: 'https://i.pravatar.cc/150?u=u2',
        isVerified: true,
      ),
    ];
  }
}
