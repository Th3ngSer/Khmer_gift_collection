import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/providers/home_provider.dart';

final quizQuestionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final String response = await rootBundle.loadString(
    'assets/mock/quiz_questions.json',
  );
  return await json.decode(response);
});

class QuizAnswersNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    return {};
  }

  void setAnswer(String questionId, String optionId) {
    state = {...state, questionId: optionId};
  }

  void resetQuiz() {
    state = {};
  }
}

final quizAnswersProvider =
    NotifierProvider<QuizAnswersNotifier, Map<String, String>>(() {
      return QuizAnswersNotifier();
    });

final quizResultsProvider = Provider<Map<String, List<dynamic>>>((ref) {
  final answers = ref.watch(quizAnswersProvider);
  final questionsAsync = ref.watch(quizQuestionsProvider);
  final homeDataAsync = ref.watch(homeFeedProvider);

  if (questionsAsync.value == null || homeDataAsync.value == null) {
    return {'top': [], 'rest': []};
  }

  final questions = questionsAsync.value!;
  final items = homeDataAsync.value!.items;

  // 1. Gather all active target tags selected by the user
  final Set<String> desiredTags = {};
  for (final q in questions) {
    final answerId = answers[q['id']];
    if (answerId != null) {
      final options = q['options'] as List<dynamic>;
      final selectedOpt = options.firstWhere(
        (o) => o['id'] == answerId,
        orElse: () => null,
      );
      if (selectedOpt != null && selectedOpt['tags'] != null) {
        desiredTags.addAll(List<String>.from(selectedOpt['tags']));
      }
    }
  }

  // 2. Score items using a high-fidelity fuzzy matrix
  final List<Map<String, dynamic>> scoredItems = items.map((it) {
    final double price = double.tryParse((it['price'] ?? 0).toString()) ?? 0.0;
    
    // Flatten item attributes into a lowercased search stream
    final List<String> itemAttributes = [
      (it['category'] ?? '').toString().toLowerCase(),
      (it['target_recipient'] ?? '').toString().toLowerCase(),
      (it['material_focus'] ?? '').toString().toLowerCase(),
      (it['stylistic_vibe'] ?? '').toString().toLowerCase(),
      (it['budget_bracket'] ?? '').toString().toLowerCase(),
      (it['description'] ?? '').toString().toLowerCase(),
    ]..removeWhere((attr) => attr.isEmpty);

    final List<String> matchedTags = [];

    for (final desiredTag in desiredTags) {
      final tagLower = desiredTag.toLowerCase().trim();
      bool isMatch = false;

      // Rule A: Cross-attribute partial token string inspection
      if (itemAttributes.any((attr) => attr.contains(tagLower) || tagLower.contains(attr))) {
        isMatch = true;
      }

      // Rule B: Dynamic evaluation for price point bracket queries
      if (tagLower == 'gift-under-50' || tagLower == 'under-50' || tagLower == 'budget') {
        if (price <= 50.0) isMatch = true;
      }

      // Rule C: Dynamic evaluation for luxury parameters
      if (tagLower == 'luxury' || tagLower == 'premium') {
        if (price > 100.0 || itemAttributes.contains('premium') || itemAttributes.contains('luxury')) {
          isMatch = true;
        }
      }

      if (isMatch) {
        matchedTags.add(desiredTag);
      }
    }

    return {
      'item': it,
      'score': matchedTags.length,
      'matched': matchedTags,
    };
  }).toList();

  // 3. Sort prioritized items strictly by match volume first, then break ties using star reviews
  scoredItems.sort((a, b) {
    final scoreComparison = (b['score'] as int).compareTo(a['score'] as int);
    if (scoreComparison != 0) return scoreComparison;
    
    final ratingA = double.tryParse((a['item']['rating'] ?? 0.0).toString()) ?? 0.0;
    final ratingB = double.tryParse((b['item']['rating'] ?? 0.0).toString()) ?? 0.0;
    return ratingB.compareTo(ratingA);
  });

  // 4. Distribute results logically into high-match tiers and fallback recommendations
  final top = scoredItems.where((m) => (m['score'] as int) > 0).take(4).toList();
  
  // If no items match user specifications perfectly, provide highly rated fallbacks
  final rest = top.isEmpty 
      ? scoredItems.take(6).toList()
      : scoredItems.where((m) => !top.contains(m)).take(6).toList();

  return {'top': top, 'rest': rest};
});