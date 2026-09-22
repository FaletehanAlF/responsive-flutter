import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class ApiService {
  final String baseUrl = 'http://localhost:8000';

  Future<List<Post>> getPosts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data['data'] as List)
          .map((item) => Post.fromJson(item))
          .toList();
    } else {
      throw Exception('Gagal mengambil artikel');
    }
  }

  Future<Post> getPostById(int id) async {
  final response = await http.get(
    Uri.parse('$baseUrl/posts/$id'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    return Post.fromJson(data['data']);
  } else {
    throw Exception('Gagal mengambil detail artikel');
  }
}
}