import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseRepoProvider = Provider<SupabaseRepository>((ref) {
  return SupabaseRepository(ref.watch(supabaseClientProvider));
});

class SupabaseRepository {
  final SupabaseClient _client;

  SupabaseRepository(this._client);

  Future<Map<String, dynamic>> fetchHomeFeedData() async {
    // 1. Fetch products (matching your products schema)
    final productsData = await _client.from('products').select('''
      id, 
      name, 
      category, 
      price, 
      description,
      product_images(image_url) 
    '''); // Note: We can join the product_images table here!

    // 2. Fetch artisans (matching your artisans schema)
    final artisansData = await _client.from('artisans').select('''
      id, 
      name, 
      profile_photo_url, 
      region, 
      heritage_story
    ''');

    return {
      'items': productsData,
      'artisans': artisansData,
      // You can keep collections and promotions empty/mocked until you create tables for them
      'collections': [], 
      'promotions': [],
    };
  }
}