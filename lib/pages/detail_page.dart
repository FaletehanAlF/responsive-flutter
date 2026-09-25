import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/category_badge.dart';
import '../widgets/narata_app_bar.dart';
import 'edit_post_page.dart';

class DetailPage extends StatefulWidget {
  final int postId;
  final void Function(bool changed)? onClose;
  final ApiService? apiService;

  const DetailPage({
    super.key,
    required this.postId,
    this.onClose,
    this.apiService,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final ApiService apiService = widget.apiService ?? ApiService();

  late int _postId;
  late Future<Post> _postFuture;

  @override
  void initState() {
    super.initState();
    _postId = widget.postId;
    _postFuture = apiService.getPostById(_postId);
  }

  @override
  void didUpdateWidget(DetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postId != _postId) {
      _postId = widget.postId;
      _reload();
    }
  }

  void _reload() {
    setState(() => _postFuture = apiService.getPostById(_postId));
  }

  void _close(bool changed) {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose(changed);
    } else {
      Navigator.pop(context, changed);
    }
  }

  Future<void> _openEdit(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPostPage(post: post)),
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
          content: Text(
            '"${post.title}" akan dihapus permanen dan tidak dapat dikembalikan.',
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

    if (confirm != true || !mounted) return;

    try {
      await apiService.deletePost(post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artikel berhasil dihapus')),
      );
      _close(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus artikel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post>(
      future: _postFuture,
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat artikel',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final post = snapshot.data;
        if (post == null) {
          return Scaffold(
            appBar: NarataAppBar(
              title: const Text('Detail Artikel'),
              showBack: true,
              onBack: widget.onClose == null ? null : () => _close(false),
            ),
            body: const Center(child: Text('Artikel tidak ditemukan')),
          );
        }

        return _buildContent(context, post);
      },
    );
  }

  Widget _buildContent(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrl;
    final date = formatPostDate(post.createdAt);

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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color:
                                      colorScheme.surfaceContainerHighest,
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
                          Flexible(
                            child: CategoryBadge(label: post.categoryName),
                          ),
                          if (date.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              date,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: colorScheme.outline),
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
                      SelectableText(
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
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Artikel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(post),
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
  }
}
