import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:responsive_ui/pages/detail_page.dart';
import 'package:responsive_ui/services/api_service.dart';

Map<String, dynamic> _postJson() => {
      'id': 2,
      'title': 'Artikel Nomor 2 dengan judul yang cukup panjang untuk diuji',
      'content': 'Paragraf isi artikel 2. ' * 20,
      'image': '/uploads/cover2.jpg',
      'category_id': 1,
      'category_name': 'Teknologi',
      'created_at': '2026-02-15 08:30:00',
    };

ApiService _api() {
  final client = MockClient((request) async {
    return http.Response(
      jsonEncode({'success': true, 'data': _postJson()}),
      200,
    );
  });
  return ApiService(baseUrl: 'http://test.local', client: client);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('MOBILE: tombol back memanggil onClose', (tester) async {
    var closed = false;
    await _pump(
      tester,
      DetailPage(
        postId: 2,
        apiService: _api(),
        onClose: (_) => closed = true,
      ),
    );
    expect(tester.takeException(), isNull);

    final back = find.byIcon(Icons.arrow_back);
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('WEB: header back terlihat & memanggil onClose', (tester) async {
    var closed = false;
    await _pump(
      tester,
      DetailPage(
        postId: 2,
        apiService: _api(),
        onClose: (_) => closed = true,
      ),
      size: const Size(1400, 900),
    );
    expect(tester.takeException(), isNull);

    // Layout web: ada breadcrumb + judul Detail Artikel di header
    expect(find.text('Detail Artikel'), findsWidgets);
    expect(find.textContaining('Beranda / Artikel'), findsOneWidget);

    final back = find.byIcon(Icons.arrow_back);
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('TABLET: layout web satu kolom + back berfungsi', (tester) async {
    var closed = false;
    await _pump(
      tester,
      DetailPage(
        postId: 2,
        apiService: _api(),
        onClose: (_) => closed = true,
      ),
      size: const Size(800, 1000),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Detail Artikel'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    expect(closed, isTrue);
  });
}
