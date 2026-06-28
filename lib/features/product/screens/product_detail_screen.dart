import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/product_detail_provider.dart';
import '../providers/review_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/constants/translations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/review.dart';

import '../widgets/product_hero_header.dart';
import '../widgets/artisan_card.dart';
import '../widgets/product_bottom_cta.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
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
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    
    final textColor = isDark ? Colors.white : AppTheme.deepEarth;
    final cardBg = Theme.of(context).cardColor;
    const goldColor = Color(0xFFD4AF37);
    
    String t(String key) => Translations.translate(key, locale);
    final heroHeight = MediaQuery.of(context).size.width * (5 / 4);

    return productAsync.when(
      loading: () => const Scaffold(body: LoadingShimmer()),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $err')),
      ),
      data: (data) {
        final item = data.product;
        final artisan = data.artisan;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottomNavigationBar: ProductBottomCTA(
            item: item,
            isFav: isFav,
            onFavPressed: _toggleFavorite,
          ),
          body: CustomScrollView(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (item['category'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 2.0,
                              color: goldColor,
                            ),
                          ),
                          reviewsAsync.when(
                            data: (reviews) {
                              final double avgRating = reviews.isEmpty 
                                  ? (item['rating'] ?? 5.0).toDouble()
                                  : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
                              
                              return Row(
                                children: [
                                  const Icon(Icons.star, color: goldColor, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    ' (${reviews.length} ${t('reviews')})',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (err, stack) => const SizedBox(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

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
                                  .withAlpha(25),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text(
                        item['tagline'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        '\$${item['price']}',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Center(child: KhmerDivider(width: 120)),
                      const SizedBox(height: 24),

                      Text(
                        t('the_story'),
                        style: const TextStyle(
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
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (artisan != null) ...[
                        Text(
                          t('meet_the_maker'),
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ArtisanCard(
                          artisan: artisan,
                          goldColor: goldColor,
                          productContext: item,
                        ),
                        const SizedBox(height: 32),
                      ],

                      // --- Reviews Section ---
                      _buildReviewsHeader(t, reviewsAsync, textColor, cardBg),
                      const SizedBox(height: 16),
                      reviewsAsync.when(
                        data: (reviews) => _buildReviewsList(reviews, t),
                        loading: () => const Center(
                            child: CircularProgressIndicator(color: goldColor)),
                        error: (err, stack) => Text('Error: $err'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWriteReviewSheet(String Function(String) t, Color textColor,
      Color cardBg, List<Review> currentReviews) {
    int selectedRating = 5;
    final TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    final double avgRating = currentReviews.isEmpty
        ? 0.0
        : currentReviews.map((r) => r.rating).reduce((a, b) => a + b) /
            currentReviews.length;

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
          padding: EdgeInsets.fromLTRB(24, 24, 24,
              MediaQuery.of(context).viewInsets.bottom + 24),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppTheme.gold, size: 16),
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
                          onPressed: isSubmitting
                              ? null
                              : () =>
                                  setSheetState(() => selectedRating = index + 1),
                          icon: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: isSelected
                                ? AppTheme.gold
                                : textColor.withAlpha(40),
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (reviewController.text.trim().isEmpty) return;

                          setSheetState(() => isSubmitting = true);

                          final user = Supabase.instance.client.auth.currentUser;
                          final userId = user?.id ??
                              'test_user_${DateTime.now().millisecondsSinceEpoch}';
                          final userName =
                              user?.userMetadata?['full_name'] ?? 'Test Guest';

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

                          await Future.delayed(const Duration(milliseconds: 600));

                          try {
                            await ref.read(reviewRepositoryProvider).submitReview(newReview);
                            ref.invalidate(productReviewsProvider(widget.productId));

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Thank you for your review!'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.green[700],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Review',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsHeader(String Function(String) t,
      AsyncValue<List<Review>> reviewsAsync, Color textColor, Color cardBg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t('reviews_title'),
          style: const TextStyle(
              fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
        ),
        reviewsAsync.when(
          data: (reviews) => TextButton(
            onPressed: () =>
                _showWriteReviewSheet(t, textColor, cardBg, reviews),
            child: Text(t('write_review'),
                style: const TextStyle(
                    color: AppTheme.gold, fontWeight: FontWeight.bold)),
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
          child: Text(t('no_reviews'),
              style: TextStyle(color: Colors.black.withAlpha(100))),
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
    final bool canDelete = review.customerId == user?.id ||
        review.customerId.startsWith('test_user');

    return Column(
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
                radius: 22,
                backgroundColor: AppTheme.gold.withAlpha(10),
                backgroundImage: review.userAvatar != null
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null
                    ? Text(review.userName[0],
                        style: const TextStyle(
                            color: AppTheme.gold, fontWeight: FontWeight.bold))
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  if (review.isVerified)
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          t('verified_purchase'),
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: AppTheme.gold,
                    );
                  }),
                ),
                const SizedBox(height: 2),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(100),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (canDelete)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.redAccent.withAlpha(150), size: 20),
                  onPressed: () => _showDeleteConfirmation(review),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
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
    );
  }

  void _showDeleteConfirmation(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Review',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to remove your review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(120))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(reviewRepositoryProvider).deleteReview(review.id);
              ref.invalidate(productReviewsProvider(widget.productId));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Review deleted'),
                      behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
