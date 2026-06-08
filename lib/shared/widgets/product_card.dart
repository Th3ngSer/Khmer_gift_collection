import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/favorites/providers/favorites_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;

  const ProductCard({super.key, required this.item});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  @override
  Widget build(BuildContext context) {
    final favsState = ref.watch(favoritesProvider);
    final bool isFav = favsState.items.contains(widget.item['id'].toString());
    // Fallback rating since our Supabase mock data didn't explicitly include one
    final double rating = widget.item['rating'] ?? 4.8;

    return GestureDetector(
      onTap: () => context.push('/products/${widget.item['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image & Heart Button
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.item['cover'] ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(favoritesProvider.notifier)
                          .toggleItem(widget.item['id'].toString());
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withOpacity(0.85),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFav
                            ? const Color(0xFFD4AF37)
                            : Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Title & Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.item['name'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${widget.item['price']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 3. Rating & Category Row
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Color(0xFFD4AF37)),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  ' · ',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.item['category'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
