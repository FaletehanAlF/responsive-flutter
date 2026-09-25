import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import 'edit_post_page.dart';

/// Halaman detail artikel: badge kategori, tanggal, judul besar,
/// gambar utama 16:9, isi artikel, dan aksi Edit/Hapus.
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

  /// Gambar utama artikel.
  /// Desktop dibatasi tingginya (340px, dalam rentang 320-380px) agar tidak
  /// mendominasi viewport dan judul/konten tetap terlihat; mobile tetap
  /// 16:9 mengikuti lebar layar. BoxFit.cover tanpa distorsi, radius 16px.
  Widget _heroImage(BuildContext context, String imageUrl, bool isDesktop) {
    final image = Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 48),
          ),
        );
      },
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: isDesktop
          ? SizedBox(height: 340, width: double.infinity, child: image)
          : AspectRatio(aspectRatio: 16 / 9, child: image),
    );
  }

  Future<void> _confirmDelete(Post post) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus artikel?'),
          content: const Text(
            'Artikel yang dihapus tidak dapat dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await apiService.deletePost(post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artikel berhasil dihapus')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus artikel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
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
            title: Text(
              post.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                onPressed: () => _confirmDelete(post),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth >= 600;
              final double cap = isDesktop ? 760 : double.infinity;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cap),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  post.categoryName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: colorScheme.onSecondaryContainer,
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
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        date,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                          ),
                          if (imageUrl != null) ...[
                            const SizedBox(height: 16),
                            _heroImage(context, imageUrl, isDesktop),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            post.content,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
