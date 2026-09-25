import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_ui/main.dart';
import 'package:responsive_ui/models/category.dart';
import 'package:responsive_ui/models/post.dart';
import 'package:responsive_ui/utils/formatters.dart';
import 'package:responsive_ui/widgets/category_badge.dart';

void main() {
  group('Post', () {
    test('mem-parsing JSON artikel dengan benar', () {
      final post = Post.fromJson(const {
        'id': 7,
        'title': ' Judul Artikel ',
        'content': 'Isi artikel',
        'image': '/uploads/cover.jpg',
        'category_id': 3,
        'category_name': 'Teknologi',
        'created_at': '2026-01-15 08:30:00',
      });

      expect(post.id, 7);
      expect(post.title, ' Judul Artikel ');
      expect(post.categoryId, 3);
      expect(post.categoryName, 'Teknologi');
    });

    test('id dan category_id dari string di-normalisasi ke integer', () {
      final post = Post.fromJson(const {
        'id': '12',
        'title': 'Judul',
        'content': 'Isi',
        'category_id': '4',
      });

      expect(post.id, 12);
      expect(post.categoryId, 4);
    });

    test('nilai kosong menghasilkan nilai default yang aman', () {
      final post = Post.fromJson(const <String, dynamic>{});

      expect(post.id, 0);
      expect(post.title, '');
      expect(post.content, '');
      expect(post.categoryName, 'Tanpa Kategori');
      expect(post.imageUrl, isNull);
    });

    test('imageUrl absolut dipertahankan', () {
      final post = Post.fromJson(const {
        'id': 1,
        'title': 'Judul',
        'content': 'Isi',
        'category_id': 1,
        'image': 'https://contoh.com/gambar.png',
      });

      expect(post.imageUrl, 'https://contoh.com/gambar.png');
    });

    test('imageUrl kosong atau null menghasilkan null', () {
      for (final value in [null, '', '   ']) {
        final post = Post.fromJson({
          'id': 1,
          'title': 'Judul',
          'content': 'Isi',
          'category_id': 1,
          'image': value,
        });

        expect(post.imageUrl, isNull, reason: 'image="$value"');
      }
    });

    test('imageUrl relatif diawali host backend', () {
      final post = Post.fromJson(const {
        'id': 1,
        'title': 'Judul',
        'content': 'Isi',
        'category_id': 1,
        'image': '/uploads/cover.jpg',
      });

      expect(post.imageUrl, endsWith('/uploads/cover.jpg'));
      expect(post.imageUrl, startsWith('http'));
    });

    test('snippet diringkas maksimal 111 karakter', () {
      final short = Post.fromJson(const {
        'id': 1,
        'title': 'Judul',
        'content': 'Isi pendek',
        'category_id': 1,
      });
      expect(short.snippet, 'Isi pendek');

      final long = Post.fromJson({
        'id': 1,
        'title': 'Judul',
        'content': List.filled(60, 'kata').join('   '),
        'category_id': 1,
      });
      expect(long.snippet.length, 111);
      expect(long.snippet, endsWith('…'));
    });
  });

  group('Category', () {
    test('mem-parsing JSON kategori', () {
      final category = Category.fromJson(const {'id': 2, 'name': ' Sains '});

      expect(category.id, 2);
      expect(category.name, 'Sains');
    });

    test('perbandingan berdasarkan id', () {
      const a = Category(id: 1, name: 'Satu');
      const b = Category(id: 1, name: 'Satu lagi');
      const c = Category(id: 2, name: 'Dua');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('formatPostDate', () {
    test('mengembalikan string kosong untuk input kosong', () {
      expect(formatPostDate(''), '');
      expect(formatPostDate('   '), '');
    });

    test('mengembalikan input apa adanya bila tidak bisa diparse', () {
      expect(formatPostDate('bukan tanggal'), 'bukan tanggal');
    });

    test('mem-format tanggal valid ke locale Indonesia', () {
      expect(formatPostDate('2026-01-15 08:30:00'), '15 Jan 2026');
    });
  });

  group('CategoryBadge', () {
    testWidgets('menampilkan label dalam huruf kapital', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryBadge(label: 'Teknologi'),
          ),
        ),
      );

      expect(find.text('TEKNOLOGI'), findsOneWidget);
    });
  });

  group('MyApp', () {
    testWidgets('tanpa error saat backend tidak terjangkau', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Beranda'), findsWidgets);
    });

    testWidgets('navigasi ke tabArtikel', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      await tester.tap(find.text('Artikel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Semua Artikel'), findsWidgets);
    });
  });
}
