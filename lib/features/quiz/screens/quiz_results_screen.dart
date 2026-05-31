import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/quiz_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/section_header.dart';

class QuizResultsScreen extends ConsumerWidget {
  const QuizResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(quizResultsProvider);
    final topMatches = results['top'] ?? [];
    final restMatches = results['rest'] ?? [];
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. Screen Header
          SliverAppBar(
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'), 
            ),
            title: const Text(
              'Your matches',
              style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURATED FOR YOU',
                    style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: goldColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "The pieces we'd pick for them",
                    style: TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on your answers about recipient, occasion, budget and style.',
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: goldColor.withOpacity(0.3)),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final match = topMatches[index];
                  final item = match['item'];
                  final matchedTags = match['matched'] as List<dynamic>;

                  return GestureDetector(
                    onTap: () => context.push('/products/${item['id']}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item['cover'] ?? '',
                              height: 96,
                              width: 96,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item['category'] ?? '').toString().toUpperCase(),
                                  style: const TextStyle(fontSize: 10, letterSpacing: 2.0, color: goldColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${item['price']}',
                                      style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      matchedTags.isNotEmpty 
                                          ? 'Matches: ${matchedTags.take(2).join(', ')}' 
                                          : 'Featured',
                                      style: TextStyle(
                                        fontSize: 10, 
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: topMatches.length,
              ),
            ),
          ),

          if (restMatches.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Also worth a look',
                subtitle: 'Great alternatives based on your profile',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.60,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Extract just the item data to feed our shared ProductCard
                    return ProductCard(item: restMatches[index]['item']);
                  },
                  childCount: restMatches.length,
                ),
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: OutlinedButton(
                onPressed: () {
                  ref.read(quizAnswersProvider.notifier).resetQuiz();
                  context.pushReplacement('/quiz'); // Replaces current screen with a fresh quiz
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: const Text('Retake the quiz', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}