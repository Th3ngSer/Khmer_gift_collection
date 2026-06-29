import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../order/providers/cart_provider.dart';
import '../../../data/models/cart_item.dart';

/// Bottom bar on the Product Detail screen.
/// "Save" toggles favourite; "Add to Cart" adds the item and shows a
/// confirmation snack-bar with a shortcut to the cart.
class ProductBottomCTA extends ConsumerWidget {
  final Map<String, dynamic>? item;
  final bool isFav;
  final VoidCallback onFavPressed;

  const ProductBottomCTA({
    super.key,
    required this.item,
    required this.isFav,
    required this.onFavPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localItem = item;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // ── Save / Favourite button ──────────────────────────────────────
          OutlinedButton(
            onPressed: onFavPressed,
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(isFav ? 'Saved ♥' : 'Save'),
          ),
          const SizedBox(width: 16),

          // ── Add to Cart button ───────────────────────────────────────────
          Expanded(
            child: ElevatedButton(
              onPressed: localItem == null
                  ? null
                  : () => _addToCart(context, ref, localItem),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C2D19),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                localItem != null
                    ? 'Add to Cart — \$${localItem['price']}'
                    : 'Loading...',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(
      BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    // Build a CartItem from the product map
    final cartItem = CartItem(
      id: '${item['id']}_${DateTime.now().millisecondsSinceEpoch}',
      productId: item['id'].toString(),
      name: item['name'] ?? '',
      price: (item['price'] ?? 0).toDouble(),
      quantity: 1,
      imageUrl: item['cover'] ?? '',
    );

    ref.read(cartProvider.notifier).addItem(cartItem);

    // Show a snack-bar with a "View Cart" action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item['name']} added to cart'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: const Color(0xFFD4AF37),
          onPressed: () => context.push('/cart'),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}