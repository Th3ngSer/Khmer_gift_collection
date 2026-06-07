// lib/features/artisan/screens/artisan_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/artisan_provider.dart';
import '../widgets/artisan_info_card.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../favorites/providers/favorites_provider.dart';

class ArtisanProfileScreen extends ConsumerWidget {
  final String artisanId;

  const ArtisanProfileScreen({super.key, required this.artisanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artisanAsync = ref.watch(artisanProfileProvider(artisanId));
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;

    // Calculates a 4:3 aspect ratio for the hero image
    final heroHeight = MediaQuery.of(context).size.width * (3 / 4);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: artisanAsync.when(
        loading: () => const LoadingShimmer(),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final a = data.artisan;
          final works = data.works;

          final favsState = ref.watch(favoritesProvider);
          final bool isFav = favsState.artisans.contains(a['id'].toString());

          return CustomScrollView(
            slivers: [
              // 1. The 4:3 Hero Image with Overlapping Rounded Corners
              SliverAppBar(
                expandedHeight: heroHeight,
                pinned: true,
                stretch: true,
                backgroundColor: scaffoldBgColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.4),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? const Color(0xFFD4AF37) : Colors.white,
                        ),
                        onPressed: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleArtisan(a['id'].toString());
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(a['cover'], fit: BoxFit.cover),
                      // Bottom-to-top gradient
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // THE OVERLAP TRICK: This draws the top rounded corners of the profile card
                // directly on top of the bottom edge of the image
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(32),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: scaffoldBgColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Profile Info & Story (Extracted Widget)
              SliverToBoxAdapter(
                child: ArtisanInfoCard(artisan: a, worksCount: works.length),
              ),

              // 3. "From the workshop" Products Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.60,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(item: works[index]),
                    childCount: works.length,
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
