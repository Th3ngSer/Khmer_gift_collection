import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(String questionId, String optionId, int totalQuestions) {
    // 1. Save the answer to Riverpod
    ref.read(quizAnswersProvider.notifier).setAnswer(questionId, optionId);

    // 2. Animate to next question OR go to results
    if (_currentIndex < totalQuestions - 1) {
      setState(() => _currentIndex++);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Quiz complete! Route to the results dashboard
      context.push('/quiz/results'); // We will build this next!
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(quizQuestionsProvider);
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (err, stack) => Center(child: Text('Error loading quiz: $err')),
        data: (questions) {
          if (questions.isEmpty) return const Center(child: Text('No questions found.'));

          return SafeArea(
            child: Column(
              children: [
                // 1. Top Navigation & Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          ref.read(quizAnswersProvider.notifier).resetQuiz();
                          context.pop();
                        },
                      ),
                      Expanded(
                        child: Row(
                          children: List.generate(
                            questions.length,
                            (index) => Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: index <= _currentIndex
                                      ? goldColor
                                      : Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balances the close button for centering
                    ],
                  ),
                ),

                // 2. The Interactive PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe, force option tap
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      final options = q['options'] as List<dynamic>;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step ${index + 1} of ${questions.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: 2.0,
                                color: goldColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              q['prompt'],
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q['subtitle'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const Spacer(),

                            // 3. The Animated Options
                            ...options.map((opt) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () => _handleOptionSelected(q['id'], opt['id'], questions.length),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          opt['label'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const Spacer(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}