import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthNotifier extends StreamNotifier<User?> {
  @override
  Stream<User?> build() {
    return Supabase.instance.client.auth.onAuthStateChange.map((data) => data.session?.user);
  }

  Future<void> signIn(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String name, bool isArtisan) async {
    final supabase = Supabase.instance.client;
    
    final AuthResponse res = await supabase.auth.signUp(email: email, password: password);
    final String? uid = res.user?.id;

    if (uid == null) return;

    final String assignedRole = isArtisan ? 'artisan' : 'customer';
    await supabase.from('users').upsert({
      'id': uid,
      'email': email,
      'role': assignedRole,
    });

    if (isArtisan) {
      await supabase.from('artisans').upsert({
        'id': uid,
        'name': name,
        'region': 'Phnom Penh', // Default fallback region for demo
        'profile_photo_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        'cover_photo_url': 'https://images.unsplash.com/photo-1618220179428-22790b461013',
      });
    }
  }

  Future<void> signInWithGoogle() async {
  final String redirectUrl = kIsWeb 
      ? 'http://localhost:56987/home'  
      : 'khmergiftapp://login-callback';

  await Supabase.instance.client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: redirectUrl,
  );
}

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}

final authProvider = StreamNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});