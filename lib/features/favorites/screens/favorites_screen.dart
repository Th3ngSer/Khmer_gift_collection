import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';
import '../widgets/favorites_tab_bar.dart';
import '../widgets/empty_favorites.dart';
import '../widgets/favorite_collection_card.dart';
import '../widgets/favorite_artisan_tile.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _currentTab = 'items';

  @override
  Widget build(BuildContext context) {
    final hydratedAsync = ref.watch(hydratedFavoritesProvider);
    final favsState = ref.watch(favoritesProvider);
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR SHELF',
              style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: goldColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Saved for later',
              style: TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Animated Segmented Control
          FavoritesTabBar(
            currentTab: _currentTab,
            onTabChanged: (tab) => setState(() => _currentTab = tab),
            counts: {
              'items': favsState.items.length,
              'collections': favsState.collections.length,
              'artisans': favsState.artisans.length,
            },
          ),
          
          // 2. Dynamic Content Area
          Expanded(
            child: hydratedAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (data) {
                if (_currentTab == 'items') {
                  if (data.items.isEmpty) return const EmptyFavorites(message: 'No saved products yet.');
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.60,
                    ),
                    itemCount: data.items.length,
                    itemBuilder: (context, index) => ProductCard(item: data.items[index]),
                  );
                }

                if (_currentTab == 'collections') {
                  if (data.collections.isEmpty) return const EmptyFavorites(message: 'No saved collections yet.');
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.collections.length,
                    itemBuilder: (context, index) => FavoriteCollectionCard(collection: data.collections[index]),
                  );
                }

                if (_currentTab == 'artisans') {
                  if (data.artisans.isEmpty) return const EmptyFavorites(message: 'No saved artisans yet.');
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.artisans.length,
                    itemBuilder: (context, index) => FavoriteArtisanTile(artisan: data.artisans[index]),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}