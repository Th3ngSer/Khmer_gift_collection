import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CollectionHeroBanner extends StatelessWidget {
  final Map<String, dynamic> collection;

  const CollectionHeroBanner({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.of(context).size.width * (3 / 4);
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    const goldColor = Color(0xFFD4AF37);

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
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // The Cover Image
            Image.network(
              collection['cover'] ?? 'https://via.placeholder.com/400', 
              fit: BoxFit.cover,
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
                    style: const TextStyle(fontSize: 10, letterSpacing: 2.5, color: goldColor),
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