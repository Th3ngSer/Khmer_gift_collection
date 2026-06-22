
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../chat_reviews/providers/chat_provider.dart';

class ArtisanProfileScreen extends ConsumerWidget {
  final Map<String, dynamic> artisanData;

  const ArtisanProfileScreen({super.key, required this.artisanData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warm Earth Tones & Gold Highlights
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.3),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                onPressed: () {
                  final roomId = 'room_${artisanData['name']}';
                  ref.read(chatProvider.notifier).initiateChat(
                    roomId, 
                    artisanData['name'] ?? 'Artisan', 
                    artisanData['avatar'] ?? artisanData['cover'] ?? 'https://i.pravatar.cc/150'
                  );
                  context.push('/chat-room/$roomId', extra: {
                    'currentUserId': 'user_123',
                    'artisanName': artisanData['name'] ?? 'Artisan',
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Profile Banner with Gradient Overlay
            Stack(
              children: [
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        artisanData['photo_url'] ??
                        artisanData['cover'] ??
                        artisanData['avatar'] ??
                        'https://via.placeholder.com/400'
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 320,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisanData['shop_name'] ?? artisanData['name'] ?? 'Master Craftsman',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artisanData['craft_type'] ?? artisanData['craft'] ?? 'Handmade Crafts',
                        style: const TextStyle(
                          color: goldColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Region Badge & Cultural Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: goldColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: goldColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: goldColor),
                            const SizedBox(width: 4),
                            Text(
                              artisanData['region'] ?? 'Cambodia',
                              style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: KhmerDivider(width: 150)),
                  ),

                  // Cultural Story Biography Section
                  const Text(
                    "Our Heritage & Story",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    artisanData['story'] ?? 'Dedicated to preserving traditional Khmer techniques and supporting local communities through sustainable craftsmanship.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black.withOpacity(0.75),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: KhmerDivider(width: 150)),
                  ),

                  // Grid of Creations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Crafted Masterpieces",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        "${(artisanData['products'] as List? ?? []).length} items",
                        style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Grid showing items created by this artisan
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: (artisanData['products'] as List? ?? []).length,
                    itemBuilder: (context, index) {
                      final product = artisanData['products'][index];
                      // FIXED: Reusing the standard product card widget with correct 'item' parameter
                      return ProductCard(item: product);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}