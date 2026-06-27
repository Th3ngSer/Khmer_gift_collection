import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArtisanProfileData {
  final Map<String, dynamic> artisan;
  final List<dynamic> works;

  ArtisanProfileData({required this.artisan, required this.works});
}

final artisanProfileProvider =
    FutureProvider.family<ArtisanProfileData, String>((ref, artisanId) async {
  final supabase = Supabase.instance.client;

  // 1. Fetch Artisan Data
  final artisanResponse = await supabase
      .from('artisans')
      .select()
      .eq('id', artisanId)
      .maybeSingle();

  if (artisanResponse == null) throw Exception('Artisan not found');

  // 2. Fetch all products matching this artisan's ID (with images)
  final worksResponse = await supabase
      .from('products')
      .select('*, product_images(image_url)')
      .eq('artisan_id', artisanId);

  // 3. Clean and map the data
  const fallbackImage =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQX1CuF5ByhjpYZMllwvBG75hNLw58TW7Dp6Q&s';

  // Compute safeWorks FIRST so we can inject them into the artisan map
  final safeWorks = worksResponse.map((p) {
    final images = p['product_images'] as List<dynamic>?;
    final imageUrl = (images != null && images.isNotEmpty)
        ? images.first['image_url']
        : fallbackImage;
    return {...p, 'cover': imageUrl};
  }).toList();

  // Build the artisan map, now including the products list
  final safeArtisan = {
    ...artisanResponse,
    'avatar': artisanResponse['profile_photo_url'] ?? fallbackImage,
    'cover': artisanResponse['cover_photo_url'] ??
        artisanResponse['profile_photo_url'] ??
        fallbackImage,
    'region': artisanResponse['region'] ?? 'Cambodia',
    'name': artisanResponse['name'] ?? 'Master Artisan',
    'craft': 'Traditional Craft',
    'established': '1998',
    'rating': 4.9,
    'bio': 'Preserving ancient techniques through sustainable craftsmanship.',
    'story': artisanResponse['heritage_story'] ?? '',
    'latitude': (artisanResponse['latitude'] as num?)?.toDouble(),
    'longitude': (artisanResponse['longitude'] as num?)?.toDouble(),
    'products':
        safeWorks, 
  };

  return ArtisanProfileData(artisan: safeArtisan, works: safeWorks);
});
