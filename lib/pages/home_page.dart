import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/post.dart';
import '../models/category.dart';
import 'detail_page.dart';
import 'add_post_page.dart';
import 'category_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();

  late Future<List<Post>> posts;
  late Future<List<Category>> categories;

  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    posts = apiService.getPosts();
    categories = apiService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostPage()),
          );
          if (!context.mounted) return;
          if (result == true) {
            setState(() {
              posts = apiService.getPosts();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('NARATA'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              );
              setState(() {
                posts = apiService.getPosts();
                categories = apiService.getCategories();
              });
            },
            icon: const Icon(Icons.category),
            tooltip: 'Kategori',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;

          double horizontalPadding = 0;
          if (isDesktop) {
            horizontalPadding = (constraints.maxWidth - 700) / 2;
            if (horizontalPadding < 16) {
              horizontalPadding = 16;
            }
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                FutureBuilder<List<Category>>(
                  future: categories,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: Text('Memuat kategori...')),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: Text('Gagal memuat kategori')),
                      );
                    }

                    final data = snapshot.data ?? [];

                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: DropdownButton<int?>(
                        value: selectedCategoryId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Semua',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...data.map((category) {
                            return DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(
                                category.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId = value;
                          });
                        },
                      ),
                    );
                  },
                ),
                Expanded(
                  child: FutureBuilder<List<Post>>(
                    future: posts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final data = snapshot.data ?? [];

                      final List<Post> filtered;
                      if (selectedCategoryId == null) {
                        filtered = data;
                      } else {
                        filtered = data
                            .where(
                              (post) =>
                                  post.categoryId == selectedCategoryId,
                            )
                            .toList();
                      }

                      if (filtered.isEmpty) {
                        if (selectedCategoryId == null) {
                          return const Center(
                            child: Text('Belum ada artikel'),
                          );
                        } else {
                          return const Center(
                            child: Text(
                              'Belum ada artikel pada kategori ini',
                            ),
                          );
                        }
                      }

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final post = filtered[index];

                          return ListTile(
                            leading: post.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      post.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.broken_image,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(Icons.image_not_supported),
                            title: Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              post.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailPage(postId: post.id),
                                ),
                              );
                              if (!context.mounted) return;
                              setState(() {
                                posts = apiService.getPosts();
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
