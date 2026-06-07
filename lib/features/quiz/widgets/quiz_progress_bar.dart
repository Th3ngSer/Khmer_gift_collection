import 'package:flutter/material.dart';

class QuizProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback onReset;

  const QuizProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    // Calculate progress mathematically to match the smooth React bar
    final progress = (currentStep + 1) / totalSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gift Finder', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: onReset,
                child: Text('Reset', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(goldColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}