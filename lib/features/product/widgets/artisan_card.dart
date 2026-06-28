import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ArtisanCard extends ConsumerWidget {
  final Map<String, dynamic> artisan;
  final Color goldColor;
  final Map<String, dynamic>? productContext;

  const ArtisanCard({
    super.key,
    required this.artisan,
    required this.goldColor,
    this.productContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Theme.of(context).cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () => context.push(
            "/artisans/${artisan['id']}",
            extra: artisan,
          ),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.gold.withAlpha(20),
            backgroundImage: NetworkImage(
              artisan['avatar'] ?? artisan['cover'] ?? 'https://i.pravatar.cc/150',
            ),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.black12),
            ],
          ),
        ),
      ),
    );
  }
}
