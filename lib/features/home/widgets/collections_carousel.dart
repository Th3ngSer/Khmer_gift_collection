import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CollectionsCarousel extends StatelessWidget {
  final List<dynamic> collections;

  const CollectionsCarousel({super.key, required this.collections});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final c = collections[index];
          return GestureDetector(
            onTap: () => context.push('/collections/${c['id']}'),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: NetworkImage(c['cover']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(180), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (c['subtitle'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    Text(
                      c['name'],
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}