import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/auth_toggle_mode_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  bool _isArtisan = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await ref
            .read(authProvider.notifier)
            .signUp(
              _emailController.text.trim(),
              _passwordController.text.trim(),
              _nameController.text.trim(),
              _isArtisan,
            );
      } else {
        await ref
            .read(authProvider.notifier)
            .signIn(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      // CHANGE YOUR CATCH BLOCK TO THIS:
      if (mounted) {
        String friendlyMessage =
            'An unexpected error occurred. Please try again later.';

        if (e is AuthException) {
          final msg = e.message.toLowerCase();
          // Translate raw database errors into beautiful natural text
          if (msg.contains('invalid login credentials') ||
              msg.contains('invalid_credentials')) {
            friendlyMessage =
                'The email or password you entered is incorrect. Please verify your credentials and try again.';
          } else if (msg.contains('rate limit')) {
            friendlyMessage =
                'Too many attempts. Please wait a moment before trying again.';
          } else {
            friendlyMessage = e.message;
          }
        }

        // Display a clean, native alert modal instead of a snackbar banner
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Sign In Failed',
              style: TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              friendlyMessage,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF374151),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed to a clean white mobile canvas
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(isSignUp: _isSignUp),
                const SizedBox(height: 48), // Generous mobile spacing
                AuthForm(
                  isSignUp: _isSignUp,
                  isArtisan: _isArtisan,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  nameController: _nameController,
                  onArtisanChanged: (val) =>
                      setState(() => _isArtisan = val ?? false),
                ),
                const SizedBox(height: 32),
                AuthSubmitButton(
                  isLoading: _isLoading,
                  isSignUp: _isSignUp,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                AuthToggleModeButton(
                  isSignUp: _isSignUp,
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                ),
                // ADD THIS GOOGLE BUTTON SEPARATOR AND WIDGET HERE:
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(authProvider.notifier).signInWithGoogle(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://developers.google.com/static/identity/images/g-logo.png',
                        height: 18,
                        width: 18,
                        // CATCHES CORS & NETWORK ERRORS INSTANTLY TO PREVENT LAYOUT EXPLOSIONS:
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4285F4), // Official Google Blue
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
