import 'package:flutter/material.dart';

/// Token desain khusus alur auth (splash / login / register),
/// meniru referensi: seni blob biru, kartu putih, tombol royal-blue.
class AuthTheme {
  static const String brandName = 'Ruang Kata';

  /// Biru royal ala tombol & judul pada referensi.
  static const Color royal = Color(0xFF3357D6);
  static const Color royalDark = Color(0xFF1E2A78);
  static const Color navy = Color(0xFF141F5C);
  static const Color skyLight = Color(0xFFA9C3F5);
  static const Color skyMid = Color(0xFF6E93E8);

  /// Abu kebiruan di belakang bingkai ponsel pada referensi.
  static const Color canvas = Color(0xFFD9E1F2);

  static const double phoneMaxWidth = 430;
  static const double cardRadius = 28;
  static const double fieldRadius = 14;

  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: royal,
    letterSpacing: -0.3,
  );

  static const TextStyle fieldLabelStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF8A8FA3),
  );
}

/// Bingkai responsif: di ponsel tampil full-bleed, di tablet/desktop
/// tampil sebagai "bingkai ponsel" (rounded + bayangan) di tengah
/// kanvas abu kebiruan seperti pada referensi.
class AuthShell extends StatelessWidget {
  final Widget child;

  const AuthShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth < 600;
            if (isPhone) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: child,
              );
            }
            final frameHeight =
                (constraints.maxHeight - 48).clamp(560.0, 900.0);
            return Center(
              child: Container(
                width: AuthTheme.phoneMaxWidth,
                height: frameHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 32,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Latar seni abstrak biru (blob + bola kaca) yang meniru referensi,
/// digambar murni dengan Canvas agar tanpa aset gambar.
class AuthBlobArt extends StatelessWidget {
  final double height;

  const AuthBlobArt({super.key, this.height = 250});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: const CustomPaint(painter: AuthBlobPainter()),
    );
  }
}

/// Painter seni abstrak biru — dipakai header auth maupun latar splash.
class AuthBlobPainter extends CustomPainter {
  const AuthBlobPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dasar gradasi navy -> royal.
    final base = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3FA0), Color(0xFF5B7FE8)],
        ).createShader(base),
    );

    // Gelombang muda transparan.
    final wave = Path()
      ..moveTo(0, h * 0.28)
      ..quadraticBezierTo(w * 0.3, h * 0.05, w * 0.62, h * 0.3)
      ..quadraticBezierTo(w * 0.85, h * 0.5, w, h * 0.38)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );

    final wave2 = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.35, h * 0.35, w * 0.7, h * 0.62)
      ..quadraticBezierTo(w * 0.88, h * 0.76, w, h * 0.68)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      wave2,
      Paint()..color = const Color(0xFF141F5C).withValues(alpha: 0.35),
    );

    // Lingkaran navy pojok kiri atas (tempat tombol Back).
    canvas.drawCircle(
      Offset(w * 0.02, h * 0.02),
      w * 0.24,
      Paint()..color = const Color(0xFF131C55),
    );

    // Bola biru muda kanan atas.
    _glossyBall(
      canvas,
      center: Offset(w * 0.78, h * 0.30),
      radius: w * 0.17,
      inner: const Color(0xFFB9D0FA),
      outer: const Color(0xFF5B7FE8),
    );

    // Bola putih kecil.
    _glossyBall(
      canvas,
      center: Offset(w * 0.72, h * 0.62),
      radius: w * 0.10,
      inner: Colors.white,
      outer: const Color(0xFF9DB9F2),
    );

    // Bola navy bawah kiri.
    _glossyBall(
      canvas,
      center: Offset(w * 0.30, h * 0.94),
      radius: w * 0.16,
      inner: const Color(0xFF2A3FA0),
      outer: const Color(0xFF0E1647),
    );
  }

  void _glossyBall(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color inner,
    required Color outer,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [inner, outer],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    // Kilau kaca.
    canvas.drawCircle(
      center + Offset(-radius * 0.3, -radius * 0.35),
      radius * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kartu putih yang menindih seni header (radius atas 28).
class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AuthTheme.cardRadius),
        ),
      ),
      child: child,
    );
  }
}

/// Field teks auth: label kecil di atas + kotak border abu terang.
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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1B1D29)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFFB6BACC),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(color: Color(0xFFE3E6F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(color: Color(0xFFE3E6F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(
                color: AuthTheme.royal,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
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
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1B1D29)),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFFB6BACC),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF8A8FA3),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(color: Color(0xFFE3E6F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(color: Color(0xFFE3E6F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(
                color: AuthTheme.royal,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AuthTheme.fieldRadius),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol utama biru royal.
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
          backgroundColor: AuthTheme.royal,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AuthTheme.royal.withValues(alpha: 0.6),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTheme.fieldRadius),
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

/// Tombol lingkaran "Back" di atas lingkaran navy header.
class AuthBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const AuthBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, size: 22, color: Colors.white),
              SizedBox(width: 2),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
        const Expanded(child: Divider(color: Color(0xFFECEFF6))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9AA0B5),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFECEFF6))),
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
        _SocialCircle(
          tooltip: 'Facebook',
          onTap: () => _soon(context),
          child: const Icon(Icons.facebook, size: 26, color: Color(0xFF1877F2)),
        ),
        const SizedBox(width: 22),
        _SocialCircle(
          tooltip: 'X',
          onTap: () => _soon(context),
          child: const Text(
            '𝕏',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 22),
        _SocialCircle(
          tooltip: 'Google',
          onTap: () => _soon(context),
          child: const Text(
            'G',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFFDB4437),
            ),
          ),
        ),
        const SizedBox(width: 22),
        _SocialCircle(
          tooltip: 'Apple',
          onTap: () => _soon(context),
          child: const Icon(Icons.apple, size: 27, color: Colors.black87),
        ),
      ],
    );
  }
}

class _SocialCircle extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  const _SocialCircle({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF4F6FB),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
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
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF9AA0B5),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AuthTheme.royal,
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
            activeColor: AuthTheme.royal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: const BorderSide(color: Color(0xFFB6BACC), width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: label),
      ],
    );
  }
}
