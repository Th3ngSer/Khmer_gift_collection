import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductHeroHeader extends StatelessWidget {
  final Map<String, dynamic> item;
  final double heroHeight;
  final PageController pageController;
  final int currentImageIndex;
  final ValueChanged<int> onPageChanged;

  const ProductHeroHeader({
    super.key,
    required this.item,
    required this.heroHeight,
    required this.pageController,
    required this.currentImageIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrls = (item['imageUrls'] as List<dynamic>? ?? []);

    return SliverAppBar(
      expandedHeight: heroHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.5),
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
            backgroundColor: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final imageWidget = Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 50,
                      ),
                    ),
                  ),
                );

                // Connect only the primary leading image to the grid card's Hero anchor
                if (index == 0) {
                  return Hero(
                    tag: 'product-img-${item['id']}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: imageWidget,
                    ),
                  );
                }

                return imageWidget;
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageUrls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentImageIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
