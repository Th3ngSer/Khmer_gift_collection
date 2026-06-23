import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../favorites/providers/favorites_provider.dart';

class CollectionHeroBanner extends ConsumerWidget {
  final Map<String, dynamic> collection;

  const CollectionHeroBanner({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroHeight = MediaQuery.of(context).size.width * (3 / 4);
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    const goldColor = Color(0xFFD4AF37);

    final favsState = ref.watch(favoritesProvider);
    final bool isFav = favsState.collections.contains(
      collection['id'].toString(),
    );

    return SliverAppBar(
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
                color: isFav ? goldColor : Colors.white,
              ),
              onPressed: () {
                ref
                    .read(favoritesProvider.notifier)
                    .toggleCollection(collection['id'].toString());
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
            Hero(
              tag: 'collection-cover-${collection['id']}',
              child: Material(
                type: MaterialType.transparency,
                child: Image.network(
                  collection['cover'] ?? 'https://via.placeholder.com/400',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    scaffoldBgColor,
                    scaffoldBgColor.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // The Anchored Title & Subtitle
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (collection['subtitle'] ?? '').toString().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: goldColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    collection['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
