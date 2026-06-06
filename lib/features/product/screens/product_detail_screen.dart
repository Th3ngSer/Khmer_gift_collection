import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/providers/home_provider.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/constants/translations.dart';

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
    final homeDataAsync = ref.watch(homeFeedProvider);
    final locale = ref.watch(localeProvider).languageCode;
    const goldColor = Color(0xFFD4AF37);
    
    String t(String key) => Translations.translate(key, locale);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: _buildBottomCTA(context, goldColor, t),
      
      body: homeDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final item = data.items
              .where((i) => i['id'].toString() == widget.productId)
              .firstOrNull;

          if (item == null) {
            return Center(child: Text(t('product_not_found')));
          }

          final artisan = data.artisans.isNotEmpty ? data.artisans.first : null;
          final rating = item['rating'] ?? 4.8;
          final reviewsCount = 24; 

          return CustomScrollView(
            slivers: [
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                ' ($reviewsCount ${t('reviews')})',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

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

                      Text(
                        t('the_story'),
                        style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['story'] ?? 'Crafted with care and precision, this piece embodies the rich cultural heritage and generational techniques of local artisans.',
                        style: TextStyle(fontSize: 15, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 32),

                      if (artisan != null) ...[
                        Text(
                          t('meet_the_maker'),
                          style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildBottomCTA(BuildContext context, Color goldColor, String Function(String) t) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
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
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('nav_order_flow'))),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A1508),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                t('order_now'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
