import '../models/product.dart';
import '../models/artisan.dart';
import '../models/review.dart';

class MockRepository {
  Future<List<Product>> getProducts() async {
    // In a real app, this might fetch from local JSON or Supabase
    // For now, returning an empty list as a placeholder
    return [];
  }

  Future<List<Artisan>> getArtisans() async {
    return [];
  }

  Future<List<Review>> getReviewsForProduct(String productId) async {
    // This will be useful for your next task: Reviews
    return [];
  }

  // Add more methods as needed for Promotions, Chat, etc.
}
