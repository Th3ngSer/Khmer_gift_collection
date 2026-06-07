import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    const deepBrown = Color(0xFF2A1508);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Creamy background
      body: CustomScrollView(
        slivers: [
          // 1. Elegant Header with User Info
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: deepBrown,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4A2511), deepBrown],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: goldColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: goldColor.withOpacity(0.2),
                        backgroundImage: user?.userMetadata?['avatar_url'] != null
                            ? NetworkImage(user!.userMetadata!['avatar_url'])
                            : null,
                        child: user?.userMetadata?['avatar_url'] == null
                            ? const Icon(Icons.person, size: 50, color: goldColor)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.userMetadata?['full_name'] ?? 'Khmer Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      user?.email ?? 'Join the collection',
                      style: TextStyle(
                        color: goldColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Stats Row (Orders, Favorites, Points)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Orders', '12', goldColor),
                  _buildStatItem('Saved', '8', goldColor),
                  _buildStatItem('Points', '450', goldColor),
                ],
              ),
            ),
          ),

          // 3. Settings Groups
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle('ACCOUNT SETTINGS'),
              _buildMenuItem(context, Icons.shopping_bag_outlined, 'My Orders', null),
              _buildMenuItem(context, Icons.favorite_border, 'My Favorites', '/favorites'),
              _buildMenuItem(context, Icons.location_on_outlined, 'Shipping Addresses', null),
              
              const SizedBox(height: 20),
              _buildSectionTitle('PREFERENCES'),
              _buildMenuItem(context, Icons.language, 'Language', null, trailing: 'English (US)'),
              _buildMenuItem(context, Icons.notifications_none, 'Notifications', null),
              _buildMenuItem(context, Icons.dark_mode_outlined, 'Appearance', null, trailing: 'Light'),

              const SizedBox(height: 20),
              _buildSectionTitle('SUPPORT'),
              _buildMenuItem(context, Icons.help_outline, 'Help Center', null),
              _buildMenuItem(context, Icons.info_outline, 'About Khmer Gift', null),

              const SizedBox(height: 32),
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go('/');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 60),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2A1508)),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Color(0xFFD4AF37),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String? route, {String? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2A1508), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 14),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
        ],
      ),
      onTap: () {
        if (route != null) {
          context.push(route);
        }
      },
    );
  }
}
