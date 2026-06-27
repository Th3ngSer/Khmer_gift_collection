import 'package:flutter/material.dart';

class ErrorPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? title;

  const ErrorPlaceholder({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    const terracottaColor = Color(0xFF8C2D19);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0), // FIX: Correctly placed inside a Padding widget
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Cultural/Thematic Error Icon Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: terracottaColor.withAlpha(isDarkMode ? 40 : 15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: goldColor.withAlpha(100),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: terracottaColor,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),

            // 2. Error Title
            Text(
              title ?? 'សូមអភ័យទោស · Connection Issue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),

            // 3. Error Description Message
            Text(
              _getFriendlyMessage(message),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // 4. Retry Action Call-To-Action Button
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: terracottaColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFriendlyMessage(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('xmlhttprequest') || lower.contains('socketexception') || lower.contains('failed host')) {
      return 'Unable to connect to the artisan network. Please check your internet connection and try again.';
    }
    if (lower.contains('jwt') || lower.contains('auth') || lower.contains('403')) {
      return 'Your session has timed out security parameters. Please verify your profile authorization.';
    }
    return rawError;
  }
}