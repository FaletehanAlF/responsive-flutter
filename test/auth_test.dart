import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_ui/pages/auth/auth_flow.dart';
import 'package:responsive_ui/pages/auth/login_page.dart';
import 'package:responsive_ui/pages/auth/register_page.dart';
import 'package:responsive_ui/pages/auth/splash_page.dart';
import 'package:responsive_ui/pages/main_shell.dart';
import 'package:responsive_ui/services/auth_service.dart';

void main() {
  group('AuthValidators (cerminan skema zod)', () {
    test('nama: wajib, min 3, maks 50', () {
      expect(AuthValidators.validateName(null), 'Nama lengkap wajib diisi');
      expect(AuthValidators.validateName('  '), 'Nama lengkap wajib diisi');
      expect(AuthValidators.validateName('Ab'), 'Nama minimal 3 karakter');
      expect(AuthValidators.validateName('Ayu'), isNull);
      expect(
        AuthValidators.validateName('A' * 51),
        'Nama maksimal 50 karakter',
      );
    });

    test('email: wajib dan format valid', () {
      expect(AuthValidators.validateEmail(''), 'Email wajib diisi');
      expect(
        AuthValidators.validateEmail('bukan-email'),
        'Format email tidak valid',
      );
      expect(
        AuthValidators.validateEmail('user@tanpa-tld'),
        'Format email tidak valid',
      );
      expect(
        AuthValidators.validateEmail('kristin.watson@example.com'),
        isNull,
      );
    });

    test('password register: wajib, min 6, maks 72', () {
      expect(AuthValidators.validatePassword(''), 'Password wajib diisi');
      expect(
        AuthValidators.validatePassword('12345'),
        'Password minimal 6 karakter',
      );
      expect(AuthValidators.validatePassword('123456'), isNull);
      expect(
        AuthValidators.validatePassword('p' * 73),
        'Password maksimal 72 karakter',
      );
    });

    test('password login: hanya wajib diisi', () {
      expect(
        AuthValidators.validatePassword('', isLogin: true),
        'Password wajib diisi',
      );
      expect(
        AuthValidators.validatePassword('123', isLogin: true),
        isNull,
      );
    });

    test('normalizeName merapatkan spasi', () {
      expect(
        AuthValidators.normalizeName('  Ayu   Lestari  '),
        'Ayu Lestari',
      );
    });
  });

  group('AuthService', () {
    test('register sukses dan otomatis masuk', () {
      final auth = AuthService.create();
      final error = auth.register(
        name: 'Ayu Lestari',
        email: 'ayu@example.com',
        password: 'rahasia123',
      );

      expect(error, isNull);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.name, 'Ayu Lestari');
    });

    test('register menolak email duplikat', () {
      final auth = AuthService.create();
      expect(
        auth.register(
          name: 'Ayu',
          email: 'ayu@example.com',
          password: 'rahasia123',
        ),
        isNull,
      );
      auth.logout();
      expect(
        auth.register(
          name: 'Ayu Lagi',
          email: 'AYU@example.com',
          password: 'rahasia123',
        ),
        'Email sudah terdaftar, silakan masuk',
      );
    });

    test('register menolak input tidak valid', () {
      final auth = AuthService.create();
      expect(
        auth.register(name: 'Ab', email: 'a@b.co', password: '123456'),
        'Nama minimal 3 karakter',
      );
      expect(
        auth.register(name: 'Ayu', email: 'salah', password: '123456'),
        'Format email tidak valid',
      );
      expect(
        auth.register(name: 'Ayu', email: 'a@b.co', password: '123'),
        'Password minimal 6 karakter',
      );
      expect(auth.isLoggedIn, isFalse);
    });

    test('login sukses, salah, dan logout', () {
      final auth = AuthService.create();
      auth.register(
        name: 'Budi',
        email: 'budi@example.com',
        password: 'katasandi',
      );
      auth.logout();
      expect(auth.isLoggedIn, isFalse);

      expect(
        auth.login(email: 'budi@example.com', password: 'salah'),
        'Email atau password salah',
      );
      expect(
        auth.login(email: 'tidak@ada.co', password: 'apapun123'),
        'Email atau password salah',
      );
      expect(
        auth.login(email: 'budi@example.com', password: 'katasandi'),
        isNull,
      );
      expect(auth.currentUser?.name, 'Budi');

      auth.logout();
      expect(auth.isLoggedIn, isFalse);
    });

    test('akun demo tersedia', () {
      final auth = AuthService.create();
      expect(
        auth.login(email: 'demo@ruangkata.id', password: 'demo1234'),
        isNull,
      );
    });
  });

  group('Halaman auth', () {
    Future<void> pumpAt(
      WidgetTester tester,
      Widget child, {
      Size size = const Size(400, 800),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: child));
      await tester.pump();
    }

    testWidgets('splash menampilkan tombol aksi dan callback', (
      tester,
    ) async {
      var signIn = 0;
      var signUp = 0;
      await pumpAt(
        tester,
        SplashPage(
          onSignIn: () => signIn++,
          onSignUp: () => signUp++,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('RUANG KATA'), findsOneWidget);

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(signIn, 1);

      await tester.tap(find.text('Sign up'));
      await tester.pump();
      expect(signUp, 1);
    });

    testWidgets('login menolak form kosong dengan pesan validasi', (
      tester,
    ) async {
      var success = false;
      await pumpAt(
        tester,
        LoginPage(
          authService: AuthService.create(),
          onBack: () {},
          onGoRegister: () {},
          onSuccess: () => success = true,
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(success, isFalse);
      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });

    testWidgets('login sukses dengan akun demo', (tester) async {
      var success = false;
      await pumpAt(
        tester,
        LoginPage(
          authService: AuthService.create(),
          onBack: () {},
          onGoRegister: () {},
          onSuccess: () => success = true,
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'demo@ruangkata.id',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'demo1234');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(success, isTrue);
    });

    testWidgets('login gagal menampilkan pesan kredensial salah', (
      tester,
    ) async {
      await pumpAt(
        tester,
        LoginPage(
          authService: AuthService.create(),
          onBack: () {},
          onGoRegister: () {},
          onSuccess: () {},
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'salah@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'keliru123');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Email atau password salah'), findsOneWidget);
    });

    testWidgets('register mewajibkan centang persetujuan', (tester) async {
      var success = false;
      await pumpAt(
        tester,
        RegisterPage(
          authService: AuthService.create(),
          onBack: () {},
          onGoLogin: () {},
          onSuccess: () => success = true,
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Ayu Lestari',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ayu@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(success, isFalse);
      expect(find.text('Persetujuan wajib dicentang'), findsOneWidget);
    });

    testWidgets('register sukses setelah centang persetujuan', (
      tester,
    ) async {
      var success = false;
      await pumpAt(
        tester,
        RegisterPage(
          authService: AuthService.create(),
          onBack: () {},
          onGoLogin: () {},
          onSuccess: () => success = true,
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Ayu Lestari',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'baru@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(success, isTrue);
    });

    testWidgets('navigasi splash-login-register-back', (tester) async {
      await pumpAt(tester, const AuthFlow());

      await tester.tap(find.text('Sign up'));
      await tester.pump();
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(find.text('Welcome Back!'), findsOneWidget);

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(find.text('Welcome back'), findsOneWidget);

      await tester.tap(find.text('Sign up').last);
      await tester.pump();
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Sign in').last);
      await tester.pump();
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('AuthGate beralih splash-aplikasi saat login-logout', (
      tester,
    ) async {
      final auth = AuthService.create();
      await pumpAt(tester, AuthGate(authService: auth));
      expect(find.text('Welcome Back!'), findsOneWidget);

      auth.login(email: 'demo@ruangkata.id', password: 'demo1234');
      await tester.pump();
      expect(find.byType(MainShell), findsOneWidget);

      auth.logout();
      await tester.pump();
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('halaman auth responsif di tablet dan desktop', (
      tester,
    ) async {
      for (final size in [const Size(800, 1000), const Size(1400, 900)]) {
        await pumpAt(tester, const AuthFlow(), size: size);
        expect(
          tester.takeException(),
          isNull,
          reason: 'splash aman pada $size',
        );

        await tester.tap(find.text('Sign in'));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'login aman pada $size',
        );

        await tester.tap(find.text('Back'));
        await tester.pump();
        await tester.tap(find.text('Sign up'));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'register aman pada $size',
        );
      }
    });
  });
}
