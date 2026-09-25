import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/post.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

const int kMaxImageSizeInBytes = 2 * 1024 * 1024;

const List<String> kSupportedImageExtensions = [
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
];

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({this.baseUrl = kApiBaseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  Never _fail(http.Response response, String fallback) {
    String message = fallback;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final serverMessage = decoded['message'];
        if (serverMessage is String && serverMessage.trim().isNotEmpty) {
          message = serverMessage;
        }
      }
    } catch (_) {}

    throw ApiException(message, statusCode: response.statusCode);
  }

  Map<String, dynamic> _decodeData(http.Response response, String fallback) {
    if (response.statusCode != 200) {
      _fail(response, fallback);
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! Map) {
        throw ApiException(fallback, statusCode: response.statusCode);
      }
      return (decoded['data'] as Map).cast<String, dynamic>();
    } on FormatException {
      throw ApiException(fallback, statusCode: response.statusCode);
    }
  }

  List<dynamic> _decodeList(http.Response response, String fallback) {
    if (response.statusCode != 200) {
      _fail(response, fallback);
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
        throw ApiException(fallback, statusCode: response.statusCode);
      }
      return decoded['data'] as List<dynamic>;
    } on FormatException {
      throw ApiException(fallback, statusCode: response.statusCode);
    }
  }

  MediaType _mediaTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    throw ApiException(
      'Format gambar tidak didukung. '
      'Hanya jpg, jpeg, png, webp yang diizinkan',
    );
  }

  Future<XFile> _prepareImage(XFile image) async {
    if (!kSupportedImageExtensions.any(image.name.toLowerCase().endsWith)) {
      throw ApiException(
        'Format gambar tidak didukung. '
        'Hanya jpg, jpeg, png, webp yang diizinkan',
      );
    }

    final size = await image.length();
    if (size > kMaxImageSizeInBytes) {
      final sizeInMb = (size / (1024 * 1024)).toStringAsFixed(1);
      throw ApiException('Ukuran gambar $sizeInMb MB melebihi batas 2 MB');
    }

    return image;
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    final data = _decodeList(response, 'Gagal mengambil kategori');
    return data
        .map((item) => Category.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> addCategory(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 201) {
      _fail(response, 'Gagal menambahkan kategori');
    }
  }

  Future<void> updateCategory(int id, String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200) {
      _fail(response, 'Gagal mengubah kategori');
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/categories/$id'));

    if (response.statusCode != 200) {
      _fail(response, 'Gagal menghapus kategori');
    }
  }

  Future<List<Post>> getPosts({int? categoryId, String? search}) async {
    final query = <String, String>{};
    if (categoryId != null) {
      query['category_id'] = '$categoryId';
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/posts')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await http.get(uri);
    final data = _decodeList(response, 'Gagal mengambil artikel');
    return data
        .map((item) => Post.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Post> getPostById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/posts/$id'));
    final data = _decodeData(response, 'Gagal mengambil detail artikel');
    return Post.fromJson(data);
  }

  Future<void> addPost({
    required String title,
    required String content,
    required int categoryId,
    XFile? image,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/posts'))
      ..fields['title'] = title
      ..fields['content'] = content
      ..fields['category_id'] = '$categoryId';

    if (image != null) {
      final prepared = await _prepareImage(image);
      final bytes = await prepared.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: prepared.name,
          contentType: _mediaTypeFor(prepared.name),
        ),
      );
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 201) {
      _fail(response, 'Gagal menambahkan artikel');
    }
  }

  Future<void> updatePost({
    required int id,
    required String title,
    required String content,
    required int categoryId,
    String? image,
    XFile? newImage,
  }) async {
    if (newImage != null) {
      final request =
          http.MultipartRequest('PUT', Uri.parse('$baseUrl/posts/$id'))
            ..fields['title'] = title
            ..fields['content'] = content
            ..fields['category_id'] = '$categoryId';

      final prepared = await _prepareImage(newImage);
      final bytes = await prepared.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: prepared.name,
          contentType: _mediaTypeFor(prepared.name),
        ),
      );

      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode != 200) {
        _fail(response, 'Gagal mengubah artikel');
      }
      return;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/posts/$id'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'image': image,
        'category_id': categoryId,
      }),
    );

    if (response.statusCode != 200) {
      _fail(response, 'Gagal mengubah artikel');
    }
  }

  Future<void> deletePost(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/posts/$id'));

    if (response.statusCode != 200) {
      _fail(response, 'Gagal menghapus artikel');
    }
  }
}
