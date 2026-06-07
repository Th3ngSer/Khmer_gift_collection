import 'package:flutter/material.dart';

class TopMatchCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final List<dynamic> matchedTags;
  final VoidCallback onTap;

  const TopMatchCard({
    super.key,
    required this.item,
    required this.matchedTags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
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
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 96,
                  width: 96,
                  color: Colors.grey[900],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                ),
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
                  const SizedBox(height: 4),
                  Text(
                    item['tagline'] ?? '',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
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
                          color: theme.colorScheme.onSurface.withOpacity(0.5)
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
  }
}