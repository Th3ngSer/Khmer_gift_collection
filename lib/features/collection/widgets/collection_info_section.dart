import 'package:flutter/material.dart';
import '../../../shared/widgets/khmer_divider.dart';

class CollectionInfoSection extends StatelessWidget {
  final String description;
  final int pieceCount;

  const CollectionInfoSection({
    super.key,
    required this.description,
    required this.pieceCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: TextStyle(
              fontSize: 14, 
              height: 1.6, 
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: KhmerDivider(width: 140)),
          ),
          
          Text(
            '$pieceCount pieces in this collection'.toUpperCase(),
            style: TextStyle(
              fontSize: 11, 
              letterSpacing: 2.0, 
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}