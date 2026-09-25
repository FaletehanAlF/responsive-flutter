class Post {
  final int id;
  final String title;
  final String content;
  final String? image;
  final int categoryId;
  final String categoryName;
  final String createdAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.categoryId,
    required this.categoryName,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value is int) return value;
      return int.tryParse('$value') ?? 0;
    }

    return Post(
      id: parseId(json['id']),
      title: '${json['title'] ?? ''}',
      content: '${json['content'] ?? ''}',
      image: json['image']?.toString(),
      categoryId: parseId(json['category_id']),
      categoryName: json['category_name']?.toString() ?? 'Tanpa Kategori',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  /// Mengubah relative path backend (/uploads/xxx.jpg)
  /// menjadi URL penuh (http://localhost:8000/uploads/xxx.jpg).
  /// Return null jika tidak ada gambar agar UI tidak me-render Image.network.
  /// Dijamin tidak menghasilkan double slash dan tidak menduplikasi base URL.
  String? get imageUrl {
    if (image == null) return null;
    final value = image!.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final path = value.startsWith('/') ? value : '/$value';
    return 'http://localhost:8000$path';
  }
}