import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

/// Layar daftar (register) sesuai referensi tengah: header seni + Back,
/// kartu "Get Started", field Full Name / Email / Password, persetujuan
/// data pribadi, tombol Sign up, daftar sosial, dan tautan ke Login.
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
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  const AuthBlobArt(height: 210),
                  Positioned(
                    top: 12,
                    left: 6,
                    child: AuthBackButton(onTap: widget.onBack),
                  ),
                ],
              ),
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
                          'Get Started',
                          textAlign: TextAlign.center,
                          style: AuthTheme.titleStyle,
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'Full Name',
                          hint: 'Enter Full Name',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          validator: AuthValidators.validateName,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          label: 'Email',
                          hint: 'Enter Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: AuthValidators.validateEmail,
                        ),
                        const SizedBox(height: 14),
                        AuthPasswordField(
                          controller: _passwordController,
                          hint: 'Enter Password',
                          validator: AuthValidators.validatePassword,
                          onSubmitted: _submit,
                        ),
                        const SizedBox(height: 12),
                        AuthCheckRow(
                          value: _agreed,
                          onChanged: (v) => setState(() {
                            _agreed = v ?? false;
                            if (_agreed) _agreeError = false;
                          }),
                          label: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B7280),
                              ),
                              children: [
                                TextSpan(
                                  text: 'I agree to the processing of ',
                                ),
                                TextSpan(
                                  text: 'Personal data',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AuthTheme.royal,
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
                        const SizedBox(height: 16),
                        AuthPrimaryButton(
                          label: 'Sign up',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 18),
                        const AuthDividerLabel(text: 'Sign up with'),
                        const SizedBox(height: 14),
                        const AuthSocialRow(),
                        const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}
