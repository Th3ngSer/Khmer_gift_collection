import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectionDetailData {
  final Map<String, dynamic> collection;
  final List<dynamic> products;

  CollectionDetailData({required this.collection, required this.products});
}

final collectionDetailProvider =
    FutureProvider.family<CollectionDetailData, String>((
      ref,
      collectionId,
    ) async {
      final String response = await rootBundle.loadString(
        'assets/mock/home_feed.json',
      );
      final Map<String, dynamic> feedData = Map<String, dynamic>.from(
        json.decode(response),
      );
      final List<dynamic> collections = List<dynamic>.from(
        feedData['collections'],
      );

      final collection = Map<String, dynamic>.from(
        collections.firstWhere(
          (c) => c['id'].toString() == collectionId,
          orElse: () => throw Exception('Collection not found'),
        ),
      );

      final itemIds = List<String>.from(collection['itemIds'] ?? []);

      final supabase = Supabase.instance.client;
      List<dynamic> safeProducts = [];

      if (itemIds.isNotEmpty) {
        try {
          final productsResponse = await supabase
              .from('products')
              .select('*, product_images(image_url)')
              .inFilter('id', itemIds);

          safeProducts = List.from(productsResponse);
        } catch (e) {}
      }

      if (safeProducts.isEmpty) {
        final fallbackResponse = await supabase
            .from('products')
            .select('*, product_images(image_url)')
            .limit(4);
        safeProducts = List.from(fallbackResponse);
      }

      safeProducts = safeProducts.map((p) {
        final images = p['product_images'] as List<dynamic>?;
        final imageUrl = (images != null && images.isNotEmpty)
            ? images.first['image_url']
            : 'https://images.unsplash.com/photo-1618220179428-22790b461013';
        return Map<String, dynamic>.from({...p, 'cover': imageUrl});
      }).toList();

      return CollectionDetailData(
        collection: collection,
        products: safeProducts,
      );
    });
