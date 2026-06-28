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
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor,
        ),
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
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold.withAlpha(50), width: 1),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.gold.withAlpha(20),
            backgroundImage: NetworkImage(artisan['avatar'] ?? artisan['cover'] ?? 'https://i.pravatar.cc/150'),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (artisan['region'] ?? 'CAMBODIA').toString().toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              artisan['name'] ?? 'Master Artisan',
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Text(
          artisan['craft'] ?? 'Heritage Crafts',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3. Chat Button (Large & Distinct)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
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
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.gold.withAlpha(60), width: 1),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppTheme.gold,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black12,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
