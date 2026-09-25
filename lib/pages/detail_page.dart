import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/category_badge.dart';
import '../widgets/narata_app_bar.dart';
import 'edit_post_page.dart';

class DetailPage extends StatefulWidget {
  final int postId;
  final void Function(bool changed)? onClose;

  const DetailPage({super.key, required this.postId, this.onClose});

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

  String _date(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('d MMM yyyy', 'id').format(parsed);
  }

  void _close(bool changed) {
    if (widget.onClose != null) {
      widget.onClose!(changed);
    } else {
      Navigator.pop(context, changed);
    }
  }

  Future<void> _openEdit(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostPage(post: post),
      ),
    );
    if (result == true && mounted) _reload();
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
      _close(true);
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
            appBar: NarataAppBar(
              title: const Text('Detail Artikel'),
              showBack: true,
              onBack: widget.onClose == null ? null : () => _close(false),
            ),
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
        final date = _date(post.createdAt);

        return Scaffold(
          appBar: NarataAppBar(
            title: Text(
              post.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            showBack: true,
            onBack: widget.onClose == null ? null : () => _close(false),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool desktop = constraints.maxWidth >= 600;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: desktop ? 760 : double.infinity,
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      color: colorScheme
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
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CategoryBadge(
                                label: post.categoryName,
                              ),
                              if (date.isNotEmpty) ...[
                                Text(
                                  ' • ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                ),
                                Text(
                                  date,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 16),
                          Text(
                            post.content,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.7),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openEdit(post),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Edit Artikel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _confirmDelete(post),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Hapus Artikel'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
