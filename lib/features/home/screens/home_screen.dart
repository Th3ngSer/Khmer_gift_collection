import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/constants/translations.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/error_placeholder.dart';

// Modular Widgets
import '../widgets/story_rail.dart';
import '../widgets/gift_finder_cta.dart';
import '../widgets/category_list.dart';
import '../widgets/collections_carousel.dart';
import '../widgets/workshop_reels_cta.dart';
import '../widgets/artisan_carousel.dart';
import '../widgets/promo_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeFeedProvider);
    final userRoleAsync = ref.watch(userRoleProvider);
    final locale = ref.watch(localeProvider).languageCode;
    const goldColor = Color(0xFFD4AF37);

    String t(String key) => Translations.translate(key, locale);

    return Scaffold(
      body: homeData.when(
        loading: () => const LoadingShimmer(),
        error: (err, stack) => ErrorPlaceholder(
          message: err.toString(),
          onRetry: () => ref.invalidate(homeFeedProvider),
        ),
        data: (data) {
          final selectedCategory = ref.watch(selectedCategoryProvider);

          final filteredItems = selectedCategory == null
              ? data.items
              : data.items
                  .where((item) => item['category'] == selectedCategory)
                  .toList();

          final trending = filteredItems.take(4).toList();
          final recommended = filteredItems.reversed.take(4).toList();

          final activeStories = data.artisans
              .where((a) => a['has_active_story'] == true)
              .map((a) => {
                    'image': a['story_post_image'],
                    'title': a['name'] ?? '',
                    'subtitle': 'Master Artisan',
                    'caption': a['story_text'] ?? '',
                    'avatar': a['avatar'],
                    'label': (a['name'] ?? '').toString().split(' ').first,
                  })
              .toList();

          return CustomScrollView(
            slivers: [
              // 1. Top Bar (App Bar)
              SliverAppBar(
                floating: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale == 'km'
                          ? 'សួស្តី'
                          : 'សួស្តី · ${t('welcome_greeting')}',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      t('gift_and_souvenir'),
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => context.push('/chat'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Story Rail (Avatars)
                    StoryRail(
                      stories: activeStories,
                      role: userRoleAsync.value ?? 'customer',
                    ),

                    // 3. Gift Finder CTA
                    const GiftFinderCTA(),

                    // 4. Categories Chips
                    CategoryList(categories: data.categories),

                    // 5. Featured Collections Carousel
                    SectionHeader(
                      title: t('featured_collections'),
                      subtitle: t('curated_season'),
                    ),
                    CollectionsCarousel(collections: data.collections),

                    // 6. Workshop Reels CTA
                    const WorkshopReelsCTA(),
                  ],
                ),
              ),

              // 7. Trending Grid
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: t('trending_now'),
                  subtitle: t('loved_week'),
                ),
              ),
              _buildProductGrid(trending),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 8. Artisan Spotlight
                    SectionHeader(
                      title: t('meet_makers'),
                      subtitle: t('stories_workshop'),
                    ),
                    ArtisanCarousel(artisans: data.artisans),

                    // 9. Promo Banner
                    if (data.promotions.isNotEmpty)
                      PromoBanner(promo: data.promotions.first),
                  ],
                ),
              ),

              // 10. Recommended Grid
              SliverToBoxAdapter(
                child: SectionHeader(title: t('recommended_for_you')),
              ),
              _buildProductGrid(recommended),

              // 11. Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 24),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 160,
                        child: KhmerDivider(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t('handmade_cambodia'),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(128),
                        ),
                      ),
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

  Widget _buildProductGrid(List<dynamic> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.60,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ProductCard(item: items[index]);
          },
          childCount: items.length,
        ),
      ),
    );
  }
}
