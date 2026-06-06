import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/collection_provider.dart';
import '../widgets/collection_hero_banner.dart';
import '../widgets/collection_info_section.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final String collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionDetailProvider(collectionId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: collectionAsync.when(
        loading: () => const LoadingShimmer(),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final c = data.collection;
          final products = data.products;

          return CustomScrollView(
            slivers: [
              // 1. Extracted Hero Banner
              CollectionHeroBanner(collection: c),

              // 2. Extracted Info & Divider Section
              SliverToBoxAdapter(
                child: CollectionInfoSection(
                  description: c['description'] ?? '',
                  pieceCount: products.length,
                ),
              ),

              // 3. The Product Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.60, // Matches your shared ProductCard ratio
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(item: products[index]),
                    childCount: products.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}