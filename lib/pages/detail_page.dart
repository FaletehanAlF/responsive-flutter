import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/news_theme.dart';
import '../widgets/news_widgets.dart';
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
  bool _bookmarked = false;

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
    setState(() {
      _postFuture = apiService.getPostById(_postId);
    });
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

  void _showMore(Post post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2E6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Artikel'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openEdit(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Hapus Artikel',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Bagikan'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan artikel disalin'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post>(
      future: _postFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: NewsColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          final err = '${snapshot.error}';
          final isNotFound =
              err.toLowerCase().contains('tidak ditemukan') ||
                  err.contains('404');
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: NewsColors.muted,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal memuat artikel',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNotFound ? 'Artikel tidak ditemukan' : err,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: NewsColors.subtitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _close(false),
                            child: const Text('Kembali'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final post = snapshot.data;
        if (post == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Artikel tidak ditemukan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

        return _buildNewsDetail(context, post);
      },
    );
  }

  Widget _buildNewsDetail(BuildContext context, Post post) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final device = deviceForWidth(maxW);
        final isMobile = device == AppDevice.mobile;

        final heroHeight = isMobile
            ? 400.0
            : device == AppDevice.tablet
                ? 440.0
                : 480.0;
        final contentMax = isMobile ? double.infinity : 780.0;
        const overlap = 28.0;

        final imageUrl = post.imageUrl;
        final meta = relativeTime(post.createdAt);

        return Scaffold(
          backgroundColor: const Color(0xFFF6F6F7),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 900,
              ),
              child: Stack(
                children: [
                  // ── Hero image full-bleed ──
                  SizedBox(
                    height: heroHeight,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: isMobile
                          ? BorderRadius.zero
                          : const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: const Color(0xFFE4E6EB),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: NewsColors.primary,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, e, s) => Container(
                                color: const Color(0xFF3A3A3C),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 56,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              color: const Color(0xFF3A3A3C),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 56,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x59000000),
                                  Colors.transparent,
                                  Color(0x22000000),
                                  Color(0xE6000000),
                                ],
                                stops: [0.0, 0.35, 0.62, 1.0],
                              ),
                            ),
                          ),
                          // Teks overlay di bawah hero
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: overlap + 18,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: contentMax == double.infinity
                                    ? double.infinity
                                    : contentMax,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  FloatingCategoryBadge(
                                    label: post.categoryName,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    post.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      height: 1.22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        'Trending',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      if (meta.isNotEmpty) ...[
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Text(
                                            '•',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          meta,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Top bar melayang ──
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _GlassCircleButton(
                          icon: Icons.arrow_back,
                          onTap: () => _close(false),
                        ),
                        const Spacer(),
                        _GlassCircleButton(
                          icon: _bookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          onTap: () => setState(
                            () => _bookmarked = !_bookmarked,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _GlassCircleButton(
                          icon: Icons.more_horiz,
                          onTap: () => _showMore(post),
                        ),
                      ],
                    ),
                  ),

                  // ── Konten scroll + kartu putih overlap ──
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: heroHeight - overlap,
                      bottom: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: contentMax == double.infinity
                              ? double.infinity
                              : contentMax,
                        ),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              18,
                              20,
                              20,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Author row ala CNN Indonesia
                                Row(
                                  children: [
                                    _SourceLogo(name: post.categoryName),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              post.categoryName,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: NewsColors.ink,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Icon(
                                            Icons.verified,
                                            size: 16,
                                            color: NewsColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ..._paragraphs(post.content).map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 14,
                                    ),
                                    child: Text(
                                      p,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.65,
                                        color: Color(0xFF2B2B2E),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Aksi Kelola (dipertahankan untuk kompatibilitas)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openEdit(post),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        label:
                                            const Text('Edit Artikel'),
                                        style: OutlinedButton.styleFrom(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            vertical: 13,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
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
                                        label: const Text(
                                          'Hapus Artikel',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding:
                                              const EdgeInsets.symmetric(
                                            vertical: 13,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _paragraphs(String content) {
    final parts = content
        .split(RegExp(r'\n\s*\n|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return [content.trim().isEmpty ? '-' : content.trim()];
    return parts;
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// Logo sumber ala CNN (lingkaran merah + inisial putih).
class _SourceLogo extends StatelessWidget {
  final String name;

  const _SourceLogo({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = initialFor(name);
    final short =
        initials.length >= 3 ? initials.substring(0, 3) : initials;
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFFCC0000),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        short.isEmpty ? 'N' : short,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
