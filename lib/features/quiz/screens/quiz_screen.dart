import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/quiz_provider.dart';
import '../widgets/quiz_option_button.dart';
import '../widgets/quiz_progress_bar.dart';

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

  void _nextStep(int totalQuestions) {
    if (_currentIndex < totalQuestions - 1) {
      setState(() => _currentIndex++);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.push('/quiz/results');
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(quizQuestionsProvider);
    final answers = ref.watch(quizAnswersProvider); // Watch the active answers
    const goldColor = Color(0xFFD4AF37);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Add a standard Back button to the AppBar if they want to leave the quiz entirely
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(quizAnswersProvider.notifier).resetQuiz();
            context.pop();
          },
        ),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (err, stack) => Center(child: Text('Error loading quiz: $err')),
        data: (questions) {
          if (questions.isEmpty) return const Center(child: Text('No questions found.'));

          return Column(
            children: [
              // Extracted Progress Bar Component
              QuizProgressBar(
                totalSteps: questions.length,
                currentStep: _currentIndex,
                onReset: () {
                  ref.read(quizAnswersProvider.notifier).resetQuiz();
                  setState(() => _currentIndex = 0);
                  _pageController.jumpToPage(0);
                },
              ),

              // The Interactive PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    final options = q['options'] as List<dynamic>;
                    final selectedAnswerId = answers[q['id']]; // Look up the saved answer

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personalized Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            margin: const EdgeInsets.bottom(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 14, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'personalized',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            q['prompt'],
                            style: const TextStyle(fontFamily: 'serif', fontSize: 32, fontWeight: FontWeight.w600, height: 1.1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            q['subtitle'],
                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          
                          const SizedBox(height: 24),

                          // Render Extracted Option Buttons
                          ...options.map((opt) {
                            return QuizOptionButton(
                              label: opt['label'],
                              isSelected: selectedAnswerId == opt['id'],
                              onTap: () {
                                ref.read(quizAnswersProvider.notifier).setAnswer(q['id'], opt['id']);
                                // Optional: Auto-advance after a tiny delay like React
                                Future.delayed(const Duration(milliseconds: 200), () => _nextStep(questions.length));
                              },
                            );
                          }),
                          
                          const Spacer(),

                          // Bottom Actions (Back / Next)
                          Row(
                            children: [
                              if (index > 0) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _previousStep,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                    child: const Text('Back'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: selectedAnswerId != null ? () => _nextStep(questions.length) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: Text(
                                    index < questions.length - 1 ? 'Next' : 'See results',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}