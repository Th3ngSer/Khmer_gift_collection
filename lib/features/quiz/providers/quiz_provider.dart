import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/providers/home_provider.dart'; // To access the inventory

// --- 1. Load the Questions ---
final quizQuestionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final String response = await rootBundle.loadString('assets/mock/quiz_questions.json');
  return await json.decode(response);
});

// --- 2. Track User Answers ---
// This acts like your Zustand store, holding a map of {questionId: selectedOptionId}
class QuizAnswersNotifier extends StateNotifier<Map<String, String>> {
  QuizAnswersNotifier() : super({});

  void setAnswer(String questionId, String optionId) {
    state = {...state, questionId: optionId};
  }

  void resetQuiz() {
    state = {};
  }
}

final quizAnswersProvider = StateNotifierProvider<QuizAnswersNotifier, Map<String, String>>((ref) {
  return QuizAnswersNotifier();
});

// --- 3. The Recommendation Algorithm ---
// This perfectly mirrors your React `quiz.results.tsx` logic!
final quizResultsProvider = Provider<Map<String, List<dynamic>>>((ref) {
  final answers = ref.watch(quizAnswersProvider);
  final questionsAsync = ref.watch(quizQuestionsProvider);
  final homeDataAsync = ref.watch(homeFeedProvider);

  // If data isn't loaded yet, return empty arrays to prevent crashes
  if (questionsAsync.value == null || homeDataAsync.value == null) {
    return {'top': [], 'rest': []};
  }

  final questions = questionsAsync.value!;
  final items = homeDataAsync.value!.items;

  // A. Extract desired tags based on user's answers
  final Set<String> desiredTags = {};
  for (final q in questions) {
    final answerId = answers[q['id']];
    if (answerId != null) {
      final options = q['options'] as List<dynamic>;
      final selectedOpt = options.firstWhere((o) => o['id'] == answerId, orElse: () => null);
      if (selectedOpt != null && selectedOpt['tags'] != null) {
        desiredTags.addAll(List<String>.from(selectedOpt['tags']));
      }
    }
  }

  final mockTagsList = ['her', 'him', 'luxury', 'elegant', 'traditional', 'modern', 'gift-under-50'];

  final List<Map<String, dynamic>> scoredItems = items.map((it) {
    final List<String> itemTags = it['tags'] != null 
        ? List<String>.from(it['tags']) 
        : [mockTagsList[items.indexOf(it) % mockTagsList.length], 'elegant'];

    final matchedTags = itemTags.where((t) => desiredTags.contains(t)).toList();
    
    return {
      'item': it,
      'score': matchedTags.length,
      'matched': matchedTags,
    };
  }).toList();

  scoredItems.sort((a, b) {
    final scoreComparison = (b['score'] as int).compareTo(a['score'] as int);
    if (scoreComparison != 0) return scoreComparison;
    
    final ratingA = a['item']['rating'] ?? 0.0;
    final ratingB = b['item']['rating'] ?? 0.0;
    return ratingB.compareTo(ratingA);
  });

  final top = scoredItems.take(4).toList();
  final rest = scoredItems.skip(4).take(6).toList();

  return {
    'top': top,
    'rest': rest,
  };
});