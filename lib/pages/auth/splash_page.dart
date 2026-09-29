import 'package:flutter/material.dart';

import '../../widgets/auth_widgets.dart';

/// Layar pembuka: logo, sapaan, dan dua aksi masuk/daftar.
/// Tampil penuh di ponsel, kartu terpusat di layar besar.
class SplashPage extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const SplashPage({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AuthLogoMark(size: 76)),
                const SizedBox(height: 18),
                const AuthBrandLabel(),
                const SizedBox(height: 28),
                const Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AuthTheme.ink,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Masuk untuk membaca dan mengelola artikel favoritmu di Ruang Kata.',
                  textAlign: TextAlign.center,
                  style: AuthTheme.subtitleStyle,
                ),
                const SizedBox(height: 36),
                AuthPrimaryButton(label: 'Sign in', onPressed: onSignIn),
                const SizedBox(height: 12),
                AuthSecondaryButton(label: 'Sign up', onPressed: onSignUp),
                const SizedBox(height: 28),
                const Text(
                  'Blog Management • v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AuthTheme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
