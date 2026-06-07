import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesState {
  final List<String> items;
  final List<String> collections;
  final List<String> artisans;

  FavoritesState({this.items = const [], this.collections = const [], this.artisans = const []});

  FavoritesState copyWith({List<String>? items, List<String>? collections, List<String>? artisans}) {
    return FavoritesState(
      items: items ?? this.items,
      collections: collections ?? this.collections,
      artisans: artisans ?? this.artisans,
    );
  }
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() {
    return FavoritesState();
  }

  void toggleItem(String id) {
    final current = List<String>.from(state.items);
    current.contains(id) ? current.remove(id) : current.add(id);
    state = state.copyWith(items: current);
  }

  void toggleCollection(String id) {
    final current = List<String>.from(state.collections);
    current.contains(id) ? current.remove(id) : current.add(id);
    state = state.copyWith(collections: current);
  }

  void toggleArtisan(String id) {
    final current = List<String>.from(state.artisans);
    current.contains(id) ? current.remove(id) : current.add(id);
    state = state.copyWith(artisans: current);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(() {
  return FavoritesNotifier();
});


class HydratedFavorites {
  final List<dynamic> items;
  final List<dynamic> collections;
  final List<dynamic> artisans;
  HydratedFavorites({required this.items, required this.collections, required this.artisans});
}

final hydratedFavoritesProvider = FutureProvider<HydratedFavorites>((ref) async {
  final favs = ref.watch(favoritesProvider);
  final supabase = Supabase.instance.client;

  List<dynamic> fetchedItems = [];
  List<dynamic> fetchedArtisans = [];
  List<dynamic> fetchedCollections = [];

  // Fetch Products
  if (favs.items.isNotEmpty) {
    final res = await supabase.from('products').select('*, product_images(image_url)').inFilter('id', favs.items);
    fetchedItems = res.map((p) {
      final images = p['product_images'] as List<dynamic>?;
      final url = (images != null && images.isNotEmpty) ? images.first['image_url'] : 'https://images.unsplash.com/photo-1618220179428-22790b461013';
      return Map<String, dynamic>.from({...p, 'cover': url});
    }).toList();
  }

  if (favs.artisans.isNotEmpty) {
    final res = await supabase.from('artisans').select().inFilter('id', favs.artisans);
    fetchedArtisans = res.map((a) => Map<String, dynamic>.from({
      ...a,
      'avatar': a['profile_photo_url'] ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
    })).toList();
  }

  // Fetch Collections (From mock JSON)
  if (favs.collections.isNotEmpty) {
    final String response = await rootBundle.loadString('assets/mock/home_feed.json');
    final data = json.decode(response);
    final allCols = List<dynamic>.from(data['collections']);
    fetchedCollections = allCols.where((c) => favs.collections.contains(c['id'].toString())).toList();
  }

  return HydratedFavorites(items: fetchedItems, collections: fetchedCollections, artisans: fetchedArtisans);
});