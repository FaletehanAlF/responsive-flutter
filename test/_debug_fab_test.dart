import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:responsive_ui/pages/category_page.dart';
import 'package:responsive_ui/services/api_service.dart';
import 'dart:convert';

const cats = [
  {'id': 1, 'name': 'Teknologi'},
  {'id': 2, 'name': 'Dart'},
];

void main() {
  testWidgets('delete 409', (tester) async {
    final client = MockClient((request) async {
      debugPrint('REQ ${request.method} ${request.url.path}');
      if (request.method == 'GET' && request.url.path == '/categories') {
        return http.Response(jsonEncode({'success': true, 'data': cats}), 200);
      }
      if (request.url.path.startsWith('/posts')) {
        return http.Response(jsonEncode({'success': true, 'data': <Map<String, dynamic>>[]}), 200);
      }
      if (request.method == 'DELETE') {
        return http.Response(jsonEncode({'success': false, 'message': 'Kategori tidak dapat dihapus karena masih digunakan oleh artikel'}), 409);
      }
      return http.Response(jsonEncode({'success': true, 'data': cats}), 200);
    });

    await tester.pumpWidget(MaterialApp(home: CategoryPage(apiService: ApiService(baseUrl: 'http://t', client: client))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    debugPrint('delete icons: ${find.byIcon(Icons.delete_outline).evaluate().length}');
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    debugPrint('confirm dialog: ${find.text('Hapus kategori?').evaluate().length}');
    debugPrint('Hapus buttons: ${find.widgetWithText(FilledButton, 'Hapus').evaluate().length}');
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    debugPrint('snackbar: ${find.textContaining('masih digunakan').evaluate().length}');
  });
}
