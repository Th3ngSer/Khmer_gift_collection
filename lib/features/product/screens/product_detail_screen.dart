import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_detail_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/providers/home_provider.dart';
import '../providers/review_provider.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/constants/translations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/review.dart';
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
  bool _isFav = false;

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeFeedProvider);
    final reviewsAsync = ref.watch(productReviewsProvider(widget.productId));
    final locale = ref.watch(localeProvider).languageCode;
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    const goldColor = Color(0xFFD4AF37);

    String t(String key) => Translations.translate(key, locale);
    final heroHeight = MediaQuery.of(context).size.width * (5 / 4);

    final textColor = ref.watch(themeProvider) == ThemeMode.dark ? Colors.white : AppTheme.deepEarth;
    final cardBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: ProductBottomCTA(
        item: productAsync.value?.product,
        isFav: _isFav,
        onFavPressed: _toggleFavorite,
      ),
      body: productAsync.when(
        loading: () => const Scaffold(body: LoadingShimmer()),
      bottomNavigationBar: _buildBottomCTA(context, goldColor, t),

      body: homeDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
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
          if (item == null) {
            return Center(child: Text(t('product_not_found')));
          }

          final artisan = data.artisans.isNotEmpty ? data.artisans.first : null;
          final rating = item['rating'] ?? 4.8;

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
                              reviewsAsync.when(
                                data: (reviews) => Text(
                                  ' (${reviews.length} ${t('reviews')})',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150), fontSize: 12),
                                ),
                                loading: () => const SizedBox(),
                                error: (_, __) => const SizedBox(),
                              ),
                            ],
                          ),
                        ],
                      ),

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
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      Text(
                        t('the_story'),
                        style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['story'] ?? 'Crafted with care and precision, this piece embodies the rich cultural heritage and generational techniques of local artisans.',
                        style: TextStyle(fontSize: 15, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
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

                      if (artisan != null) ...[
                        Text(
                          t('meet_the_maker'),
                          style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 12),
                        _buildArtisanCard(artisan),
                        const SizedBox(height: 32),
                      ],

                      // --- Reviews Section ---
                      _buildReviewsHeader(t, reviewsAsync, textColor, cardBg),
                      const SizedBox(height: 16),
                      reviewsAsync.when(
                        data: (reviews) => _buildReviewsList(reviews, t),
                        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
                        error: (err, stack) => Text('Error: $err'),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildArtisanCard(Map<String, dynamic> artisan) {
    return GestureDetector(
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
    );
  }

  void _showWriteReviewSheet(String Function(String) t, Color textColor, Color cardBg) {
    int selectedRating = 5;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

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
              Text(
                t('write_review'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: textColor,
                ),
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
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: reviewController,
                maxLines: 4,
                enabled: !isSubmitting,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts with the community...',
                  hintStyle: TextStyle(color: textColor.withAlpha(60)),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.gold, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (reviewController.text.trim().isEmpty) return;

                    setSheetState(() => isSubmitting = true);

                    final user = Supabase.instance.client.auth.currentUser;
                    final userId = user?.id ?? 'test_user_${DateTime.now().millisecondsSinceEpoch}';
                    final userName = user?.userMetadata?['full_name'] ?? 'Test Guest';

                    final newReview = Review(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      customerId: userId,
                      productId: widget.productId,
                      rating: selectedRating,
                      reviewText: reviewController.text,
                      createdAt: DateTime.now(),
                      userName: userName,
                      isVerified: user != null,
                    );

                    // Add a tiny artificial delay for smoothness
                    await Future.delayed(const Duration(milliseconds: 600));

                    try {
                      await ref.read(reviewRepositoryProvider).submitReview(newReview);
                      ref.invalidate(productReviewsProvider(widget.productId));

                      if (mounted) Navigator.pop(context);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                const Text('Thank you for your review!'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green[700],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        TextButton(
          onPressed: () => _showWriteReviewSheet(t, textColor, cardBg),
          child: Text(t('write_review'), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildReviewsList(List<Review> reviews, String Function(String) t) {
    if (reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(t('no_reviews'), style: TextStyle(color: Colors.black.withOpacity(0.4))),
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
    // For demo/mock: allow deleting if customerId matches OR if it starts with 'test_user'
    final bool canDelete = review.customerId == user?.id || review.customerId.startsWith('test_user');

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.gold.withAlpha(40), width: 1),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.gold.withAlpha(10),
                  backgroundImage: review.userAvatar != null ? NetworkImage(review.userAvatar!) : null,
                  child: review.userAvatar == null
                      ? Text(review.userName[0], style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (review.isVerified)
                      Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.blue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            t('verified_purchase'),
                            style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent.withAlpha(150), size: 20),
                  onPressed: () => _showDeleteConfirmation(review),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: AppTheme.gold,
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(100), fontSize: 11),
                    ),
                  ],
                ),
                      ),
                      const SizedBox(height: 16),
                      ProductReviewsList(reviews: reviews, goldColor: goldColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
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
                Text(
                  review.reviewText,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Review', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove your review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(120))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(reviewRepositoryProvider).deleteReview(review.id);
              ref.invalidate(productReviewsProvider(widget.productId));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review deleted'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Delete'),
          ),
        ],
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
                color: _isFav ? goldColor.withAlpha(25) : Colors.transparent,
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
