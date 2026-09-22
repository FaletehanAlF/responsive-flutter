import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';

class DetailPage extends StatelessWidget {
  final int postId;

  const DetailPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return FutureBuilder<Post>(
      future: apiService.getPostById(postId),
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Artikel'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Hapus Artikel'),
                        content: const Text(
                          'Apakah kamu yakin ingin menghapus artikel ini?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, true);
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
                      const SnackBar(content: Text('Artikel berhasil dihapus')),
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
        );
      },
    );
  }
}
