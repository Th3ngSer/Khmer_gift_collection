import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../features/favorites/providers/favorites_provider.dart';
import '../../../core/constants/translations.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/providers/artisan_provider.dart';
import '../../artisan/widgets/edit_artisan_sheet.dart';
import '../../artisan/widgets/upload_product_sheet.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider).languageCode;
    final user = Supabase.instance.client.auth.currentUser;
    final isArtisanRole = user != null &&
        (user.userMetadata?['role'] == 'artisan' ||
            user.email == 'louchumdararith02@gmail.com');

    final artisanState = isArtisanRole ? ref.watch(artisanProfileProvider(user.id)) : null;
    final liveArtisanData = artisanState?.value?.artisan;

    final coverUrl =
        liveArtisanData?['cover_photo_url'] ?? liveArtisanData?['cover'];
    final avatarUrl = liveArtisanData?['profile_photo_url'] ??
        liveArtisanData?['avatar'] ??
        user?.userMetadata?['avatar_url'];
    final displayName = liveArtisanData?['name'] ??
        user?.userMetadata?['full_name'] ??
        'Khmer Guest';

    final hasValidCover = coverUrl != null && coverUrl.startsWith('http');
    final hasValidAvatar = avatarUrl != null && avatarUrl.startsWith('http');

    final favoritesCount = ref.watch(favoritesProvider).items.length;
    
    String t(String key) => Translations.translate(key, locale);

    final textColor = isDark ? Colors.white : AppTheme.deepEarth;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;

    void showLanguagePicker() {
      showModalBottomSheet(
        context: context,
        backgroundColor: cardBg,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Consumer(
            builder: (context, ref, _) {
              final selectedLocale = ref.watch(localeProvider);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Translations.translate(
                          'select_language', selectedLocale.languageCode),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...languages.map((lang) => ListTile(
                          leading: Text(lang.flag,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(
                            lang.name,
                            style: TextStyle(
                              fontWeight:
                                  selectedLocale.languageCode == lang.code
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                          trailing: selectedLocale.languageCode == lang.code
                              ? const Icon(Icons.check_circle,
                                  color: AppTheme.gold)
                              : null,
                          onTap: () {
                            ref
                                .read(localeProvider.notifier)
                                .setLocale(Locale(lang.code));
                            Navigator.pop(context);
                          },
                        )),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    void showThemePicker() {
      showModalBottomSheet(
        context: context,
        backgroundColor: cardBg,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t('appearance'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.wb_sunny_outlined, color: AppTheme.gold),
                  title: Text(t('light'), style: TextStyle(color: textColor)),
                  trailing: themeMode == ThemeMode.light
                      ? const Icon(Icons.check_circle, color: AppTheme.gold)
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined,
                      color: AppTheme.gold),
                  title: Text(t('dark'), style: TextStyle(color: textColor)),
                  trailing: themeMode == ThemeMode.dark
                      ? const Icon(Icons.check_circle, color: AppTheme.gold)
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    }

    void showNotificationPicker() {
      showModalBottomSheet(
        context: context,
        backgroundColor: cardBg,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Consumer(
            builder: (context, ref, _) {
              final isMuted = ref.watch(notificationProvider).isMuted;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('mute_messages'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined,
                          color: AppTheme.gold),
                      title: Text(t('on'), style: TextStyle(color: textColor)),
                      trailing: !isMuted
                          ? const Icon(Icons.check_circle, color: AppTheme.gold)
                          : null,
                      onTap: () {
                        ref.read(notificationProvider.notifier).setMute(false);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('notifications_enabled')),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.gold,
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications_off_outlined,
                          color: AppTheme.gold),
                      title: Text(t('off'), style: TextStyle(color: textColor)),
                      trailing: isMuted
                          ? const Icon(Icons.check_circle, color: AppTheme.gold)
                          : null,
                      onTap: () {
                        ref.read(notificationProvider.notifier).setMute(true);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('notifications_muted')),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.grey[800],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    void showSignOutConfirmation() {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 32),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  t('sign_out'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  t('sign_out_confirm'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withAlpha(160),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Buttons Row
                Row(
                  children: [
                    // No Button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          t('no'),
                          style: TextStyle(
                            color: textColor.withAlpha(120),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Yes Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (user != null) {
                            await Supabase.instance.client.auth.signOut();
                          }
                          if (context.mounted) context.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          t('yes'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // 1. "Airy" Header with Floating Avatar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: scaffoldBg,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Top Decorative Banner (Gradient or Artisan Cover Photo)
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: hasValidCover
                          ? null
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4A2511), Color(0xFF2A1508)],
                            ),
                      image: hasValidCover
                          ? DecorationImage(
                              image: NetworkImage(coverUrl!), fit: BoxFit.cover)
                          : null,
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40)),
                    ),
                    // Add a slight dark overlay if using an image so it blends well
                    child: hasValidCover
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(40),
                                  bottomRight: Radius.circular(40)),
                            ),
                          )
                        : null,
                  ),
                  // Floating Avatar
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: scaffoldBg,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.gold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: AppTheme.gold.withAlpha(25),
                          backgroundImage:
                              hasValidAvatar ? NetworkImage(avatarUrl!) : null,
                          child: !hasValidAvatar
                              ? const Icon(Icons.person,
                                  size: 50, color: AppTheme.gold)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                    if (isArtisanRole)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.verified,
                            color: AppTheme.gold, size: 24),
                      ),
                  ],
                ),
                Text(
                  user?.email ?? 'Join the collection',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 51 : 10),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(t('orders'), '0', isDark),
                      _buildVerticalDivider(isDark),
                      _buildStatItem(t('saved'), favoritesCount.toString(), isDark),
                      _buildVerticalDivider(isDark),
                      _buildStatItem(t('points'), '0', isDark, isPoints: true),
                    ],
                  ),
                ),

                if (isArtisanRole) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final artisanData = liveArtisanData ??
                                      {
                                        'id': user!.id,
                                        'name': user.userMetadata?['full_name'],
                                        'shop_name':
                                            user.userMetadata?['shop_name'] ??
                                                user.userMetadata?['full_name'],
                                      };
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24))),
                                    builder: (context) =>
                                        EditArtisanSheet(artisan: artisanData),
                                  );
                                },
                                icon: const Icon(Icons.edit_note,
                                    size: 18, color: AppTheme.gold),
                                label: const Text(
                                  'Edit Story',
                                  style: TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: AppTheme.gold),
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
                                        UploadProductSheet(artisanId: user.id),
                                  );
                                },
                                icon: const Icon(Icons.library_add,
                                    size: 18, color: AppTheme.gold),
                                label: const Text(
                                  'Add Item',
                                  style: TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: AppTheme.gold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final artisanData = liveArtisanData ??
                                  {
                                    'id': user!.id,
                                    'name': user.userMetadata?['full_name'],
                                    'shop_name':
                                        user.userMetadata?['shop_name'] ??
                                            user.userMetadata?['full_name'],
                                  };
                              context.push('/my_artisan_profile',
                                  extra: artisanData);
                            },
                            icon: const Icon(Icons.storefront),
                            label: const Text(
                              'View My Shop Dashboard',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.gold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // >>> END OF CONDITIONAL ARTISAN DESKTOP BUTTONS DECK <<<
              ],
            ),
          ),

          // 3. Menu Items Grouped in Cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle(t('account_settings')),
                _buildMenuCard(cardBg, [
                  _buildMenuItem(
                    context,
                    Icons.shopping_bag_outlined,
                    t('my_orders'),
                    null,
                    isDark,
                    trailing: '0 active',
                    onTap: () {
                      context.go('/home');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t('no_orders_yet')),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.gold,
                        ),
                      );
                    },
                  ),
                  _buildMenuDivider(isDark),
                  _buildMenuItem(context, Icons.confirmation_number_outlined,
                      t('promotions'), '/promotions', isDark),
                  _buildMenuDivider(isDark),
                  _buildMenuItem(context, Icons.favorite_border,
                      t('my_favorites'), '/favorites', isDark),
                  _buildMenuDivider(isDark),
                  _buildMenuItem(context, Icons.location_on_outlined,
                      t('shipping_addresses'), null, isDark),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle(t('preferences')),
                _buildMenuCard(cardBg, [
                  _buildMenuItem(
                    context,
                    Icons.language,
                    t('language'),
                    null,
                    isDark,
                    trailing:
                        '${languages.firstWhere((l) => l.code == locale).flag} ${languages.firstWhere((l) => l.code == locale).name}',
                    onTap: showLanguagePicker,
                  ),
                  _buildMenuDivider(isDark),
                  _buildMenuItem(
                    context,
                    Icons.notifications_none,
                    t('notifications'),
                    null,
                    isDark,
                    trailing: ref.watch(notificationProvider).isMuted
                        ? t('off')
                        : t('on'),
                    onTap: showNotificationPicker,
                  ),
                  _buildMenuDivider(isDark),
                  _buildMenuItem(
                    context,
                    Icons.dark_mode_outlined,
                    t('theme'),
                    null,
                    isDark,
                    trailing: isDark ? t('dark') : t('light'),
                    onTap: showThemePicker,
                  ),
                  _buildMenuDivider(isDark),
                  _buildMenuItem(
                    context,
                    Icons.logout_rounded,
                    t('sign_out'),
                    null,
                    isDark,
                    onTap: showSignOutConfirmation,
                  ),
                ]),
              ]),
            ),
          ),

          // 4. Footer Message
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C120C)
                      : const Color(0xFFF5EFE6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text(
                      'សូមអរគុណ',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'serif',
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every purchase supports a Cambodian artisan family.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      height: 30,
      width: 1,
      color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
    );
  }

  Widget _buildMenuCard(Color bg, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 20,
      color: isDark ? Colors.white.withAlpha(5) : const Color(0xFFFDFBF7),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark,
      {bool isPoints = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isPoints
                ? AppTheme.gold
                : (isDark ? Colors.white : AppTheme.deepEarth),
          ),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.gold,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      String? route, bool isDark,
      {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.gold.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isDark ? Colors.white : AppTheme.deepEarth, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppTheme.deepEarth,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontSize: 13),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              size: 18, color: isDark ? Colors.white10 : Colors.black12),
        ],
      ),
      onTap: onTap ??
          () {
            if (route != null) {
              context.push(route);
            }
          },
    );
  }
}
