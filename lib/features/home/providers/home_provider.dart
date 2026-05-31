import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Define the Data Model
class HomeFeedData {
  final List<dynamic> artisans;
  final List<dynamic> promotions;
  final List<dynamic> collections;
  final List<dynamic> items; // Products

  HomeFeedData({
    required this.artisans,
    required this.promotions,
    required this.collections,
    required this.items,
  });
}

// 2. The Hybrid Provider
final homeFeedProvider = FutureProvider<HomeFeedData>((ref) async {
  
  final String jsonString = await rootBundle.loadString('assets/mock/home_feed.json');
  final localData = json.decode(jsonString);

  final supabase = Supabase.instance.client;
  final rawArtisans = await supabase.from('artisans').select();
  final rawProducts = await supabase.from('products').select();

  const fallbackAvatar = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQX1CuF5ByhjpYZMllwvBG75hNLw58TW7Dp6Q&s';
  const fallbackCover = 'https://mlo1wbhvgmgt.i.optimole.com/w:1024/h:576/q:mauto/g:sm/f:best/https://pethero.co.za/wp-content/uploads/2026/02/Indoor-Cats-Blog-Banner.png';
  const fallbackProduct = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQiugxgmLGqUu6bXJiwgMidRtxyKN9zG_ujGg&s';

  final safeArtisans = rawArtisans.map((a) => {
    ...a,
    'avatar': a['avatar'] ?? fallbackAvatar,
    'cover': a['cover'] ?? fallbackCover,
  }).toList();

  final safeProducts = rawProducts.map((p) => {
    ...p,
    'cover': p['cover'] ?? fallbackProduct,
  }).toList();

  return HomeFeedData(
    artisans: safeArtisans,
    items: safeProducts,
    promotions: localData['promotions'] ?? [],
    collections: localData['collections'] ?? [],
  );
});