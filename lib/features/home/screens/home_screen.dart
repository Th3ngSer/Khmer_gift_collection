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
          final activeSort = ref.watch(homeSortProvider);

          List<dynamic> filteredItems = selectedCategory == null
              ? List.from(data.items)
              : data.items
                  .where((item) => item['category'] == selectedCategory)
                  .toList();

          if (activeSort == ProductSortOrder.priceLowToHigh) {
            filteredItems.sort((a, b) {
              final priceA =
                  double.tryParse((a['price'] ?? 0).toString()) ?? 0.0;
              final priceB =
                  double.tryParse((b['price'] ?? 0).toString()) ?? 0.0;
              return priceA.compareTo(priceB);
            });
          } else if (activeSort == ProductSortOrder.priceHighToBottom) {
            filteredItems.sort((a, b) {
              final priceA =
                  double.tryParse((a['price'] ?? 0).toString()) ?? 0.0;
              final priceB =
                  double.tryParse((b['price'] ?? 0).toString()) ?? 0.0;
              return priceB.compareTo(priceA);
            });
          } else {
            filteredItems.sort((a, b) {
              final ratingA =
                  double.tryParse((a['rating'] ?? 0).toString()) ?? 0.0;
              final ratingB =
                  double.tryParse((b['rating'] ?? 0).toString()) ?? 0.0;
              return ratingB.compareTo(ratingA); // Highest rating first
            });
          }

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
                      locale == 'km' ? 'សូមស្វាគមន៍' : 'WELCOME TO',
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

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${t('Sort by') ?? 'Sort'}: ',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      _buildSortChip(ref, context, 'Popular',
                          ProductSortOrder.defaultOrder, activeSort),
                      const SizedBox(width: 6),
                      _buildSortChip(ref, context, '\$ Low-High',
                          ProductSortOrder.priceLowToHigh, activeSort),
                      const SizedBox(width: 6),
                      _buildSortChip(ref, context, '\$ High-Low',
                          ProductSortOrder.priceHighToBottom, activeSort),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => context.go('/explore'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: SectionHeader(
                      title: t('trending_now'),
                      subtitle: t('loved_week'),
                    ),
                  ),
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

              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => context.go('/explore'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: SectionHeader(title: t('recommended_for_you')),
                  ),
                ),
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

  Widget _buildSortChip(WidgetRef ref, BuildContext context, String label,
      ProductSortOrder order, ProductSortOrder currentActive) {
    final isSelected = currentActive == order;
    return InkWell(
      onTap: () => ref.read(homeSortProvider.notifier).changeSortOrder(order),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFC05E3D)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC05E3D)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
