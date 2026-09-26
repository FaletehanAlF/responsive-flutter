import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:responsive_ui/pages/articles_page.dart';
import 'package:responsive_ui/pages/home_page.dart';
import 'package:responsive_ui/services/api_service.dart';

const List<Map<String, dynamic>> _kCategories = [
  {'id': 1, 'name': 'Teknologi'},
  {'id': 2, 'name': 'Pengembangan Dart'},
];

/// Judul panjang (2 baris) + nama kategori panjang untuk menekan layout.
List<Map<String, dynamic>> _posts() {
  return List.generate(6, (index) {
    final id = 6 - index;
    return <String, dynamic>{
      'id': id,
      'title':
          'Artikel Nomor $id dengan judul yang sangat panjang agar membungkus dua baris penuh diuji',
      'content': 'Paragraf isi artikel $id. ' * 12,
      'image': id.isEven ? null : '/uploads/cover$id.jpg',
      'category_id': id.isEven ? 1 : 2,
      'category_name':
          id.isEven ? 'Teknologi' : 'Pengembangan Dart Lanjutan',
      'created_at': '2026-0${(id % 9) + 1}-15 08:30:00',
    };
  });
}

ApiService _api() {
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
        jsonEncode({'success': true, 'data': _posts()}),
        200,
      );
    }
    return http.Response('{}', 404);
  });
  return ApiService(baseUrl: 'http://test.local', client: client);
}

Future<void> _pumpAt(
  WidgetTester tester,
  Widget child,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Mensimulasikan user menggeser lebar jendela web berulang kali.
Future<void> _dragWidths(
  WidgetTester tester,
  Widget Function() rebuild,
  List<Size> sizes,
) async {
  for (final size in sizes) {
    tester.view.physicalSize = size;
    await tester.pumpWidget(MaterialApp(home: rebuild()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.takeException(),
      isNull,
      reason: 'tidak boleh ada error pada ukuran $size',
    );
  }
}

void main() {
  tearDown(() {});

  group('Resize HomePage tanpa error', () {
    // Lebar digeser naik-turun melewati breakpoint 600 & 1024.
    final widths = [
      const Size(400, 800),
      const Size(550, 800),
      const Size(620, 900),
      const Size(800, 1000),
      const Size(1000, 900),
      const Size(1100, 900),
      const Size(1400, 1000),
      const Size(900, 900),
      const Size(500, 800),
      const Size(400, 800),
    ];

    testWidgets('carousel + grid recommendation aman di semua lebar',
        (tester) async {
      addTearDown(tester.view.reset);
      await _pumpAt(tester, HomePage(apiService: _api()), widths.first);
      expect(tester.takeException(), isNull);

      await _dragWidths(tester, () => HomePage(apiService: _api()), widths);
    });
  });

  group('Resize ArticlesPage tanpa error', () {
    final widths = [
      const Size(400, 800),
      const Size(650, 900),
      const Size(800, 1000),
      const Size(1200, 900),
      const Size(1400, 1000),
      const Size(700, 900),
      const Size(400, 800),
    ];

    testWidgets('grid discover aman di semua lebar', (tester) async {
      addTearDown(tester.view.reset);
      await _pumpAt(tester, ArticlesPage(apiService: _api()), widths.first);
      expect(tester.takeException(), isNull);

      await _dragWidths(
          tester, () => ArticlesPage(apiService: _api()), widths);
    });
  });
}
