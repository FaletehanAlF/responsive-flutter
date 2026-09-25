import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/post.dart';
import '../models/category.dart';

class ApiService {
  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data['data'] as List)
          .map((item) => Category.fromJson(item))
          .toList();
    } else {
      throw Exception('Gagal mengambil kategori');
    }
  }

  Future<void> addCategory(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 201) {
      throw Exception('Gagal menambahkan kategori');
    }
  }

  Future<void> updateCategory(int id, String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah kategori');
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/categories/$id'));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus kategori');
    }
  }

  final String baseUrl = 'http://localhost:8000';

  Future<List<Post>> getPosts() async {
    final response = await http.get(Uri.parse('$baseUrl/posts'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data['data'] as List).map((item) => Post.fromJson(item)).toList();
    } else {
      throw Exception('Gagal mengambil artikel');
    }
  }

  Future<Post> getPostById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/posts/$id'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return Post.fromJson(data['data']);
    } else {
      throw Exception('Gagal mengambil detail artikel');
    }
  }

  Future<void> addPost({
    required String title,
    required String content,
    required int categoryId,
    XFile? image,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts'),
    );

    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['category_id'] = categoryId.toString();

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Gagal menambahkan artikel');
    }
  }

  Future<void> updatePost({
    required int id,
    required String title,
    required String content,
    required int categoryId,
    String? image,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/posts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'image': image,
        'category_id': categoryId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah artikel');
    }
  }

  Future<void> deletePost(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/posts/$id'));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus artikel');
    }
  }
}
