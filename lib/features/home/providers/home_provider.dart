import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Define the Data Model
class HomeFeedData {
  final List<dynamic> artisans;
  final List<dynamic> promotions;
  final List<dynamic> collections;
  final List<dynamic> items;

  HomeFeedData({
    required this.artisans,
    required this.promotions,
    required this.collections,
    required this.items,
  });
}

// 2. The Hybrid Provider
final homeFeedProvider = FutureProvider<HomeFeedData>((ref) async {
  final String jsonString = await rootBundle.loadString(
    'assets/mock/home_feed.json',
  );
  final localData = json.decode(jsonString);

  final supabase = Supabase.instance.client;
  final rawArtisans = await supabase.from('artisans').select();
  final rawProducts = await supabase
      .from('products')
      .select('*, product_images(image_url)');

  const fallbackAvatar =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQX1CuF5ByhjpYZMllwvBG75hNLw58TW7Dp6Q&s';
  const fallbackCover =
      'https://mlo1wbhvgmgt.i.optimole.com/w:1024/h:576/q:mauto/g:sm/f:best/https://pethero.co.za/wp-content/uploads/2026/02/Indoor-Cats-Blog-Banner.png';
  const fallbackProduct =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQiugxgmLGqUu6bXJiwgMidRtxyKN9zG_ujGg&s';

  final safeArtisans = rawArtisans
      .map(
        (a) => {
          ...a,
          'avatar': a['profile_photo_url'] ?? fallbackAvatar, 
          'cover':
              a['profile_photo_url'] ??
              fallbackCover, 
          'story': a['heritage_story'] ?? '', 
          'craft':
              'Master Artisan', 
        },
      )
      .toList();

  final safeProducts = rawProducts.map((p) {
    final images = p['product_images'] as List<dynamic>?;
    final imageUrl = (images != null && images.isNotEmpty)
        ? images.first['image_url']
        : fallbackProduct;

    return {
      ...p,
      'cover': imageUrl, 
    };
  }).toList();

  return HomeFeedData(
    artisans: safeArtisans,
    items: safeProducts,
    promotions: localData['promotions'] ?? [],
    collections: localData['collections'] ?? [],
  );
});
