import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_detail_provider.dart';
import '../providers/review_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../shared/widgets/loading_shimmer.dart';

import '../widgets/product_hero_header.dart';
import '../widgets/artisan_card.dart';
import '../widgets/product_reviews_list.dart';
import '../widgets/product_bottom_cta.dart';
import '../widgets/write_review_sheet.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
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

  Future<void> _toggleFavorite() async {
    await ref.read(favoritesProvider.notifier).toggleItem(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final reviewsAsync = ref.watch(productReviewsProvider(widget.productId));
    final isFav = ref.watch(favoritesProvider).items.contains(widget.productId);
    final locale = ref.watch(localeProvider).languageCode;
    const goldColor = Color(0xFFD4AF37);

    const goldColor = Color(0xFFD4AF37);
    final heroHeight = MediaQuery.of(context).size.width * (5 / 4);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: ProductBottomCTA(
        item: productAsync.value?.product,
        isFav: isFav,
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
                onPageChanged: (index) =>
                    setState(() => _currentImageIndex = index),
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
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav
                                  ? goldColor
                                  : Theme.of(context).iconTheme.color,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.1),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // NEW: Dedicated Cultural Specs Sheet Grid (Materials & Dimensions)
                      const Text(
                        'Specifications',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.texture_outlined,
                                      size: 20, color: goldColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Material Focus',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        Text(
                                          item['material_focus'] ??
                                              'Traditional Craft',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.straighten_outlined,
                                      size: 20, color: goldColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dimensions',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        Text(
                                          item['dimensions'] ??
                                              'Standard / Hand-cut',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Available at Riverside Atelier & 2 more',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
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
                                label: Text(tag,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor: Theme.of(context).cardColor,
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            )
                            .toList(),
                      ),

  void _showWriteReviewSheet(String Function(String) t, Color textColor, Color cardBg, List<Review> currentReviews) {
    int selectedRating = 5;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    final double avgRating = currentReviews.isEmpty 
        ? 0.0 
        : currentReviews.map((r) => r.rating).reduce((a, b) => a + b) / currentReviews.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      barrierColor: Colors.black.withAlpha(100),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('write_review'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      color: textColor,
                    ),
                  ),
                  if (currentReviews.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppTheme.gold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'How would you rate this masterpiece?',
                style: TextStyle(color: textColor.withAlpha(120), fontSize: 14),
              ),
              const SizedBox(height: 32),
              // Interactive Animated Rating Stars
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final isSelected = index < selectedRating;
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 200),
                      tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: IconButton(
                          onPressed: isSubmitting ? null : () => setSheetState(() => selectedRating = index + 1),
                          icon: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? AppTheme.gold : textColor.withAlpha(40),
                            size: 44,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                builder: (context) => WriteReviewSheet(
                                    productId: widget.productId),
                              );
                            },
                            icon: const Icon(Icons.rate_review_outlined,
                                size: 18, color: goldColor),
                            label: const Text(
                              'Write Review',
                              style: TextStyle(
                                  color: goldColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      ref.invalidate(productReviewsProvider(widget.productId));
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsHeader(String Function(String) t, AsyncValue<List<Review>> reviewsAsync, Color textColor, Color cardBg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t('reviews_title'),
          style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
        ),
        reviewsAsync.when(
          data: (reviews) => TextButton(
            onPressed: () => _showWriteReviewSheet(t, textColor, cardBg, reviews),
            child: Text(t('write_review'), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildReviewsList(List<Review> reviews, String Function(String) t) {
    if (reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(t('no_reviews'), style: TextStyle(color: Colors.black.withAlpha(100))),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, opacity, child) => Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - opacity)),
              child: child,
            ),
          ),
          child: _buildReviewItem(review, t),
        );
      },
    );
  }

  Widget _buildReviewItem(Review review, String Function(String) t) {
    final user = Supabase.instance.client.auth.currentUser;
    final bool canDelete = review.customerId == user?.id || review.customerId.startsWith('test_user');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // User Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold.withAlpha(40), width: 1),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.gold.withAlpha(10),
                backgroundImage: review.userAvatar != null ? NetworkImage(review.userAvatar!) : null,
                child: review.userAvatar == null
                    ? Text(review.userName[0], style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // User Name & Verified Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  if (review.isVerified)
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          t('verified_purchase'),
                          style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Rating Stars & Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: AppTheme.gold,
                    );
                  }),
                ),
                const SizedBox(height: 2),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            // Delete button if applicable
            if (canDelete)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent.withAlpha(150), size: 20),
                  onPressed: () => _showDeleteConfirmation(review),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Review Text Bubble
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (review.photoUrl != null && review.photoUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      review.photoUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
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
