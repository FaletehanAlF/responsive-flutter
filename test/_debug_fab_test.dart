import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:responsive_ui/pages/category_page.dart';
import 'package:responsive_ui/services/api_service.dart';
import 'dart:convert';

const cats = [
  {'id': 1, 'name': 'Teknologi'},
  {'id': 2, 'name': 'Pengembangan Dart'},
];

ApiService api() {
  final client = MockClient((request) async {
    if (request.url.path == '/categories') {
      return http.Response(jsonEncode({'success': true, 'data': cats}), 200);
    }
    return http.Response(jsonEncode({'success': true, 'data': <Map<String, dynamic>>[]}), 200);
  });
  return ApiService(baseUrl: 'http://t', client: client);
}

void main() {
  testWidgets('fab with data', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CategoryPage(apiService: api())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    debugPrint('tiles: ${find.byType(ListTile).evaluate().length}');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    debugPrint('Dialog text: ${find.text('Tambah Kategori').evaluate().length}');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    debugPrint('empty msg: ${find.text('Nama kategori wajib diisi').evaluate().length}');
    debugPrint('Dialog still: ${find.text('Tambah Kategori').evaluate().length}');
  });
}
