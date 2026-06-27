import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/promo_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/constants/translations.dart';
import '../../../core/theme/app_theme.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(activePromotionsProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    const goldColor = Color(0xFFD4AF37);

    String t(String key) => Translations.translate(key, locale);

    final textColor = isDark ? Colors.white : AppTheme.deepEarth;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;

    void _showCouponDetails(dynamic promo) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 80 : 30),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (promo.bannerImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(promo.bannerImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 20),
                Text(
                  promo.title,
                  style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  promo.description,
                  style: TextStyle(color: textColor.withAlpha(180), fontSize: 15, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: goldColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: goldColor.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promo.code,
                        style: const TextStyle(color: goldColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: goldColor),
                        onPressed: () {
                          // Copy logic here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Coupon code copied!'), behavior: SnackBarBehavior.floating, backgroundColor: goldColor),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t('promotions_title'),
          style: TextStyle(
            color: textColor,
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: promosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: goldColor)),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: textColor))),
        data: (promos) {
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 64, color: textColor.withAlpha(30)),
                  const SizedBox(height: 16),
                  Text(
                    t('no_promos_available'),
                    style: TextStyle(color: textColor.withAlpha(100)),
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
              return InkWell(
                onTap: () => _showCouponDetails(promo),
                borderRadius: BorderRadius.circular(24),
                child: _buildCouponCard(context, promo, goldColor, textColor, cardBg, isDark),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, dynamic promo, Color gold, Color textColor, Color cardBg, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 12),
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
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.description,
                          style: TextStyle(
                            color: textColor.withAlpha(150),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: gold.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: gold.withAlpha(76)),
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
                          color: gold.withAlpha(150),
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
