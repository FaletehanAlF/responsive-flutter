import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import 'edit_post_page.dart';

class DetailPage extends StatelessWidget {
  final int postId;

  const DetailPage({
    super.key,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return FutureBuilder<Post>(
      future: apiService.getPostById(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Detail Artikel'),
            ),
            body: Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Text('Artikel tidak ditemukan'),
            ),
          );
        }

        final post = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Artikel'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Artikel',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostPage(
                        post: post,
                      ),
                    ),
                  );

                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Hapus Artikel',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Hapus Artikel'),
                        content: const Text(
                          'Apakah kamu yakin ingin menghapus artikel ini?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, false);
                            },
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, true);
                            },
                            child: const Text('Hapus'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm != true) return;

                  try {
                    await apiService.deletePost(post.id);

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Artikel berhasil dihapus'),
                      ),
                    );

                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal menghapus artikel: $e',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth >= 600;

              double horizontalPadding = 16;

              if (isDesktop) {
                horizontalPadding = (constraints.maxWidth - 700) / 2;

                if (horizontalPadding < 16) {
                  horizontalPadding = 16;
                }
              }

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        post.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}