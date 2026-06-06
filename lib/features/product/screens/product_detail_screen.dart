import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_detail_provider.dart';
import '../../../shared/widgets/khmer_divider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isFav = false; 

  @override
  Widget build(BuildContext context) {
    // Now watching the new dedicated provider and passing the productId
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    const goldColor = Color(0xFFD4AF37);
    
    // Calculates a 4:5 aspect ratio based on the screen width for the hero image
    final heroHeight = MediaQuery.of(context).size.width * (5 / 4);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: _buildBottomCTA(context, goldColor, productAsync.value?.product),
      
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final item = data.product;
          final artisan = data.artisan;
          final reviews = data.reviews;
          
          final rating = item['rating'] ?? 5.0; // Fallback since rating isn't a direct DB column
          final tags = ['Handmade', item['budget_bracket'] ?? 'Premium', item['material_focus'] ?? 'Organic'];

          return CustomScrollView(
            slivers: [
              // 1. The Hero Image & Transparent Header
              SliverAppBar(
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
                       Image.network(
                        item['cover'] ?? '', 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
                            ),
                          );
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
                    ],
                  ),
                ),
              ),

              // 2. Product Info & Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Label
                      Text(
                        (item['category'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(fontSize: 10, letterSpacing: 2.0, color: goldColor),
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
                              style: const TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _isFav = !_isFav),
                            icon: Icon(
                              _isFav ? Icons.favorite : Icons.favorite_border,
                              color: _isFav ? goldColor : Theme.of(context).iconTheme.color,
                            ),
                            style: IconButton.styleFrom(backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1)),
                          )
                        ],
                      ),
                      
                      // Tagline (Motif Legend)
                      const SizedBox(height: 8),
                      Text(
                        item['tagline'],
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),

                      // Price & Rating
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '\$${item['price']}',
                            style: const TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: goldColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            ' (${reviews.length} reviews)',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                          ),
                        ],
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
                        item['story'],
                        style: TextStyle(fontSize: 15, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 20),

                      // Maker / Artisan Card
                      if (artisan != null) ...[
                        GestureDetector(
                          onTap: () => context.push('/artisans/${artisan['id']}', extra: artisan),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(artisan['avatar'] ?? ''),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (artisan['region'] ?? '').toString().toUpperCase(),
                                        style: const TextStyle(fontSize: 10, letterSpacing: 2.0, color: goldColor),
                                      ),
                                      Text(
                                        artisan['name'] ?? '',
                                        style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        artisan['craft'] ?? '',
                                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 28),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Availability Note
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 8),
                          Text(
                            'Available at Riverside Atelier & 2 more',
                            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),

                      // Tags
                      const SizedBox(height: 20),
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

                      // Embedded Reviews Section
                      const SizedBox(height: 32),
                      const Text(
                        'Reviews',
                        style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._buildReviewsSection(reviews),
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

  // Helper to render the inline reviews
  List<Widget> _buildReviewsSection(List<dynamic> reviews) {
    if (reviews.isEmpty) {
      return [const Text("No reviews yet. Be the first to order!")];
    }
    
    return reviews.map((r) {
      final rating = r['rating'] as int? ?? 5;
      final email = r['users']?['email'] ?? 'Anonymous';
      final username = email.toString().split('@').first; // Clean up email for display

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 16, child: Text(username[0].toUpperCase(), style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 12),
                  Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 14,
                      color: const Color(0xFFD4AF37),
                    )),
                  )
                ],
              ),
              if (r['review_text'] != null) ...[
                const SizedBox(height: 12),
                Text(r['review_text'], style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  // Sticky Bottom Call-to-Action Bar
  Widget _buildBottomCTA(BuildContext context, Color goldColor, Map<String, dynamic>? item) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95), // Slight transparency for backdrop effect
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // Secondary Toggle Button
          OutlinedButton(
            onPressed: () => setState(() => _isFav = !_isFav),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(_isFav ? 'Saved' : 'Save'),
          ),
          const SizedBox(width: 16),
          // Primary Order Button
          Expanded(
            child: ElevatedButton(
              onPressed: item == null ? null : () {
                context.push('/booking/${item['id']}'); // Routing as defined in React specs
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C2D19), // Terracotta Red / Primary
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                item != null ? 'Order — \$${item['price']}' : 'Loading...',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}