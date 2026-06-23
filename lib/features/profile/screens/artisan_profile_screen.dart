import 'package:flutter/material.dart';
import '../../../shared/widgets/khmer_divider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../artisan/providers/artisan_provider.dart';
import '../../artisan/widgets/edit_artisan_sheet.dart';
import '../../artisan/widgets/upload_product_sheet.dart';

class ArtisanProfileScreen extends ConsumerWidget {
  final Map<String, dynamic> artisanData;

  const ArtisanProfileScreen({super.key, required this.artisanData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Warm Earth Tones & Gold Highlights
    const goldColor = Color(0xFFD4AF37);
    final artisanId =
        (artisanData['id'] ?? Supabase.instance.client.auth.currentUser?.id)
            .toString();

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
                      image: NetworkImage(artisanData['photo_url'] ??
                          artisanData['cover_photo_url'] ??
                          artisanData['cover'] ??
                          artisanData['avatar'] ??
                          artisanData['profile_photo_url'] ??
                          'https://via.placeholder.com/400'),
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
                        artisanData['shop_name'] ??
                            artisanData['name'] ??
                            'Master Craftsman',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artisanData['craft_type'] ??
                            artisanData['craft'] ??
                            'Handmade Crafts',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: goldColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: goldColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: goldColor),
                            const SizedBox(width: 4),
                            Text(
                              artisanData['region'] ?? 'Cambodia',
                              style: const TextStyle(
                                  color: goldColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
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
                    artisanData['story'] ?? artisanData['heritage_story'] ??
                        'Dedicated to preserving traditional Khmer techniques and supporting local communities through sustainable craftsmanship.',
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
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.4), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24)),
                              ),
                              builder: (context) =>
                                  EditArtisanSheet(artisan: artisanData),
                            );
                          },
                          icon: const Icon(Icons.edit_note,
                              size: 18, color: goldColor),
                          label: const Text(
                            'Edit Profile/Story',
                            style: TextStyle(
                                color: goldColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: goldColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24)),
                              ),
                              builder: (context) =>
                                  UploadProductSheet(artisanId: artisanId),
                            );
                          },
                          icon: const Icon(Icons.library_add,
                              size: 18, color: goldColor),
                          label: const Text(
                            'Add Item for Sale',
                            style: TextStyle(
                                color: goldColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: goldColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: KhmerDivider(width: 150)),
                  ),

                  // Grid showing items created by this artisan
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
