import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:responsive_ui/models/post.dart';
import 'package:responsive_ui/pages/add_post_page.dart';
import 'package:responsive_ui/pages/articles_page.dart';
import 'package:responsive_ui/pages/category_page.dart';
import 'package:responsive_ui/pages/detail_page.dart';
import 'package:responsive_ui/pages/edit_post_page.dart';
import 'package:responsive_ui/pages/home_page.dart';
import 'package:responsive_ui/services/api_service.dart';

const List<Map<String, dynamic>> _kCategories = [
  {'id': 1, 'name': 'Teknologi'},
  {'id': 2, 'name': 'Pengembangan Dart'},
];

List<Map<String, dynamic>> _posts({int count = 4}) {
  return List.generate(count, (index) {
    final id = count - index;
    return <String, dynamic>{
      'id': id,
      'title': 'Artikel Nomor $id dengan judul yang cukup panjang untuk diuji',
      'content':
          'Paragraf isi artikel $id. ' * 12,
      'image': id.isEven ? null : '/uploads/cover$id.jpg',
      'category_id': id.isEven ? 1 : 2,
      'category_name': id.isEven ? 'Teknologi' : 'Pengembangan Dart',
      'created_at': '2026-0${(id % 9) + 1}-15 08:30:00',
    };
  });
}

ApiService _api({
  int postCount = 4,
  Map<String, int> failures = const {},
}) {
  final client = MockClient((request) async {
    final path = request.url.path;

    if (path == '/categories' && request.method == 'GET') {
      return http.Response(
        jsonEncode({'success': true, 'data': _kCategories}),
        200,
      );
    }

    if (path == '/posts' && request.method == 'GET') {
      return http.Response(
        jsonEncode({'success': true, 'data': _posts(count: postCount)}),
        200,
      );
    }

    if (path.startsWith('/posts/')) {
      final id = int.parse(path.split('/').last);
      final match = _posts(count: postCount).where((p) => p['id'] == id);
      if (match.isEmpty) {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Artikel tidak ditemukan'}),
          404,
        );
      }
      return http.Response(
        jsonEncode({'success': true, 'data': match.first}),
        200,
      );
    }

    final status = failures[path] ?? 200;
    return http.Response(
      jsonEncode({'success': status == 200, 'message': 'Gagal dari server'}),
      status,
    );
  });

  return ApiService(baseUrl: 'http://test.local', client: client);
}

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_wrap(child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  const sizes = {
    'ponsel': Size(400, 800),
    'tablet': Size(800, 1000),
    'desktop': Size(1400, 1000),
  };

  for (final entry in sizes.entries) {
    final label = entry.key;
    final size = entry.value;

    group('HomePage ($label)', () {
      testWidgets('merender daftar artikel tanpa error', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pump(tester, HomePage(apiService: _api()));

        expect(tester.takeException(), isNull);
        expect(find.text('Selamat datang di NARATA'), findsOneWidget);
        expect(find.textContaining('Artikel Nomor'), findsWidgets);
      });

      testWidgets('merender tanpa error saat backend gagal', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final failing = MockClient(
          (_) async => http.Response(
            jsonEncode({'success': false, 'message': 'boom'}),
            500,
          ),
        );
        await _pump(
          tester,
          HomePage(
            apiService: ApiService(
              baseUrl: 'http://test.local',
              client: failing,
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Gagal memuat artikel'), findsOneWidget);
        expect(find.text('Kategori tidak dapat dimuat'), findsOneWidget);
      });
    });

    group('ArticlesPage ($label)', () {
      testWidgets('merender grid artikel tanpa error', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pump(tester, ArticlesPage(apiService: _api()));

        expect(tester.takeException(), isNull);
        expect(find.textContaining('artikel ditemukan'), findsOneWidget);
      });

      testWidgets('filter kategori dan pencarian bekerja', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pump(tester, ArticlesPage(apiService: _api()));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Teknologi'));
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.byType(TextField).first,
          'tidak ada yang cocok',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Artikel tidak ditemukan'), findsOneWidget);

        await tester.enterText(find.byType(TextField).first, 'Nomor 1');
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('menampilkan estado kosong saat tidak ada artikel', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final empty = MockClient((request) async {
          if (request.url.path == '/categories') {
            return http.Response(
              jsonEncode({'success': true, 'data': _kCategories}),
              200,
            );
          }
          return http.Response(
            jsonEncode({'success': true, 'data': <Map<String, dynamic>>[]}),
            200,
          );
        });

        await _pump(
          tester,
          ArticlesPage(
            apiService: ApiService(
              baseUrl: 'http://test.local',
              client: empty,
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Belum ada artikel'), findsOneWidget);
      });
    });
  }

  group('DetailPage', () {
    testWidgets('merender detail artikel tanpa error', (tester) async {
      await _pump(tester, DetailPage(postId: 2, apiService: _api()));

      expect(tester.takeException(), isNull);
      expect(find.text('Edit Artikel'), findsOneWidget);
      expect(find.text('Hapus Artikel'), findsOneWidget);
    });

    testWidgets('menampilkan pesan 404 dari server', (tester) async {
      await _pump(tester, DetailPage(postId: 999, apiService: _api()));

      expect(tester.takeException(), isNull);
      expect(find.text('Artikel tidak ditemukan'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('dialog hapus menampilkan judul artikel', (tester) async {
      await _pump(tester, DetailPage(postId: 2, apiService: _api()));

      await _tap(tester, find.text('Hapus Artikel'));

      expect(tester.takeException(), isNull);
      expect(find.text('Hapus artikel?'), findsOneWidget);
      expect(
        find.textContaining('Artikel Nomor 2'),
        findsWidgets,
        reason: 'judul artikel tampil di app bar dan dialog',
      );
    });

    testWidgets('tombol coba lagi pada state error tidak melempar error', (
      tester,
    ) async {
      await _pump(tester, DetailPage(postId: 999, apiService: _api()));
      expect(find.text('Coba lagi'), findsOneWidget);

      await _tap(tester, find.text('Coba lagi'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('berpindah postId menampilkan data terbaru', (tester) async {
      await _pump(tester, DetailPage(postId: 2, apiService: _api()));
      expect(find.textContaining('Artikel Nomor 2'), findsWidgets);

      await tester.pumpWidget(
        _wrap(DetailPage(postId: 3, apiService: _api())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Artikel Nomor 3'), findsWidgets);
    });
  });

  group('AddPostPage', () {
    Finder get submitButton => find.widgetWithText(FilledButton, 'Tambah Artikel');

    testWidgets('validasi menolak form kosong', (tester) async {
      await _pump(tester, AddPostPage(apiService: _api()));

      await _tap(tester, submitButton);

      expect(tester.takeException(), isNull);
      expect(find.text('Judul artikel wajib diisi'), findsOneWidget);
      expect(find.text('Isi artikel wajib diisi'), findsOneWidget);
      expect(find.text('Pilih salah satu kategori'), findsOneWidget);
    });

    testWidgets('dropdown kategori terisi dari server', (tester) async {
      await _pump(tester, AddPostPage(apiService: _api()));

      expect(tester.takeException(), isNull);
      await _tap(tester, find.byType(DropdownButtonFormField<int>));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Teknologi'), findsWidgets);
      expect(find.text('Pengembangan Dart'), findsWidgets);
    });

    testWidgets('kirim form memanggil API dan memanggil onSaved', (
      tester,
    ) async {
      var savedCalled = false;
      final client = MockClient((request) async {
        if (request.url.path == '/categories') {
          return http.Response(
            jsonEncode({'success': true, 'data': _kCategories}),
            200,
          );
        }
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': 9}}),
            201,
          );
        }
        return http.Response('{}', 200);
      });

      await _pump(
        tester,
        AddPostPage(
          apiService: ApiService(
            baseUrl: 'http://test.local',
            client: client,
          ),
          onSaved: () => savedCalled = true,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan judul artikel'),
        'Judul Baru',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Tulis isi artikel di sini…'),
        'Isi artikel baru',
      );

      await _tap(tester, find.byType(DropdownButtonFormField<int>));
      await tester.pump(const Duration(milliseconds: 300));
      await _tap(tester, find.text('Teknologi').last);

      await _tap(tester, submitButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(savedCalled, isTrue);
    });

    testWidgets('menampilkan pesan error dari server', (tester) async {
      final client = MockClient((request) async {
        if (request.url.path == '/categories') {
          return http.Response(
            jsonEncode({'success': true, 'data': _kCategories}),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Kategori tidak ditemukan',
          }),
          400,
        );
      });

      await _pump(
        tester,
        AddPostPage(
          apiService: ApiService(
            baseUrl: 'http://test.local',
            client: client,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan judul artikel'),
        'Judul Baru',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Tulis isi artikel di sini…'),
        'Isi artikel baru',
      );
      await _tap(tester, find.byType(DropdownButtonFormField<int>));
      await tester.pump(const Duration(milliseconds: 300));
      await _tap(tester, find.text('Teknologi').last);

      await _tap(tester, submitButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Kategori tidak ditemukan'), findsOneWidget);
    });
  });

  group('EditPostPage', () {
    final post = Post.fromJson({
      'id': 2,
      'title': 'Judul Artikel',
      'content': 'Isi artikel',
      'image': '/uploads/cover2.jpg',
      'category_id': 1,
      'category_name': 'Teknologi',
      'created_at': '2026-01-15 08:30:00',
    });

    testWidgets('memuat nilai awal dan kategori terpilih', (tester) async {
      await _pump(tester, EditPostPage(post: post, apiService: _api()));

      expect(tester.takeException(), isNull);
      expect(
        find.widgetWithText(TextField, 'Judul Artikel'),
        findsOneWidget,
      );
      expect(find.text('Teknologi'), findsWidgets);
    });

    testWidgets('kategori yang sudah dihapus memunculkan pesan', (
      tester,
    ) async {
      final client = MockClient((request) async {
        if (request.url.path == '/categories') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 9, 'name': 'Kategori Baru'},
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      await _pump(
        tester,
        EditPostPage(
          post: post,
          apiService: ApiService(
            baseUrl: 'http://test.local',
            client: client,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('Kategori asli sudah tidak tersedia, pilih ulang'),
        findsOneWidget,
      );
    });

    testWidgets('tombol hapus gambar menandai gambar untuk dihapus', (
      tester,
    ) async {
      String? sentImage;
      final client = MockClient((request) async {
        if (request.url.path == '/categories') {
          return http.Response(
            jsonEncode({'success': true, 'data': _kCategories}),
            200,
          );
        }
        sentImage = jsonDecode(request.body)['image'] as String?;
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok'}),
          200,
        );
      });

      await _pump(
        tester,
        EditPostPage(
          post: post,
          apiService: ApiService(
            baseUrl: 'http://test.local',
            client: client,
          ),
        ),
      );

      expect(find.text('Hapus gambar'), findsOneWidget);
      await _tap(tester, find.text('Hapus gambar'));
      expect(find.text('Batal hapus'), findsOneWidget);

      await _tap(tester, find.widgetWithText(FilledButton, 'Simpan Perubahan'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(sentImage, '');
    });
  });

  group('CategoryPage', () {
    testWidgets('merender daftar kategori beserta jumlah artikel', (
      tester,
    ) async {
      await _pump(tester, CategoryPage(apiService: _api()));

      expect(tester.takeException(), isNull);
      expect(find.text('Teknologi'), findsOneWidget);
      expect(find.text('Pengembangan Dart'), findsOneWidget);
      expect(find.text('2 artikel'), findsOneWidget);
    });

    testWidgets('menampilkan pesan 409 dari server saat hapus gagal', (
      tester,
    ) async {
      final client = MockClient((request) async {
        if (request.url.path == '/categories' && request.method == 'GET') {
          return http.Response(
            jsonEncode({'success': true, 'data': _kCategories}),
            200,
          );
        }
        if (request.url.path == '/categories' && request.method == 'DELETE') {
          return http.Response(
            jsonEncode({
              'success': false,
              'message':
                  'Kategori tidak dapat dihapus karena masih digunakan oleh artikel',
            }),
            409,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      await _pump(
        tester,
        CategoryPage(
          apiService: ApiService(
            baseUrl: 'http://test.local',
            client: client,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pump();
      await tester.tap(find.text('Hapus').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Kategori tidak dapat dihapus karena masih digunakan oleh artikel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('dialog tambah kategori tetap terbuka bila nama kosong', (
      tester,
    ) async {
      await _pump(tester, CategoryPage(apiService: _api()));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(find.text('Tambah Kategori'), findsOneWidget);

      await tester.tap(find.text('Simpan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Nama kategori wajib diisi'), findsOneWidget);
      expect(find.text('Tambah Kategori'), findsOneWidget);
    });
  });
}
