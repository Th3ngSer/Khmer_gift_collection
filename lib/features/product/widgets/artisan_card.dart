import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../chat_reviews/providers/chat_provider.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push(
          '/artisans/${artisan['id']}',
          extra: artisan,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.gold.withAlpha(20),
          backgroundImage: NetworkImage(artisan['avatar'] ?? artisan['cover'] ?? 'https://i.pravatar.cc/150'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (artisan['region'] ?? 'CAMBODIA').toString().toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: goldColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              artisan['name'] ?? 'Artisan',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'serif'),
            ),
          ],
        ),
        subtitle: Text(
          artisan['craft'] ?? 'Master Artisan',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chat Icon Button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.gold.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.gold, size: 22),
                onPressed: () {
                  final roomId = 'room_${artisan['name']}';
                  ref.read(chatProvider.notifier).initiateChat(
                    roomId, 
                    artisan['name'] ?? 'Artisan', 
                    artisan['avatar'] ?? artisan['cover'] ?? 'https://i.pravatar.cc/150'
                  );
                  context.push('/chat-room/$roomId', extra: {
                    'currentUserId': 'user_123',
                    'artisanName': artisan['name'] ?? 'Artisan',
                    'productContext': productContext,
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black12),
          ],
        ),
      ),
    );
  }
}
