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
          final trending = data.items.take(4).toList();
          final recommended = data.items.reversed.take(4).toList();
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
                    _buildStoryRail(context, ref, activeStories,
                        userRoleAsync.value ?? 'customer'),

                    // 3. Gift Finder CTA
                    _buildGiftFinderCTA(context, t),

                    // 4. Categories Chips
                    _buildCategories(context, data.categories),

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

  Widget _buildStoryRail(BuildContext context, WidgetRef ref,
      List<Map<String, dynamic>> stories, String role) {
    const goldColor = Color(0xFFD4AF37);
    final isArtisan = role == 'artisan';

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: stories.length + (isArtisan ? 1 : 0),
        itemBuilder: (context, index) {
          // Render the creation slot first for artisans
          if (isArtisan && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _showAddStorySheet(context, ref),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200),
                          child: const CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.palette_outlined,
                                color: Color(0xFF8C2D19)),
                          ),
                        ),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: goldColor,
                            child:
                                Icon(Icons.add, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Add Story',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }

          final storyIndex = isArtisan ? index - 1 : index;
          final story = stories[storyIndex];

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        StoryViewer(stories: stories, initialIndex: storyIndex),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        Color(0xFF8C2D19),
                        goldColor,
                        Color(0xFF8C2D19)
                      ]),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).scaffoldBackgroundColor),
                      child: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(story['avatar'])),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(story['label'],
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(200))),
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
  void _showAddStorySheet(BuildContext context, WidgetRef ref) {
  final urlController = TextEditingController();
  final captionController = TextEditingController();
  bool isPosting = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Creative Process', style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'Story Image URL',
                hintText: 'https://images.unsplash.com/...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: captionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Story Caption / Legend',
                hintText: 'Describe what you are working on today...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C2D19), foregroundColor: Colors.white),
                onPressed: isPosting ? null : () async {
                  if (urlController.text.trim().isEmpty) return;
                  setSheetState(() => isPosting = true);

                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    try {
                      await Supabase.instance.client.from('artisans').update({
                        'latest_story_url': urlController.text.trim(),
                        'story_caption': captionController.text.trim(),
                        'story_created_at': DateTime.now().toIso8601String(),
                      }).eq('id', user.id);

                      ref.invalidate(homeFeedProvider); // Refresh layout stream
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setSheetState(() => isPosting = false);
                    }
                  }
                },
                child: isPosting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Publish Story', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
