import 'package:flutter/material.dart';
import './auth_constants.dart';

class AuthHeader extends StatelessWidget {
  final bool isSignUp;

  const AuthHeader({super.key, required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'KHMER GIFT COLLECTION',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 3.0,
            color: AuthConstants.goldColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isSignUp ? 'Create Shelf' : 'Welcome Back',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSignUp
              ? 'Enter your details to open your account.'
              : 'Sign in to continue to your dashboard.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}