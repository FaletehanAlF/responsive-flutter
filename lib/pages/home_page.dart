import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import 'add_post_page.dart';
import 'detail_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';

/// Halaman utama NARATA: sambutan, ringkasan, filter kategori,
/// dan daftar artikel terbaru.
class HomePage extends StatefulWidget {
  final int refreshSignal;

  const HomePage({super.key, this.refreshSignal = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();

  late Future<List<Post>> _postsFuture;
  late Future<List<Category>> _categoriesFuture;

  int? _selectedCategoryId;
  int _lastSignal = 0;

  @override
  void initState() {
    super.initState();
    _lastSignal = widget.refreshSignal;
    _load();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal != _lastSignal) {
      _lastSignal = widget.refreshSignal;
      _load();
    }
  }

  void _load() {
    setState(() {
      _postsFuture = apiService.getPosts();
      _categoriesFuture = apiService.getCategories();
    });
  }

  String _snippet(String content) {
    final clean = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= 100) return clean;
    return '${clean.substring(0, 100)}…';
  }

  String _formatDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.contains('T')) return value.split('T').first;
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  Future<void> _openDetail(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailPage(postId: post.id)),
    );
    if (!mounted) return;
    if (result == true) _load();
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPostPage()),
    );
    if (!mounted) return;
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'NARATA',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          final double cap = isDesktop ? 1000 : double.infinity;
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cap),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FutureBuilder<List<Post>>(
                      future: _postsFuture,
                      builder: (context, postSnapshot) {
                        if (postSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 64),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (postSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    size: 48,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Gagal memuat artikel',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _load,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final posts = postSnapshot.data ?? [];
                        return FutureBuilder<List<Category>>(
                          future: _categoriesFuture,
                          builder: (context, catSnapshot) {
                            final categories = catSnapshot.data ?? [];
                            final filtered = _selectedCategoryId == null
                                ? posts
                                : posts
                                    .where(
                                      (post) =>
                                          post.categoryId ==
                                          _selectedCategoryId,
                                    )
                                    .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat datang di NARATA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kelola dan temukan artikel dengan mudah.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _statCard(
                                        context,
                                        icon: Icons.article_outlined,
                                        value: '${posts.length}',
                                        label: 'Total Artikel',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _statCard(
                                        context,
                                        icon: Icons.category_outlined,
                                        value: '${categories.length}',
                                        label: 'Total Kategori',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Artikel Terbaru',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 19,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Artikel yang baru ditambahkan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                if (catSnapshot.connectionState ==
                                    ConnectionState.waiting)
                                  Text(
                                    'Memuat kategori…',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                  )
                                else
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        ChoiceChip(
                                          label: const Text('Semua'),
                                          selected:
                                              _selectedCategoryId == null,
                                          onSelected: (_) {
                                            setState(
                                              () =>
                                                  _selectedCategoryId = null,
                                            );
                                          },
                                        ),
                                        ...categories.map(
                                          (category) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: ChoiceChip(
                                              label: Text(category.name),
                                              selected: _selectedCategoryId ==
                                                  category.id,
                                              onSelected: (_) {
                                                setState(() {
                                                  _selectedCategoryId =
                                                      category.id;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                if (filtered.isEmpty)
                                  _emptyState(context)
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) =>
                                        _articleCard(
                                      context,
                                      filtered[index],
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sampul gambar card artikel.
  /// Desktop dibatasi tingginya (280px) agar proporsional dan tidak
  /// mendominasi viewport; mobile tetap 16:9 mengikuti lebar layar.
  /// BoxFit.cover menjaga gambar memenuhi area tanpa distorsi.
  Widget _cardCover(BuildContext context, String imageUrl) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 600;
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
            child: Icon(Icons.image_not_supported, size: 40),
          ),
        );
      },
    );
    if (isDesktop) {
      return SizedBox(
        height: 280,
        width: double.infinity,
        child: image,
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: image,
    );
  }

  Widget _articleCard(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrl;
    final date = _formatDate(post.createdAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () => _openDetail(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) _cardCover(context, imageUrl),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.categoryName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _snippet(post.content),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (date.isNotEmpty) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool filtered = _selectedCategoryId != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.article_outlined,
                size: 44,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada artikel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? 'Belum ada artikel pada kategori ini.'
                  : 'Tambahkan artikel pertama untuk mulai mengisi NARATA.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
            if (!filtered) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openAdd,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Artikel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
