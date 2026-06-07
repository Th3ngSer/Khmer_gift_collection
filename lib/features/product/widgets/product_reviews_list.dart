import 'package:flutter/material.dart';

class ProductReviewsList extends StatelessWidget {
  final List<dynamic> reviews;
  final Color goldColor;

  const ProductReviewsList({
    super.key,
    required this.reviews,
    required this.goldColor,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Text("No reviews yet. Be the first to order!");
    }

    return Column(
      children: reviews.map((r) {
        final rating = r['rating'] as int? ?? 5;
        final email = r['users']?['email'] ?? 'Anonymous';
        final username = email.toString().split('@').first;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: goldColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (r['review_text'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    r['review_text'],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}