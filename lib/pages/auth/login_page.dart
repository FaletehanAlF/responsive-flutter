import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

/// Layar masuk: kartu form ringkas dengan judul rata kiri,
/// field filled, dan aksi sosial.
class LoginPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onGoRegister;
  final VoidCallback onSuccess;
  final AuthService? authService;

  const LoginPage({
    super.key,
    required this.onBack,
    required this.onGoRegister,
    required this.onSuccess,
    this.authService,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  late AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService.instance;
    _auth.addListener(_onAuthChanged);
  }

  @override
  void didUpdateWidget(LoginPage oldWidget) {
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final error = _auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (error != null) {
        _showMessage(error);
        return;
      }
      widget.onSuccess();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AuthBackButton(onTap: widget.onBack),
                    const Spacer(),
                    const AuthLogoMark(size: 40),
                  ],
                ),
                const SizedBox(height: 24),
                AuthFormCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome back',
                          style: AuthTheme.titleStyle,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Masuk untuk melanjutkan ke akunmu.',
                          style: AuthTheme.subtitleStyle,
                        ),
                        const SizedBox(height: 22),
                        AuthTextField(
                          label: 'Email',
                          hint: 'kristin.watson@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: AuthValidators.validateEmail,
                        ),
                        const SizedBox(height: 16),
                        AuthPasswordField(
                          controller: _passwordController,
                          hint: '••••••••••',
                          validator: (v) => AuthValidators.validatePassword(
                            v,
                            isLogin: true,
                          ),
                          onSubmitted: _submit,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: AuthCheckRow(
                                value: _auth.rememberMe,
                                onChanged: (v) =>
                                    _auth.setRememberMe(v ?? false),
                                label: const Text(
                                  'Remember me',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AuthTheme.subtitle,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showMessage(
                                'Reset password segera hadir',
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 2,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AuthTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AuthPrimaryButton(
                          label: 'Sign in',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 20),
                        const AuthDividerLabel(text: 'Sign in with'),
                        const SizedBox(height: 16),
                        const AuthSocialRow(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AuthSwitchText(
                  prefix: "Don't have an account?",
                  action: 'Sign up',
                  onTap: widget.onGoRegister,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
