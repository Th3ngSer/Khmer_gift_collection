import 'package:flutter/material.dart';
import '../../../shared/widgets/khmer_divider.dart';

class ArtisanInfoCard extends StatefulWidget {
  final Map<String, dynamic> artisan;
  final int worksCount;

  const ArtisanInfoCard({super.key, required this.artisan, required this.worksCount});

  @override
  State<ArtisanInfoCard> createState() => _ArtisanInfoCardState();
}

class _ArtisanInfoCardState extends State<ArtisanInfoCard> {
  bool _isFav = false;

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final theme = Theme.of(context);
    final a = widget.artisan;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar, Details, and Favorite Button
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: goldColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(a['avatar']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (a['region'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(fontSize: 10, letterSpacing: 2.0, color: goldColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a['name'],
                      style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold, height: 1.1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a['craft']} · Est. ${a['established']}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isFav = !_isFav),
                icon: Icon(
                  _isFav ? Icons.favorite : Icons.favorite_border,
                  color: _isFav ? theme.colorScheme.primary : theme.iconTheme.color,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.dividerColor.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          
          // Row 2: Metrics
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: goldColor, size: 16),
              const SizedBox(width: 4),
              Text(
                a['rating'].toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                ' · ${widget.worksCount} works',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
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
            style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 12),
          Text(
            a['story'],
            style: TextStyle(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          
          const SizedBox(height: 28),
          const Text(
            'From the workshop',
            style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}