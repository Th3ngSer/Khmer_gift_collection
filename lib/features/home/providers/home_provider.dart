import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

class HomeFeedData {
  final List<dynamic> artisans;
  final List<dynamic> promotions;
  final List<dynamic> collections;
  final List<dynamic> items;
  final List<String> categories;

  HomeFeedData({
    required this.artisans,
    required this.promotions,
    required this.collections,
    required this.items,
    required this.categories,
  });
}

final userRoleProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.value;

  if (user == null) return null;
  final data = await Supabase.instance.client
      .from('users')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();
  return data?['role'] as String?;
});

final homeFeedProvider = FutureProvider<HomeFeedData>((ref) async {
  final String jsonString = await rootBundle.loadString(
    'assets/mock/home_feed.json',
  );
  final localData = json.decode(jsonString);

  final supabase = Supabase.instance.client;
  final rawArtisans = await supabase.from('artisans').select();
  final rawProducts = await supabase
      .from('products')
      .select('*, product_images!product_images_product_id_fkey(image_url)');

  const fallbackAvatar =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQX1CuF5ByhjpYZMllwvBG75hNLw58TW7Dp6Q&s';
  const fallbackCover =
      'https://mlo1wbhvgmgt.i.optimole.com/w:1024/h:576/q:mauto/g:sm/f:best/https://pethero.co.za/wp-content/uploads/2026/02/Indoor-Cats-Blog-Banner.png';
  const fallbackProduct =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQiugxgmLGqUu6bXJiwgMidRtxyKN9zG_ujGg&s';

  final processedArtisans = rawArtisans.map((a) {
    bool isStoryValid = false;
    if (a['story_created_at'] != null && a['latest_story_url'] != null) {
      final createdAt = DateTime.parse(a['story_created_at'].toString());
      isStoryValid = DateTime.now().difference(createdAt).inHours < 24;
    }

    return {
      ...a,
      'has_active_story': isStoryValid,
      'avatar': a['profile_photo_url'] ?? fallbackAvatar,
      'cover': a['cover_photo_url'] ?? a['profile_photo_url'] ?? fallbackCover,
      'story_post_image': isStoryValid ? a['latest_story_url'] : null,
      'story_text': isStoryValid ? (a['story_caption'] ?? '') : '',
    };
  }).toList();

  final safeProducts = rawProducts.map((p) {
    final images = p['product_images'] as List<dynamic>?;
    final imageUrl = (images != null && images.isNotEmpty)
        ? images.first['image_url']
        : fallbackProduct;
    return {...p, 'cover': imageUrl};
  }).toList();

  final dynamicCategories =
      safeProducts.map((i) => i['category'].toString()).toSet().toList();

  final finalCategories = dynamicCategories.isEmpty
      ? ['Textile', 'Silver', 'Wood', 'Edible', 'Jewelry']
      : dynamicCategories;

  return HomeFeedData(
    artisans: processedArtisans,
    items: safeProducts,
    promotions: localData['promotions'] ?? [],
    collections: localData['collections'] ?? [],
    categories: finalCategories,
  );
});

class CategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectCategory(String? category) {
    state = category;
  }
}

final selectedCategoryProvider = NotifierProvider<CategoryNotifier, String?>(() {
  return CategoryNotifier();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});
