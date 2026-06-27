import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../chat_reviews/providers/chat_provider.dart';
import '../../../core/theme/app_theme.dart';

class ArtisanInfoCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> artisan;
  final int worksCount;

  const ArtisanInfoCard({
    super.key,
    required this.artisan,
    required this.worksCount,
  });

  @override
  ConsumerState<ArtisanInfoCard> createState() => _ArtisanInfoCardState();
}

class _ArtisanInfoCardState extends ConsumerState<ArtisanInfoCard> {
  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final theme = Theme.of(context);
    final a = widget.artisan;
    final favsState = ref.watch(favoritesProvider);
    final bool isFav = favsState.artisans.contains(a['id'].toString());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: goldColor, width: 2),
                ),
                child: Hero(
                  tag: 'artisan-avatar-${a['id']}',
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(a['avatar']),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          (a['region'] ?? '').toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.0,
                            color: goldColor,
                            fontWeight:
                                FontWeight.bold, 
                          ),
                        ),
                        if (a['latitude'] != null &&
                            a['longitude'] != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => context.go('/map', extra: {
                              'lat': a['latitude'],
                              'lng': a['longitude'],
                            }),
                            child: const Icon(Icons.location_pin,
                                size: 12, color: goldColor),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a['name'],
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a['craft']} · Est. ${a['established']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // NEW: Direct Chat Room Routing CTA Button
              IconButton(
                onPressed: () => context.push('/chat/${a['id']}', extra: a),
                icon: const Icon(Icons.chat_bubble_outline, color: goldColor),
                style: IconButton.styleFrom(
                  backgroundColor: theme.dividerColor.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 8),

              IconButton(
                onPressed: () {
                  ref
                      .read(favoritesProvider.notifier)
                      .toggleArtisan(a['id'].toString());
                },
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? goldColor : theme.iconTheme.color,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.dividerColor.withAlpha(25),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final roomId = 'room_${a['name']}';
                  ref.read(chatProvider.notifier).initiateChat(
                    roomId, 
                    a['name'] ?? 'Artisan', 
                    a['avatar'] ?? a['cover'] ?? 'https://i.pravatar.cc/150'
                  );
                  context.push('/chat-room/$roomId', extra: {
                    'currentUserId': 'user_123',
                    'artisanName': a['name'] ?? 'Artisan',
                  });
                },
                icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.gold),
                style: IconButton.styleFrom(
                  backgroundColor: theme.dividerColor.withAlpha(25),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: goldColor, size: 16),
              const SizedBox(width: 4),
              Text(
                a['rating'].toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                ' · ${widget.worksCount} works',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Row 3: Narrative
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: KhmerDivider(width: 140)),
          ),
          Text(
            a['bio'],
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            a['story'],
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 28),
          const Text(
            'From the workshop',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
