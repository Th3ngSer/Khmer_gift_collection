import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductBottomCTA extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Copying the public property to a local variable allows Dart to promote its type
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
          OutlinedButton(
            onPressed: onFavPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(isFav ? 'Saved' : 'Save'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: localItem == null
                  ? null
                  : () => context.push('/booking/${localItem['id']}'), 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C2D19),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                localItem != null ? 'Order — \$${localItem['price']}' : 'Loading...', 
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}