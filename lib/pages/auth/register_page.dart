import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

/// Layar daftar: kartu form dengan validasi zod + persetujuan data.
class RegisterPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onGoLogin;
  final VoidCallback onSuccess;
  final AuthService? authService;

  const RegisterPage({
    super.key,
    required this.onBack,
    required this.onGoLogin,
    required this.onSuccess,
    this.authService,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _agreed = false;
  bool _agreeError = false;
  bool _loading = false;
  late AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService.instance;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _agreeError = !_agreed);
    if (!valid || !_agreed) {
      if (!_agreed) {
        _showMessage('Centang persetujuan pemrosesan data pribadi');
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final error = _auth.register(
        name: _nameController.text,
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
                          'Get Started',
                          style: AuthTheme.titleStyle,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Buat akun untuk mulai menulis dan membaca.',
                          style: AuthTheme.subtitleStyle,
                        ),
                        const SizedBox(height: 22),
                        AuthTextField(
                          label: 'Full Name',
                          hint: 'Enter Full Name',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          validator: AuthValidators.validateName,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Email',
                          hint: 'Enter Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: AuthValidators.validateEmail,
                        ),
                        const SizedBox(height: 16),
                        AuthPasswordField(
                          controller: _passwordController,
                          hint: 'Enter Password',
                          validator: AuthValidators.validatePassword,
                          onSubmitted: _submit,
                        ),
                        const SizedBox(height: 14),
                        AuthCheckRow(
                          value: _agreed,
                          onChanged: (v) => setState(() {
                            _agreed = v ?? false;
                            if (_agreed) _agreeError = false;
                          }),
                          label: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: AuthTheme.subtitle,
                              ),
                              children: [
                                TextSpan(
                                  text: 'I agree to the processing of ',
                                ),
                                TextSpan(
                                  text: 'Personal data',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AuthTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_agreeError)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Persetujuan wajib dicentang',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        AuthPrimaryButton(
                          label: 'Sign up',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 20),
                        const AuthDividerLabel(text: 'Sign up with'),
                        const SizedBox(height: 16),
                        const AuthSocialRow(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AuthSwitchText(
                  prefix: 'Already have an account?',
                  action: 'Sign in',
                  onTap: widget.onGoLogin,
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
