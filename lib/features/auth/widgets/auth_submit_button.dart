import 'package:flutter/material.dart';
import './auth_constants.dart';

class AuthSubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isSignUp;
  final VoidCallback onPressed;

  const AuthSubmitButton({
    super.key,
    required this.isLoading,
    required this.isSignUp,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AuthConstants.goldColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AuthConstants.goldColor.withOpacity(0.6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              isSignUp ? 'Register Account' : 'Sign In',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}