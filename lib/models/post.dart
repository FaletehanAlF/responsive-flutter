import '../services/api_service.dart';

class Post {
  final int id;
  final String title;
  final String content;
  final String? image;
  final int categoryId;
  final String categoryName;
  final String createdAt;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.categoryId,
    required this.categoryName,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: _parseId(json['id']),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      image: json['image']?.toString(),
      categoryId: _parseId(json['category_id']),
      categoryName: json['category_name']?.toString() ?? 'Tanpa Kategori',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  String? get imageUrl {
    final value = image?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final path = value.startsWith('/') ? value : '/$value';
    return '$kApiBaseUrl$path';
  }

  String get snippet {
    final clean = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= 110) return clean;
    return '${clean.substring(0, 110)}…';
  }
}
