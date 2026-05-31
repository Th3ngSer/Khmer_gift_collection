import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/providers/home_provider.dart';
import '../../../shared/widgets/khmer_divider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isFav = false; // Local state for the heart toggle demo

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeFeedProvider);
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // The Sticky Bottom CTA Bar
      bottomNavigationBar: _buildBottomCTA(context, goldColor),
      
      body: homeDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final item = data.items
              .where((i) => i['id'].toString() == widget.productId)
              .firstOrNull;

          if (item == null) {
            return const Center(child: Text('Product not found.'));
          }

          final artisan = data.artisans.isNotEmpty ? data.artisans.first : null;
          final rating = item['rating'] ?? 4.8;
          final reviewsCount = 24; 
          final tags = item['tags'] != null ? List<String>.from(item['tags']) : ['Elegant', 'Handmade'];

          return CustomScrollView(
            slivers: [
              // 3. The Hero Image & Transparent Header
              SliverAppBar(
                expandedHeight: 400,
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
                      Image.network(item['cover'] ?? '', fit: BoxFit.cover),
                      // Subtle gradient to make the white header icons pop
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Product Info & Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Rating Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (item['category'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(fontSize: 10, letterSpacing: 2.0, color: goldColor),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: goldColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                ' ($reviewsCount reviews)',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title & Price
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${item['price']}',
                        style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w600, color: goldColor),
                      ),
                      
                      const SizedBox(height: 24),
                      const Center(child: KhmerDivider(width: 120)),
                      const SizedBox(height: 24),

                      // The Story
                      const Text(
                        'The story',
                        style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['story'] ?? 'Crafted with care and precision, this piece embodies the rich cultural heritage and generational techniques of local artisans. Perfect for adding a touch of elegance to any setting.',
                        style: TextStyle(fontSize: 15, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 20),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Theme.of(context).cardColor,
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        )).toList(),
                      ),
                      
                      const SizedBox(height: 32),

                      // Maker / Artisan Card
                      if (artisan != null) ...[
                        const Text(
                          'Meet the maker',
                          style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/artisans/${artisan['id']}', extra: artisan),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(artisan['avatar'] ?? artisan['cover'] ?? ''),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artisan['name'] ?? '',
                                        style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${artisan['craft']} · ${artisan['region']}',
                                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // --- Sticky Bottom Call-to-Action Bar ---
  Widget _buildBottomCTA(BuildContext context, Color goldColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // Favorite Heart Button
          InkWell(
            onTap: () => setState(() => _isFav = !_isFav),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: _isFav ? goldColor : Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(16),
                color: _isFav ? goldColor.withOpacity(0.1) : Colors.transparent,
              ),
              child: Icon(
                _isFav ? Icons.favorite : Icons.favorite_border,
                color: _isFav ? goldColor : Theme.of(context).iconTheme.color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Order / Buy Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Future Phase: Route to the Booking / Order Flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigating to Order Flow...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A1508), // Deep Earth Tone
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Order Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}