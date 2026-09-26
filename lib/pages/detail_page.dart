import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
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
    } else if (Navigator.of(context).canPop()) {
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          title: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 24,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'Hapus artikel?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: NewsColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${post.title}" akan dihapus permanen dari daftar.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: Color(0xFF3A3A3E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 18,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tindakan ini tidak dapat dibatalkan.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: NewsColors.subtitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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

  void _toggleBookmark() {
    setState(() => _bookmarked = !_bookmarked);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(_bookmarked ? 'Ditambahkan ke bookmark' : 'Bookmark dihapus'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post>(
      future: _postFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: NewsAppBar(
              title: 'Memuat artikel…',
              showBack: true,
              onBack: () => _close(false),
            ),
            body: const Center(
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
            appBar: NewsAppBar(
              title: 'Detail Artikel',
              showBack: true,
              onBack: () => _close(false),
            ),
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
            appBar: NewsAppBar(
              title: 'Detail Artikel',
              showBack: true,
              onBack: () => _close(false),
            ),
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
        final device = deviceForWidth(constraints.maxWidth);
        if (device == AppDevice.mobile) {
          return _buildMobileDetail(context, post);
        }
        return _buildWebDetail(
          context,
          post,
          isDesktop: device == AppDevice.desktop,
        );
      },
    );
  }

  // ───────────────────────── MOBILE (hero + kartu overlap) ─────────────────────────
  Widget _buildMobileDetail(BuildContext context, Post post) {
    const heroHeight = 400.0;
    const overlap = 28.0;

    final imageUrl = post.imageUrl;
    final meta = relativeTime(post.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      body: Stack(
        children: [
          // ── Hero image full-bleed ──
          SizedBox(
            height: heroHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FloatingCategoryBadge(label: post.categoryName),
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
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Konten scroll + kartu putih overlap ──
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: heroHeight - overlap,
              bottom: 24,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  overflow: TextOverflow.ellipsis,
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
                        padding: const EdgeInsets.only(bottom: 14),
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
                            label: const Text('Edit Artikel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
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
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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

          // ── Top bar melayang (PALING ATAS agar bisa diklik) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassCircleButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Kembali',
                  onTap: () => _close(false),
                ),
                const Spacer(),
                _GlassCircleButton(
                  icon: _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  tooltip: 'Bookmark',
                  onTap: _toggleBookmark,
                ),
                const SizedBox(width: 10),
                _GlassCircleButton(
                  icon: Icons.more_horiz,
                  tooltip: 'Opsi lainnya',
                  onTap: () => _showMore(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── TABLET & WEB (layout editorial 2 kolom) ───────────────
  Widget _buildWebDetail(
    BuildContext context,
    Post post, {
    required bool isDesktop,
  }) {
    final imageUrl = post.imageUrl;
    final date = formatPostDate(post.createdAt);
    final meta = relativeTime(post.createdAt);
    final readTime = _readTime(post.content);

    return Scaffold(
      backgroundColor: Colors.white,
      // App bar SAMA persis dengan halaman lain (konsisten mobile & web).
      appBar: NewsAppBar(
        title: 'Detail Artikel',
        showBack: true,
        onBack: () => _close(false),
        trailingActions: [
          CircleIconButton(
            icon: _bookmarked ? Icons.bookmark : Icons.bookmark_border,
            onTap: _toggleBookmark,
          ),
          CircleIconButton(
            icon: Icons.more_horiz,
            onTap: () => _showMore(post),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1080 : 720,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beranda / Artikel / ${post.categoryName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: NewsColors.subtitle,
                  ),
                ),
                const SizedBox(height: 14),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _WebArticleBody(
                          post: post,
                          imageUrl: imageUrl,
                          date: date,
                          meta: meta,
                          readTime: readTime,
                          onEdit: () => _openEdit(post),
                          onDelete: () => _confirmDelete(post),
                        ),
                      ),
                      const SizedBox(width: 32),
                      SizedBox(
                        width: 300,
                        child: _WebSidePanel(
                          post: post,
                          date: date,
                          meta: meta,
                          readTime: readTime,
                          bookmarked: _bookmarked,
                          onBookmark: _toggleBookmark,
                          onShare: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tautan artikel disalin'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                else
                  _WebArticleBody(
                    post: post,
                    imageUrl: imageUrl,
                    date: date,
                    meta: meta,
                    readTime: readTime,
                    onEdit: () => _openEdit(post),
                    onDelete: () => _confirmDelete(post),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _readTime(String content) {
    final words = content
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .length;
    final minutes = (words / 200).ceil().clamp(1, 999);
    return '$minutes mnt baca';
  }

  List<String> _paragraphs(String content) {
    final parts = content
        .split(RegExp(r'\n\s*\n|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return [content.trim().isEmpty ? '-' : content.trim()];
    }
    return parts;
  }
}

/// Kolom utama artikel untuk tablet/web.
class _WebArticleBody extends StatelessWidget {
  final Post post;
  final String? imageUrl;
  final String date;
  final String meta;
  final String readTime;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WebArticleBody({
    required this.post,
    required this.imageUrl,
    required this.date,
    required this.meta,
    required this.readTime,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final paragraphs = post.content
        .split(RegExp(r'\n\s*\n|\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FloatingCategoryBadge(label: post.categoryName),
            if (meta.isNotEmpty) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: NewsColors.subtitle,
                  ),
                ),
              ),
            ],
            const Spacer(),
            const Icon(
              Icons.schedule_outlined,
              size: 15,
              color: NewsColors.muted,
            ),
            const SizedBox(width: 5),
            Text(
              readTime,
              style: const TextStyle(
                fontSize: 13,
                color: NewsColors.subtitle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          post.title,
          style: const TextStyle(
            fontSize: 34,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: NewsColors.ink,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 16),
        // Baris penulis
        Row(
          children: [
            _SourceLogo(name: post.categoryName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          post.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  if (date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Diterbitkan $date',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: NewsColors.subtitle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (url != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFFF1F2F4),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: NewsColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, e, s) => Container(
                  color: const Color(0xFFE4E6EB),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: NewsColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 22),
        ...((paragraphs.isEmpty ? [post.content] : paragraphs).map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SelectableText(
              p,
              style: const TextStyle(
                fontSize: 16.5,
                height: 1.8,
                color: Color(0xFF2B2B2E),
              ),
            ),
          ),
        )),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Artikel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus Artikel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Panel samping khusus desktop: info + aksi.
class _WebSidePanel extends StatelessWidget {
  final Post post;
  final String date;
  final String meta;
  final String readTime;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onShare;

  const _WebSidePanel({
    required this.post,
    required this.date,
    required this.meta,
    required this.readTime,
    required this.bookmarked,
    required this.onBookmark,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kartu penulis
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F0F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ditulis oleh',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NewsColors.subtitle,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _SourceLogo(name: post.categoryName, big: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.categoryName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Kartu info artikel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F0F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Info artikel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NewsColors.subtitle,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.category_outlined,
                label: 'Kategori',
                value: post.categoryName,
              ),
              const SizedBox(height: 10),
              if (date.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Diterbitkan',
                    value: date,
                  ),
                ),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Waktu baca',
                value: readTime,
              ),
              if (meta.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _InfoRow(
                    icon: Icons.trending_up,
                    label: 'Aktivitas',
                    value: meta,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onBookmark,
          icon: Icon(
            bookmarked ? Icons.bookmark : Icons.bookmark_border,
            size: 18,
          ),
          label: Text(bookmarked ? 'Tersimpan' : 'Simpan artikel'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('Bagikan'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: NewsColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: NewsColors.subtitle,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: NewsColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;

  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
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
      ),
    );
  }
}

/// Logo sumber ala CNN (lingkaran merah + inisial putih).
class _SourceLogo extends StatelessWidget {
  final String name;
  final bool big;

  const _SourceLogo({required this.name, this.big = false});

  @override
  Widget build(BuildContext context) {
    final initials = initialFor(name);
    final short = initials.length >= 3 ? initials.substring(0, 3) : initials;
    final size = big ? 46.0 : 38.0;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFCC0000),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        short.isEmpty ? 'N' : short,
        style: TextStyle(
          color: Colors.white,
          fontSize: big ? 15 : 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
