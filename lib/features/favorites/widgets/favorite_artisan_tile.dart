import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FavoriteArtisanTile extends StatelessWidget {
  final Map<String, dynamic> artisan;

  const FavoriteArtisanTile({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => context.push('/artisans/${artisan['id']}'),
        leading: Hero(
          tag:
              'artisan-avatar-${artisan['id']}', // Matches Artisan Profile anchor
          child: CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(artisan['avatar']),
          ),
        ),
        title: Text(
          artisan['name'],
          style: const TextStyle(
              fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${artisan['craft'] ?? 'Master Artisan'}   ${artisan['region'] ?? 'Cambodia'}',
          style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 14, color: theme.dividerColor),
      ),
    );
  }
}
