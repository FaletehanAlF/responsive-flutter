import 'package:flutter/material.dart';

/// Bahasa desain auth versi clean-modern: kanvas terang netral, kartu
/// putih dengan border halus, aksen biru aplikasi, tipografi tegas rata
/// kiri, dan whitespace lega. Tanpa ilustrasi berat — fokus ke isi.
class AuthTheme {
  static const String brandName = 'Ruang Kata';

  static const Color primary = Color(0xFF1877F2);
  static const Color primaryDark = Color(0xFF0F5FCC);
  static const Color ink = Color(0xFF111214);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color muted = Color(0xFF9AA0A6);
  static const Color fieldFill = Color(0xFFF1F2F4);
  static const Color line = Color(0xFFE8EAEF);

  /// Kanvas terang di belakang bingkai pada tablet/desktop.
  static const Color canvas = Color(0xFFEDF0F6);

  static const double phoneMaxWidth = 430;

  static const TextStyle titleStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    height: 1.55,
    color: subtitle,
  );

  static const TextStyle fieldLabelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: ink,
  );
}

/// Logo mark "RK": kotak gradasi biru dengan inisial putih.
class AuthLogoMark extends StatelessWidget {
  final double size;

  const AuthLogoMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuthTheme.primary, AuthTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'RK',
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Nama brand kecil berhuruf renggang di bawah/beside logo.
class AuthBrandLabel extends StatelessWidget {
  final TextAlign textAlign;

  const AuthBrandLabel({super.key, this.textAlign = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return Text(
      'RUANG KATA',
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 3.0,
        color: AuthTheme.primary,
      ),
    );
  }
}

/// Bingkai responsif: ponsel full-bleed, tablet/desktop berupa kartu
/// terpusat yang "mengambang" di atas kanvas terang.
class AuthShell extends StatelessWidget {
  final Widget child;

  const AuthShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return child;
            }
            final frameHeight =
                (constraints.maxHeight - 48).clamp(560.0, 900.0);
            return Container(
              color: AuthTheme.canvas,
              child: Center(
                child: Container(
                  width: AuthTheme.phoneMaxWidth,
                  height: frameHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AuthTheme.line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 32,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Kartu form putih: padding lega, radius 24, border + bayangan halus.
class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AuthTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration _authInputDecoration(String hint) {
  const radius = BorderRadius.all(Radius.circular(16));
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: AuthTheme.muted),
    filled: true,
    fillColor: AuthTheme.fieldFill,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 15,
    ),
    border: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AuthTheme.primary, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}

/// Field teks auth: label tegas + input filled seperti form aplikasi.
class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AuthTheme.fieldLabelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 15, color: AuthTheme.ink),
          decoration: _authInputDecoration(hint),
        ),
      ],
    );
  }
}

/// Field password dengan tombol intip.
class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint = 'Enter Password',
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: AuthTheme.fieldLabelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 15, color: AuthTheme.ink),
          decoration: _authInputDecoration(widget.hint).copyWith(
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AuthTheme.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol utama penuh.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AuthTheme.primary.withValues(alpha: 0.6),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Tombol sekunder (outlined) penuh.
class AuthSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AuthTheme.primary,
          side: const BorderSide(color: AuthTheme.primary, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Tombol kembali: pil abu dengan ikon + teks.
class AuthBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const AuthBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AuthTheme.fieldFill,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back,
                size: 18,
                color: AuthTheme.ink,
              ),
              SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AuthTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pemisah "Sign in with" dengan garis di kanan-kiri.
class AuthDividerLabel extends StatelessWidget {
  final String text;

  const AuthDividerLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthTheme.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AuthTheme.muted),
          ),
        ),
        const Expanded(child: Divider(color: AuthTheme.line)),
      ],
    );
  }
}

/// Baris tombol sosial (tampilan; login sosial belum diintegrasikan).
class AuthSocialRow extends StatelessWidget {
  const AuthSocialRow({super.key});

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Login sosial segera hadir'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          tooltip: 'Facebook',
          onTap: () => _soon(context),
          child: const Icon(
            Icons.facebook,
            size: 24,
            color: AuthTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        _SocialButton(
          tooltip: 'X',
          onTap: () => _soon(context),
          child: const Text(
            '𝕏',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AuthTheme.ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _SocialButton(
          tooltip: 'Google',
          onTap: () => _soon(context),
          child: const Text(
            'G',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFFDB4437),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _SocialButton(
          tooltip: 'Apple',
          onTap: () => _soon(context),
          child: const Icon(
            Icons.apple,
            size: 25,
            color: AuthTheme.ink,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  const _SocialButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AuthTheme.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 48,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Teks alih halaman ("Already have an account? Sign in").
class AuthSwitchText extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;

  const AuthSwitchText({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            prefix,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AuthTheme.subtitle),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AuthTheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Baris checkbox + label (remember me / persetujuan).
class AuthCheckRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget label;

  const AuthCheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AuthTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: const BorderSide(color: AuthTheme.muted, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: label),
      ],
    );
  }
}
