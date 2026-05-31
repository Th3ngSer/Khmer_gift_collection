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
  
  // A. Load static UI data (Promotions & Collections) from local JSON
  final String jsonString = await rootBundle.loadString('assets/mock/home_feed.json');
  final localData = json.decode(jsonString);

  // B. Load dynamic data (Products & Artisans) live from Supabase
  final supabase = Supabase.instance.client;
  
  // Because we configured RLS earlier, this safely fetches the public data!
  final artisansData = await supabase.from('artisans').select();
  final productsData = await supabase.from('products').select();

  // C. Combine and return everything to the UI
  return HomeFeedData(
    artisans: artisansData,
    items: productsData,
    promotions: localData['promotions'] ?? [],
    collections: localData['collections'] ?? [],
  );
});