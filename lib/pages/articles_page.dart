import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import 'detail_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';

/// Halaman pengelolaan semua artikel: pencarian, filter kategori,
/// daftar 1 kolom di mobile dan grid 2 kolom di layar lebar.
class ArticlesPage extends StatefulWidget {
  final int refreshSignal;

  const ArticlesPage({super.key, this.refreshSignal = 0});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  final ApiService apiService = ApiService();
  final TextEditingController searchController = TextEditingController();

  late Future<List<Post>> _postsFuture;
  late Future<List<Category>> _categoriesFuture;

  String _keyword = '';
  int? _selectedCategoryId;
  int _lastSignal = 0;

  @override
  void initState() {
    super.initState();
    _lastSignal = widget.refreshSignal;
    _load();
    searchController.addListener(() {
      setState(() {
        _keyword = searchController.text;
      });
    });
  }

  @override
  void didUpdateWidget(ArticlesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal != _lastSignal) {
      _lastSignal = widget.refreshSignal;
      _load();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _postsFuture = apiService.getPosts();
      _categoriesFuture = apiService.getCategories();
    });
  }

  List<Post> _applyFilter(List<Post> data) {
    final query = _keyword.trim().toLowerCase();
    return data.where((post) {
      final matchCategory =
          _selectedCategoryId == null || post.categoryId == _selectedCategoryId;
      if (!matchCategory) return false;
      if (query.isEmpty) return true;
      return post.title.toLowerCase().contains(query) ||
          post.content.toLowerCase().contains(query);
    }).toList();
  }

  String _snippet(String content) {
    final clean = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= 110) return clean;
    return '${clean.substring(0, 110)}…';
  }

  /// Format tanggal via package intl (locale Indonesia),
  /// contoh: "25 Sep 2026". Kembalikan mentah bila tak ter-parse.
  String _formatDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('d MMM yyyy', 'id').format(parsed);
  }

  Future<void> _openDetail(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailPage(postId: post.id)),
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
        title: const Text('Semua Artikel'),
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
          final bool wideGrid = constraints.maxWidth >= 1100;
          final bool isDesktop = constraints.maxWidth >= 600;
          final double cap = wideGrid ? 1120 : (isDesktop ? 760 : double.infinity);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semua Artikel',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola seluruh artikel yang tersimpan.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Cari judul atau isi artikel…',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerLow,
                            suffixIcon: _keyword.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Bersihkan',
                                    icon: const Icon(Icons.clear),
                                    onPressed: searchController.clear,
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<Category>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            final data = snapshot.data ?? [];
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('Semua'),
                                    selected: _selectedCategoryId == null,
                                    onSelected: (_) {
                                      setState(
                                        () => _selectedCategoryId = null,
                                      );
                                    },
                                  ),
                                  ...data.map(
                                    (category) => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: ChoiceChip(
                                        label: Text(category.name),
                                        selected: _selectedCategoryId ==
                                            category.id,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedCategoryId = category.id;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Post>>(
                          future: _postsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 64),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
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

                            final filtered =
                                _applyFilter(snapshot.data ?? []);
                            if (filtered.isEmpty) {
                              return _emptyState(context);
                            }

                            if (wideGrid) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.05,
                                ),
                                itemBuilder: (context, index) =>
                                    _gridCard(context, filtered[index]),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _listCard(context, filtered[index]),
                            );
                          },
                        ),
                      ],
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

  Widget _cardShell(BuildContext context, Post post, Widget child) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () => _openDetail(post),
        child: child,
      ),
    );
  }

  Widget _coverImage(BuildContext context, String imageUrl,
      {double? maxHeight}) {
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
    // Desktop: batasi tinggi agar gambar tidak mendominasi viewport.
    // Mobile (maxHeight null): pertahankan 16:9 mengikuti lebar layar.
    if (maxHeight != null) {
      return SizedBox(
        height: maxHeight,
        width: double.infinity,
        child: image,
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: image,
    );
  }

  Widget _metaRow(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = _formatDate(post.createdAt);
    return Row(
      children: [
        if (date.isNotEmpty) ...[
          Icon(Icons.calendar_today, size: 13, color: colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            date,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
          ),
        ],
        const Spacer(),
        Icon(Icons.arrow_forward, size: 18, color: colorScheme.primary),
      ],
    );
  }

  Widget _listCard(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrl;
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 600;
    return _cardShell(
      context,
      post,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            _coverImage(
              context,
              imageUrl,
              maxHeight: isDesktop ? 280 : null,
            ),
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
                _metaRow(context, post),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridCard(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrl;
    return _cardShell(
      context,
      post,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null) _coverImage(context, imageUrl),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 4),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _snippet(post.content),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  _metaRow(context, post),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool searching = _keyword.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
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
                searching ? Icons.search_off : Icons.article_outlined,
                size: 44,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searching ? 'Artikel tidak ditemukan' : 'Belum ada artikel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Ubah kata kunci atau filter kategori.'
                  : 'Tambahkan artikel pertama untuk mulai mengisi NARATA.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
