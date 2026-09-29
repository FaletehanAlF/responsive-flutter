import 'package:flutter/foundation.dart';

/// Aturan validasi auth di Flutter.
///
/// Cerminan dari `backend/schemas/authSchema.js` (zod) yang menjadi
/// acuan tunggal aturan. Pesan error disamakan agar konsisten antara
/// backend dan aplikasi.
class AuthValidators {
  static const int minNameLength = 3;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 72;

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validateName(String? value) {
    final text = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return 'Nama lengkap wajib diisi';
    if (text.length < minNameLength) {
      return 'Nama minimal $minNameLength karakter';
    }
    if (text.length > maxNameLength) {
      return 'Nama maksimal $maxNameLength karakter';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Email wajib diisi';
    if (!_emailPattern.hasMatch(text)) return 'Format email tidak valid';
    return null;
  }

  static String? validatePassword(String? value, {bool isLogin = false}) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password wajib diisi';
    if (isLogin) return null;
    if (text.length < minPasswordLength) {
      return 'Password minimal $minPasswordLength karakter';
    }
    if (text.length > maxPasswordLength) {
      return 'Password maksimal $maxPasswordLength karakter';
    }
    return null;
  }

  /// Normalisasi nama seperti preprocess di skema zod (rapatkan spasi).
  static String normalizeName(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// Data pengguna yang sedang masuk.
class AuthUser {
  final String name;
  final String email;

  const AuthUser({required this.name, required this.email});
}

/// Session auth sederhana (demo, penyimpanan di memori).
///
/// Backend NARATA saat ini belum punya tabel pengguna / endpoint auth,
/// sehingga login-register berjalan lokal sebagai UI flow. Titik integrasi
/// backend sudah disiapkan: ganti isi [login] / [register] dengan panggilan
/// `POST /auth/login` dan `POST /auth/register` saat endpoint tersedia —
/// kontrak body & validasinya mengikuti `backend/schemas/authSchema.js`.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();

  AuthService._internal() {
    // Akun demo agar alur bisa dicoba langsung.
    _users['demo@ruangkata.id'] = _StoredUser(
      name: 'Demo Ruang Kata',
      email: 'demo@ruangkata.id',
      password: 'demo1234',
    );
  }

  /// Untuk pengujian / injeksi pada widget (AuthGate, AuthFlow).
  factory AuthService.create() => AuthService._internal();

  final Map<String, _StoredUser> _users = {};
  AuthUser? _currentUser;
  bool _rememberMe = false;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get rememberMe => _rememberMe;

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Mendaftarkan akun baru. Mengembalikan pesan error bila gagal,
  /// null bila berhasil (dan otomatis masuk).
  String? register({
    required String name,
    required String email,
    required String password,
  }) {
    final cleanName = AuthValidators.normalizeName(name);
    final cleanEmail = email.trim();

    final nameError = AuthValidators.validateName(cleanName);
    if (nameError != null) return nameError;
    final emailError = AuthValidators.validateEmail(cleanEmail);
    if (emailError != null) return emailError;
    final passwordError = AuthValidators.validatePassword(password);
    if (passwordError != null) return passwordError;

    final key = cleanEmail.toLowerCase();
    if (_users.containsKey(key)) {
      return 'Email sudah terdaftar, silakan masuk';
    }

    _users[key] = _StoredUser(
      name: cleanName,
      email: cleanEmail,
      password: password,
    );
    _currentUser = AuthUser(name: cleanName, email: cleanEmail);
    notifyListeners();
    return null;
  }

  /// Masuk dengan email & password. Mengembalikan pesan error bila gagal,
  /// null bila berhasil.
  String? login({required String email, required String password}) {
    final cleanEmail = email.trim();

    final emailError = AuthValidators.validateEmail(cleanEmail);
    if (emailError != null) return emailError;
    final passwordError =
        AuthValidators.validatePassword(password, isLogin: true);
    if (passwordError != null) return passwordError;

    final stored = _users[cleanEmail.toLowerCase()];
    if (stored == null || stored.password != password) {
      return 'Email atau password salah';
    }

    _currentUser = AuthUser(name: stored.name, email: stored.email);
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

class _StoredUser {
  final String name;
  final String email;
  final String password;

  const _StoredUser({
    required this.name,
    required this.email,
    required this.password,
  });
}
