// lib/widgets/auth_button.dart

import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final VoidCallback onPressed;

  const AuthButton({
    super.key,
    required this.isLoading,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Define gradient colors
    const Color primaryBlue = Color(0xFF00BFFF);
    const Color primaryPurple = Color(0xFF8A2BE2);

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isLoading ? 60 : constraints.maxWidth,
          height: 60,
          // Updated decoration to use a gradient instead of a solid color
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryBlue, primaryPurple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(isLoading ? 30 : 15),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent, // Material is now transparent to show the gradient
            borderRadius: BorderRadius.circular(isLoading ? 30 : 15),
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(isLoading ? 30 : 15),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}