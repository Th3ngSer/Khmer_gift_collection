import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/promo_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/constants/translations.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(activePromotionsProvider);
    final locale = ref.watch(localeProvider).languageCode;
    const goldColor = Color(0xFFD4AF37);
    const deepBrown = Color(0xFF2A1508);

    String t(String key) => Translations.translate(key, locale);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepBrown),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t('promotions_title'), // Need to add this to translations
          style: const TextStyle(
            color: deepBrown,
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: promosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (promos) {
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.black.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    t('no_promos_available'),
                    style: TextStyle(color: Colors.black.withOpacity(0.4)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return _buildCouponCard(context, promo, goldColor, deepBrown);
            },
          );
        },
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, dynamic promo, Color gold, Color brown) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            if (promo.bannerImage != null)
              Image.network(
                promo.bannerImage!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo.title,
                          style: TextStyle(
                            color: brown,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.description,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: gold.withOpacity(0.3)),
                          ),
                          child: Text(
                            promo.code,
                            style: TextStyle(
                              color: gold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        '${promo.discountPercentage.toInt()}%',
                        style: TextStyle(
                          color: gold,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        'OFF',
                        style: TextStyle(
                          color: gold.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
