import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/news_theme.dart';
import '../widgets/news_widgets.dart';
import 'detail_page.dart';

class ArticlesPage extends StatefulWidget {
  final int refreshSignal;
  final ValueChanged<int>? onOpenDetail;
  final ApiService? apiService;

  const ArticlesPage({
    super.key,
    this.refreshSignal = 0,
    this.onOpenDetail,
    this.apiService,
  });

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  final TextEditingController searchController = TextEditingController();

  late final ApiService apiService = widget.apiService ?? ApiService();

  late Future<List<Post>> _postsFuture;
  late Future<List<Category>> _categoriesFuture;

  String _keyword = '';
  int? _selectedCategoryId;
  int _lastSignal = 0;

  @override
  void initState() {
    super.initState();
    _lastSignal = widget.refreshSignal;
    _startRequests();
    searchController.addListener(_onSearchChanged);
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
    searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _startRequests() {
    _postsFuture = apiService.getPosts();
    _categoriesFuture = apiService.getCategories();
  }

  void _load() {
    setState(_startRequests);
  }

  Future<void> _refresh() async {
    _load();
    try {
      await Future.wait([_postsFuture, _categoriesFuture]);
    } catch (_) {}
  }

  void _onSearchChanged() {
    if (_keyword == searchController.text) return;
    setState(() => _keyword = searchController.text);
  }

  List<Post> _applyFilter(List<Post> data) {
    final query = _keyword.trim().toLowerCase();
    return data.where((post) {
      if (_selectedCategoryId != null &&
          post.categoryId != _selectedCategoryId) {
        return false;
      }
      if (query.isEmpty) return true;
      return post.title.toLowerCase().contains(query) ||
          post.content.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openDetail(Post post) async {
    final onOpenDetail = widget.onOpenDetail;
    if (onOpenDetail != null) {
      onOpenDetail(post.id);
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailPage(postId: post.id)),
    );
    if (!mounted) return;
    if (result == true) _load();
  }

  void _onFilterTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter lanjutan segera hadir'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final device = deviceForWidth(maxW);
          final contentMax = contentMaxWidth(maxW, desktop: 1100);
          final canPop = Navigator.of(context).canPop();

          final horizontalPad = device == AppDevice.mobile ? 20.0 : 24.0;

          return RefreshIndicator(
            color: NewsColors.primary,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: contentMax == double.infinity
                        ? double.infinity
                        : contentMax,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      8,
                      horizontalPad,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).padding.top + 8,
                        ),
                        // ── Top row: back (jika bisa) ──
                        if (canPop)
                          CircleIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          )
                        else
                          const SizedBox(height: 44 - 8),
                        const SizedBox(height: 12),
                        // Label kompatibilitas + judul Discover
                        const Text(
                          'Semua Artikel',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: NewsColors.subtitle,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: NewsColors.ink,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'News from all around the world',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: NewsColors.subtitle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DiscoverSearchBar(
                          controller: searchController,
                          onFilterTap: _onFilterTap,
                        ),
                        const SizedBox(height: 14),
                        FutureBuilder<List<Category>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const SizedBox.shrink();
                            }
                            final cats =
                                snapshot.data ?? const <Category>[];
                            return CategoryPills(
                              items: [
                                (id: null, label: 'All'),
                                for (final c in cats)
                                  (id: c.id, label: c.name),
                              ],
                              selectedId: _selectedCategoryId,
                              onSelected: (id) => setState(
                                () => _selectedCategoryId = id,
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
                                  child: CircularProgressIndicator(
                                    color: NewsColors.primary,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return _LoadError(
                                message: 'Gagal memuat artikel',
                                detail:
                                    'Pastikan backend NARATA sedang berjalan.',
                                onRetry: _load,
                              );
                            }

                            final filtered = _applyFilter(
                              snapshot.data ?? const [],
                            );
                            if (filtered.isEmpty) {
                              return _EmptyState(
                                isSearching:
                                    _keyword.trim().isNotEmpty ||
                                        _selectedCategoryId != null,
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${filtered.length} artikel ditemukan',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: NewsColors.subtitle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (device == AppDevice.mobile)
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(
                                      height: 1,
                                      thickness: 0.6,
                                      color: Color(0xFFF0F0F2),
                                      indent: 112,
                                    ),
                                    itemBuilder: (context, i) {
                                      final post = filtered[i];
                                      return _DiscoverTile(
                                        post: post,
                                        onTap: () => _openDetail(post),
                                      );
                                    },
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 4,
                                      // Tinggi tetap (thumbnail 96 + padding 16
                                      // + toleransi) — anti overflow saat resize.
                                      mainAxisExtent: 122,
                                    ),
                                    itemBuilder: (context, i) {
                                      final post = filtered[i];
                                      return _DiscoverTile(
                                        post: post,
                                        onTap: () => _openDetail(post),
                                      );
                                    },
                                  ),
                              ],
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
}

/// Tile Discover: kategori kecil → judul → author • tanggal (thumbnail kiri).
class _DiscoverTile extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const _DiscoverTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NewsListTile(post: post, onTap: onTap, thumbnailSize: 96);
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _LoadError({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: NewsColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: NewsColors.subtitle,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;

  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F2F4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.article_outlined,
                size: 44,
                color: NewsColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Artikel tidak ditemukan' : 'Belum ada artikel',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Ubah kata kunci atau filter kategori.'
                  : 'Tambahkan artikel pertama untuk mulai mengisi NARATA.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: NewsColors.subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
