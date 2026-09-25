import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:responsive_ui/pages/category_page.dart';
import 'package:responsive_ui/services/api_service.dart';
import 'dart:convert';

void main() {
  testWidgets('fab', (tester) async {
    final client = MockClient((r) async => http.Response(
        jsonEncode({'success': true, 'data': <Map<String, dynamic>>[]}), 200));
    await tester.pumpWidget(MaterialApp(
      home: CategoryPage(apiService: ApiService(baseUrl: 'http://t', client: client)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    debugPrint('FAB count: ${find.byType(FloatingActionButton).evaluate().length}');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    debugPrint('Dialog text: ${find.text('Tambah Kategori').evaluate().length}');
    debugPrint('AlertDialog count: ${find.byType(AlertDialog).evaluate().length}');
  });
}
