import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductDetailData {
  final Map<String, dynamic> product;
  final Map<String, dynamic>? artisan;
  final List<dynamic> reviews;

  ProductDetailData({
    required this.product,
    this.artisan,
    required this.reviews,
  });
}

final productDetailProvider = FutureProvider.family<ProductDetailData, String>((
  ref,
  productId,
) async {
  final supabase = Supabase.instance.client;

  // 1. Fetch the product, its images, and its artisan in a single joined query
  final productResponse = await supabase
      .from('products')
      .select('*, product_images(image_url), artisans(*)')
      .eq('id', productId)
      .maybeSingle();

  if (productResponse == null) {
    throw Exception('Product not found');
  }

  // 2. Fetch the reviews associated with this product (joining users to get the reviewer's info)
  final reviewsResponse = await supabase
      .from('reviews')
      .select('*, users(email)')
      .eq('product_id', productId);

  // 3. Map the data safely to avoid null errors in the UI
  final artisanData = productResponse['artisans'];
  final images = productResponse['product_images'] as List<dynamic>?;
  final imageUrls = (images != null && images.isNotEmpty)
      ? images.map((img) => img['image_url'].toString()).toList()
      : [
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQiugxgmLGqUu6bXJiwgMidRtxyKN9zG_ujGg&s',
        ]; // Fallback

  final safeProduct = {
    ...productResponse,
    'cover': imageUrls.first,
    'imageUrls': imageUrls, 
    'story': productResponse['description'] ?? '',
    'tagline': productResponse['motif_legend'] ?? 'Handmade in Cambodia',
  };

  final safeArtisan = artisanData != null
      ? <String, dynamic>{
          ...Map<String, dynamic>.from(artisanData as Map),
          'avatar':
              artisanData['profile_photo_url'] ??
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQX1CuF5ByhjpYZMllwvBG75hNLw58TW7Dp6Q&s',
          'craft': 'Master Artisan',
        }
      : null;

  return ProductDetailData(
    product: safeProduct,
    artisan: safeArtisan,
    reviews: reviewsResponse,
  );
});
