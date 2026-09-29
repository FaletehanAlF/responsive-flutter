import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

/// Layar masuk (login) sesuai referensi kanan: header seni + tombol Back,
/// kartu "Welcome back", field Email & Password, Remember me,
/// tombol Sign in, login sosial, dan tautan ke Register.
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
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  const AuthBlobArt(height: 240),
                  Positioned(
                    top: 12,
                    left: 6,
                    child: AuthBackButton(onTap: widget.onBack),
                  ),
                ],
              ),
              // Kartu menindih header.
              Transform.translate(
                offset: const Offset(0, -28),
                child: AuthFormCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: AuthTheme.titleStyle,
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'Email',
                          hint: 'kristin.watson@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: AuthValidators.validateEmail,
                        ),
                        const SizedBox(height: 14),
                        AuthPasswordField(
                          controller: _passwordController,
                          hint: '••••••••••',
                          validator: (v) => AuthValidators.validatePassword(
                            v,
                            isLogin: true,
                          ),
                          onSubmitted: _submit,
                        ),
                        const SizedBox(height: 12),
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
                                    fontSize: 12.5,
                                    color: Color(0xFF6B7280),
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
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AuthTheme.royal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AuthPrimaryButton(
                          label: 'Sign in',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 18),
                        const AuthDividerLabel(text: 'Sign in with'),
                        const SizedBox(height: 14),
                        const AuthSocialRow(),
                        const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}
