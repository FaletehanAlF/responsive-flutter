import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../main_shell.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'splash_page.dart';

/// Langkah dalam alur auth sebelum masuk aplikasi.
enum AuthStep { splash, login, register }

/// Mengatur perpindahan Splash <-> Login <-> Register (tanpa Navigator,
/// cukup state) lalu menyerahkan ke [MainShell] setelah auth sukses.
class AuthFlow extends StatefulWidget {
  final AuthService? authService;
  final AuthStep initialStep;

  const AuthFlow({
    super.key,
    this.authService,
    this.initialStep = AuthStep.splash,
  });

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  late AuthStep _step = widget.initialStep;

  void _go(AuthStep step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case AuthStep.splash:
        return SplashPage(
          onSignIn: () => _go(AuthStep.login),
          onSignUp: () => _go(AuthStep.register),
        );
      case AuthStep.login:
        return LoginPage(
          authService: widget.authService,
          onBack: () => _go(AuthStep.splash),
          onGoRegister: () => _go(AuthStep.register),
          onSuccess: () {},
        );
      case AuthStep.register:
        return RegisterPage(
          authService: widget.authService,
          onBack: () => _go(AuthStep.splash),
          onGoLogin: () => _go(AuthStep.login),
          onSuccess: () {},
        );
    }
  }
}

/// Gerbang sesi: belum masuk -> [AuthFlow], sudah masuk -> [MainShell].
class AuthGate extends StatefulWidget {
  final AuthService? authService;

  const AuthGate({super.key, this.authService});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService.instance;
    _auth.addListener(_onAuthChanged);
  }

  @override
  void didUpdateWidget(AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.authService ?? AuthService.instance;
    if (next != _auth) {
      _auth.removeListener(_onAuthChanged);
      _auth = next;
      _auth.addListener(_onAuthChanged);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.isLoggedIn) {
      return const MainShell();
    }
    return AuthFlow(authService: widget.authService);
  }
}
