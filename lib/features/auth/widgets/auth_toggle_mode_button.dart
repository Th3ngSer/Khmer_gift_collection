import 'package:flutter/material.dart';
import './auth_constants.dart';

class AuthToggleModeButton extends StatelessWidget {
  final bool isSignUp;
  final VoidCallback onPressed;

  const AuthToggleModeButton({
    super.key,
    required this.isSignUp,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              isSignUp ? 'Sign In' : 'Create one',
              style: const TextStyle(
                color: AuthConstants.goldColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}