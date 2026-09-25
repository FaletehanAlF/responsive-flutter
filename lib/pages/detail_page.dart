import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import 'edit_post_page.dart';

class DetailPage extends StatefulWidget {
  final int postId;

  const DetailPage({super.key, required this.postId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ApiService apiService = ApiService();

  late Future<Post> futurePost;

  @override
  void initState() {
    super.initState();
    futurePost = apiService.getPostById(widget.postId);
  }

  void _reload() {
    setState(() {
      futurePost = apiService.getPostById(widget.postId);
    });
  }

  String _formatDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.contains('T')) return value.split('T').first;
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post>(
      future: futurePost,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Artikel')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Artikel tidak ditemukan')),
          );
        }

        final post = snapshot.data!;
        final imageUrl = post.imageUrl;
        final date = _formatDate(post.createdAt);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Artikel'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Artikel',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostPage(post: post),
                    ),
                  );
                  if (result == true && context.mounted) _reload();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
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
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
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
                      SnackBar(content: Text('Gagal menghapus artikel: $e')),
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
                if (horizontalPadding < 16) horizontalPadding = 16;
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            post.categoryName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                        ),
                        if (date.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today, size: 14),
                                const SizedBox(width: 6),
                                Text(date),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (imageUrl != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      post.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
