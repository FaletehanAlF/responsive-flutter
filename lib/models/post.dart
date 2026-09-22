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
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      image: json['image'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      createdAt: json['created_at'],
    );
  }
}