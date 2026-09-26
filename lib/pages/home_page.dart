import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/news_theme.dart';
import '../widgets/news_widgets.dart';
import 'detail_page.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  final int refreshSignal;
  final ValueChanged<int>? onOpenDetail;
  final VoidCallback? onViewAll;
  final VoidCallback? onSearchTap;
  final ApiService? apiService;

  const HomePage({
    super.key,
    this.refreshSignal = 0,
    this.onOpenDetail,
    this.onViewAll,
    this.onSearchTap,
    this.apiService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiService apiService = widget.apiService ?? ApiService();

  late Future<List<Post>> _postsFuture;
  late Future<List<Category>> _categoriesFuture;

  int? _selectedCategoryId;
  int _lastSignal = 0;
  int _carouselIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _lastSignal = widget.refreshSignal;
    _startRequests();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal != _lastSignal) {
      _lastSignal = widget.refreshSignal;
      _load();
    }
  }

  void _startRequests() {
    _postsFuture = apiService.getPosts();
    _categoriesFuture = apiService.getCategories();
  }

  void _load() {
    setState(() {
      _startRequests();
      _carouselIndex = 0;
    });
  }

  Future<void> _refresh() async {
    _load();
    try {
      await Future.wait([_postsFuture, _categoriesFuture]);
    } catch (_) {}
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

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
  }

  List<Post> _filterByCategory(List<Post> posts) {
    if (_selectedCategoryId == null) return posts;
    return posts.where((p) => p.categoryId == _selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // App bar konsisten di semua halaman (kecuali Articles).
      appBar: NewsAppBar(
        onSearch: widget.onSearchTap ?? widget.onViewAll,
        onNotification: _openNotifications,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final device = deviceForWidth(maxW);
          final contentMax = contentMaxWidth(maxW, desktop: 1150);
          final isDesktop = device == AppDevice.desktop;
          final isTablet = device == AppDevice.tablet;

          final horizontalPad = device == AppDevice.mobile ? 20.0 : 24.0;
          final carouselHeight = device == AppDevice.mobile
              ? 210.0
              : isTablet
                  ? 280.0
                  : 320.0;

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
                        const SizedBox(height: 6),
                        // Sapaan (dipertahankan untuk kompatibilitas + aksesibilitas)
                        const Text(
                          'Selamat datang di NARATA',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: NewsColors.subtitle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SectionHeader(
                          title: 'Breaking News',
                          onViewAll: widget.onViewAll,
                        ),
                        const SizedBox(height: 14),
                        FutureBuilder<List<Post>>(
                          future: _postsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox(
                                height: carouselHeight,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: NewsColors.primary,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return _PostLoadError(onRetry: _load);
                            }
                            final all = _filterByCategory(
                              snapshot.data ?? const [],
                            );
                            if (all.isEmpty) {
                              return _EmptyState(
                                hasFilter: _selectedCategoryId != null,
                                compact: true,
                              );
                            }
                            final breaking = all.take(5).toList();
                            if (isDesktop) {
                              return _BreakingGrid(
                                posts: breaking,
                                onTap: _openDetail,
                              );
                            }
                            return Column(
                              children: [
                                _BreakingCarousel(
                                  posts: breaking,
                                  height: carouselHeight,
                                  index: _carouselIndex,
                                  onChanged: (i) => setState(
                                    () => _carouselIndex = i,
                                  ),
                                  onTap: _openDetail,
                                  viewportFraction:
                                      device == AppDevice.mobile ? 1.0 : 0.82,
                                ),
                                const SizedBox(height: 12),
                                CarouselDots(
                                  count: breaking.length,
                                  active: _carouselIndex.clamp(
                                    0,
                                    breaking.length - 1,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // ── Filter kategori (styled pills, tetap "Kategori tidak dapat dimuat" saat error) ──
                        FutureBuilder<List<Category>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Memuat kategori…',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: NewsColors.subtitle,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Kategori tidak dapat dimuat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: NewsColors.subtitle,
                                  ),
                                ),
                              );
                            }
                            final cats = snapshot.data ?? const [];
                            if (cats.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 4),
                              child: CategoryPills(
                                items: [
                                  (id: null, label: 'Semua'),
                                  for (final c in cats)
                                    (id: c.id, label: c.name),
                                ],
                                selectedId: _selectedCategoryId,
                                onSelected: (id) => setState(() {
                                  _selectedCategoryId = id;
                                  _carouselIndex = 0;
                                }),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        SectionHeader(
                          title: 'Recommendation',
                          onViewAll: widget.onViewAll,
                        ),
                        const SizedBox(height: 6),
                        FutureBuilder<List<Post>>(
                          future: _postsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: NewsColors.primary,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              // Pesan ringkas; error utama sudah tampil di Breaking.
                              // Tetap tampilkan agar konsisten saat list kosong.
                              return const SizedBox.shrink();
                            }
                            final posts = _filterByCategory(
                              snapshot.data ?? const [],
                            );
                            if (posts.isEmpty) {
                              return _EmptyState(
                                hasFilter: _selectedCategoryId != null,
                              );
                            }
                            if (device == AppDevice.mobile) {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: posts.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(
                                  height: 1,
                                  thickness: 0.6,
                                  color: Color(0xFFF0F0F2),
                                  indent: 110,
                                ),
                                itemBuilder: (context, i) => NewsListTile(
                                  post: posts[i],
                                  onTap: () => _openDetail(posts[i]),
                                ),
                              );
                            }
                            // Tinggi sel TETAP (bukan childAspectRatio) agar tidak
                            // overflow saat lebar layar digeser/di-resize.
                            return GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 4,
                                mainAxisExtent: 118,
                              ),
                              itemBuilder: (context, i) => NewsListTile(
                                post: posts[i],
                                onTap: () => _openDetail(posts[i]),
                                thumbnailSize: 92,
                              ),
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

class _BreakingCarousel extends StatefulWidget {
  final List<Post> posts;
  final double height;
  final int index;
  final ValueChanged<int> onChanged;
  final ValueChanged<Post> onTap;
  final double viewportFraction;

  const _BreakingCarousel({
    required this.posts,
    required this.height,
    required this.index,
    required this.onChanged,
    required this.onTap,
    this.viewportFraction = 1.0,
  });

  @override
  State<_BreakingCarousel> createState() => _BreakingCarouselState();
}

class _BreakingCarouselState extends State<_BreakingCarousel> {
  // NB: tidak boleh `final` — controller dibuat ulang saat
  // viewportFraction berubah (mis. resize mobile <-> tablet).
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void didUpdateWidget(_BreakingCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportFraction != widget.viewportFraction) {
      _controller.dispose();
      _controller =
          PageController(viewportFraction: widget.viewportFraction);
    }
    if (oldWidget.posts.length != widget.posts.length) {
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.posts.length,
        onPageChanged: widget.onChanged,
        itemBuilder: (context, i) {
          final pad = widget.viewportFraction < 1.0
              ? const EdgeInsets.symmetric(horizontal: 6)
              : EdgeInsets.zero;
          return Padding(
            padding: pad,
            child: BreakingNewsCard(
              post: widget.posts[i],
              height: widget.height,
              onTap: () => widget.onTap(widget.posts[i]),
            ),
          );
        },
      ),
    );
  }
}

class _BreakingGrid extends StatelessWidget {
  final List<Post> posts;
  final ValueChanged<Post> onTap;

  const _BreakingGrid({required this.posts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final show = posts.take(3).toList();
    // Tinggi sel tetap 224 (kartu 220) agar aman di semua lebar desktop.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: show.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: show.length >= 3 ? 3 : show.length,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 224,
      ),
      itemBuilder: (context, i) => BreakingNewsCard(
        post: show[i],
        height: 220,
        onTap: () => onTap(show[i]),
      ),
    );
  }
}

class _PostLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _PostLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Gagal memuat artikel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pastikan backend NARATA sedang berjalan.',
            style: TextStyle(fontSize: 12, color: NewsColors.subtitle),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final bool compact;

  const _EmptyState({required this.hasFilter, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 24 : 40),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.article_outlined,
              size: 44,
              color: NewsColors.muted,
            ),
            const SizedBox(height: 10),
            Text(
              hasFilter
                  ? 'Tidak ada artikel pada kategori ini'
                  : 'Belum ada artikel',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih kategori lain atau tambahkan artikel.',
              style: TextStyle(fontSize: 12, color: NewsColors.subtitle),
            ),
          ],
        ),
      ),
    );
  }
}
