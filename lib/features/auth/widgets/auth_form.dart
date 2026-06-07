import 'package:flutter/material.dart';
import './auth_constants.dart';
import 'auth_text_field.dart';

class AuthForm extends StatelessWidget {
  final bool isSignUp;
  final bool isArtisan;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final ValueChanged<bool?> onArtisanChanged;

  const AuthForm({
    super.key,
    required this.isSignUp,
    required this.isArtisan,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.onArtisanChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isSignUp) ...[
          AuthTextField(
            controller: nameController,
            labelText: 'Display Name',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
        ],
        AuthTextField(
          controller: emailController,
          labelText: 'Email Address',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: passwordController,
          labelText: 'Password',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
        ),
        if (isSignUp) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: CheckboxListTile(
              title: const Text(
                'Register as Artisan Workshop Owner',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Allows you to list traditional crafts for sale',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              activeColor: AuthConstants.goldColor,
              value: isArtisan,
              onChanged: onArtisanChanged,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ],
    );
  }
}