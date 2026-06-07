import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_detail_provider.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../shared/widgets/loading_shimmer.dart';

import '../widgets/product_hero_header.dart';
import '../widgets/artisan_card.dart';
import '../widgets/product_reviews_list.dart';
import '../widgets/product_bottom_cta.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isFav = false;
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() => _isFav = !_isFav);
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    const goldColor = Color(0xFFD4AF37);
    final heroHeight = MediaQuery.of(context).size.width * (5 / 4);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: ProductBottomCTA(
        item: productAsync.value?.product,
        isFav: _isFav,
        onFavPressed: _toggleFavorite,
      ),
      body: productAsync.when(
        loading: () => const Scaffold(body: LoadingShimmer()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final item = data.product;
          final artisan = data.artisan;
          final reviews = data.reviews;

          final rating = item['rating'] ?? 5.0;
          final tags = [
            'Handmade',
            item['budget_bracket'] ?? 'Premium',
            item['material_focus'] ?? 'Organic',
          ];

          return CustomScrollView(
            slivers: [
              ProductHeroHeader(
                item: item,
                heroHeight: heroHeight,
                pageController: _pageController,
                currentImageIndex: _currentImageIndex,
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Label
                      Text(
                        (item['category'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.0,
                          color: goldColor,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Title & Favorite Heart Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleFavorite,
                            icon: Icon(
                              _isFav ? Icons.favorite : Icons.favorite_border,
                              color: _isFav ? goldColor : Theme.of(context).iconTheme.color,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),

                      // Tagline
                      const SizedBox(height: 8),
                      Text(
                        item['tagline'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),

                      // Price & Rating
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '\$${item['price']}',
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: goldColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            ' (${reviews.length} reviews)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Center(child: KhmerDivider(width: 120)),
                      const SizedBox(height: 24),

                      // The Story
                      const Text(
                        'The story',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['story'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Maker / Artisan Card
                      if (artisan != null) ...[
                        ArtisanCard(artisan: artisan, goldColor: goldColor),
                      ],

                      // Availability Note
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Available at Riverside Atelier & 2 more',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),

                      // Tags
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Theme.of(context).cardColor,
                                side: BorderSide(color: Theme.of(context).dividerColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      // Embedded Reviews Section
                      const SizedBox(height: 32),
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ProductReviewsList(reviews: reviews, goldColor: goldColor),
                    ],
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