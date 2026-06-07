import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EmptyFavorites extends StatelessWidget {
  final String message;

  const EmptyFavorites({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const goldColor = Color(0xFFD4AF37);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: goldColor.withOpacity(0.1), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Icon(Icons.favorite_border, size: 48, color: theme.dividerColor),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_forward, size: 16, color: goldColor),
            label: const Text(
              'Browse the collection',
              style: TextStyle(color: goldColor, letterSpacing: 1.0, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}