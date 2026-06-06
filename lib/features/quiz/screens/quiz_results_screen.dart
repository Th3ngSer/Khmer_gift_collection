// lib/features/quiz/screens/quiz_results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/quiz_provider.dart';
import '../widgets/top_match_card.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/khmer_divider.dart'; // Added Khmer Divider

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
              icon: const Icon(Icons.close), // Swapped back arrow for close (React spec)
              onPressed: () => context.go('/home'), 
            ),
            title: const Text(
              'Your matches',
              style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),

          // 2. Results Intro
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
                  const Center(child: KhmerDivider(width: 140)), // Replaced standard divider
                ],
              ),
            ),
          ),

          // 3. Top Matches List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final match = topMatches[index];
                  return TopMatchCard(
                    item: match['item'],
                    matchedTags: match['matched'] as List<dynamic>,
                    onTap: () => context.push('/products/${match['item']['id']}'),
                  );
                },
                childCount: topMatches.length,
              ),
            ),
          ),

          // 4. Secondary Recommendations Grid
          if (restMatches.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: SectionHeader(
                  title: 'Also worth a look',
                  subtitle: 'Great alternatives based on your profile',
                ),
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
                    return ProductCard(item: restMatches[index]['item']);
                  },
                  childCount: restMatches.length,
                ),
              ),
            ),
          ],

          // 5. Retake Quiz Action
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: OutlinedButton(
                onPressed: () {
                  ref.read(quizAnswersProvider.notifier).resetQuiz();
                  context.pushReplacement('/quiz'); 
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