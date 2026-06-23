import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArtisanCard extends StatelessWidget {
  final Map<String, dynamic> artisan;
  final Color goldColor;

  const ArtisanCard({
    super.key,
    required this.artisan,
    required this.goldColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/artisans/${artisan['id']}',
        extra: artisan,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'artisan-avatar-${artisan['id']}',
              child: CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(artisan['avatar'] ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (artisan['region'] ?? '').toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.0,
                      color: goldColor,
                    ),
                  ),
                  Text(
                    artisan['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    artisan['craft'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 28),
          ],
        ),
      ),
    );
  }
}
