import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../widgets/story_viewer.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/constants/translations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/error_placeholder.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeFeedProvider);
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
          final categories =
              data.items.map((i) => i['category'].toString()).toSet().toList();
          final trending = data.items.take(4).toList();
          final recommended = data.items.reversed.take(4).toList();
          final finalCategories = categories.isEmpty
              ? ['Textile', 'Silver', 'Wood', 'Edible', 'Jewelry']
              : categories;
          final stories = [
            ...data.artisans.map((a) => {
                  'image': a['story_post_image'] ?? a['cover'] ?? '',
                  'title': a['name'] ?? '',
                  'subtitle': '${a['craft']} · ${a['region']}',
                  'caption': a['story'] ?? '',
                  'avatar': a['avatar'] ?? a['cover'] ?? '',
                  'label': (a['name'] ?? '').toString().split(' ').first,
                }),
            ...data.promotions.take(2).map((p) => {
                  'image': p['image'] ?? '',
                  'title': p['title'] ?? '',
                  'subtitle': p['subtitle'] ?? '',
                  'caption': p['cta'] ?? '',
                  'avatar': p['image'] ?? '',
                  'label': p['badge'] ?? '',
                  'linkCollectionId': p['linkCollectionId'],
                }),
          ];

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
                    onPressed: () {}, // Search action
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => context.push('/chat'), // Nav to chat
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Story Rail (Avatars)
                    _buildStoryRail(context, stories),

                    // 3. Gift Finder CTA
                    _buildGiftFinderCTA(context, t),

                    // 4. Categories Chips
                    _buildCategories(context, finalCategories),

                    // 5. Featured Collections Carousel
                    SectionHeader(
                      title: t('featured_collections'),
                      subtitle: t('curated_season'),
                    ),
                    _buildCollectionsCarousel(context, data.collections),

                    // --- Workshop Reels CTA ---
                    _buildWorkshopReelsCTA(context, t),
                  ],
                ),
              ),

              // 6. Trending Grid
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
                    // 7. Artisan Spotlight
                    SectionHeader(
                      title: t('meet_makers'),
                      subtitle: t('stories_workshop'),
                    ),
                    _buildArtisanCarousel(context, data.artisans),

                    // 8. Promo Banner
                    if (data.promotions.isNotEmpty)
                      _buildPromoBanner(context, data.promotions.first),
                  ],
                ),
              ),

              // 9. Recommended Grid
              SliverToBoxAdapter(
                child: SectionHeader(title: t('recommended_for_you')),
              ),
              _buildProductGrid(recommended),

              // 10. Footer
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

  Widget _buildStoryRail(
      BuildContext context, List<Map<String, dynamic>> stories) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        StoryViewer(stories: stories, initialIndex: index),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8C2D19),
                          Color(0xFFD4AF37),
                          Color(0xFF8C2D19)
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(story['avatar']),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story['label'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGiftFinderCTA(BuildContext context, String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.push('/quiz'),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8C2D19), Color(0xFF6B2213)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withAlpha(240),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Color(0xFF8C2D19)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('find_perfect_gift'),
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            t('quiz_sub'),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withAlpha(50),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context, List<String> categories) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(categories[index],
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
              backgroundColor: Theme.of(context).cardColor,
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionsCarousel(
      BuildContext context, List<dynamic> collections) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final c = collections[index];
          return GestureDetector(
            onTap: () => context.push('/collections/${c['id']}'),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: NetworkImage(c['cover']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(180), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (c['subtitle'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    Text(
                      c['name'],
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtisanCarousel(BuildContext context, List<dynamic> artisans) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artisans.length,
        itemBuilder: (context, index) {
          final a = artisans[index];
          return GestureDetector(
            onTap: () => context.push('/artisans/${a['id']}', extra: a),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: NetworkImage(a['cover']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(200), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (a['region'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    Text(
                      a['name'],
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      a['craft'] ?? '',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkshopReelsCTA(
      BuildContext context, String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => context.push('/reels'),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage(
                  'https://assets.mixkit.com/videos/preview/mixkit-weaving-silk-on-a-loom-41584-0.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.black.withAlpha(150), Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.gold.withAlpha(100),
                          blurRadius: 15,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('workshop_live'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        t('watch_how_made'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context, dynamic promo) {
    return GestureDetector(
      onTap: () => context.push('/collections/${promo['linkCollectionId']}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(promo['image']),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                Colors.black.withAlpha(180),
                Colors.black.withAlpha(76),
                Colors.transparent
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.66,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (promo['badge'] ?? '').toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.0,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  promo['title'],
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  promo['subtitle'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
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
