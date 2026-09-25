import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/category_badge.dart';
import '../widgets/narata_app_bar.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  final int refreshSignal;
  final ValueChanged<int>? onOpenDetail;

  const HomePage({super.key, this.refreshSignal = 0, this.onOpenDetail});

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
    _startRequests();
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
    setState(_startRequests);
  }

  Future<void> _refresh() async {
    _load();
    await Future.wait([_postsFuture, _categoriesFuture]);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const NarataAppBar(
        title: Text(
          'NARATA',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool desktop = constraints.maxWidth >= 600;
          final bool useGrid = constraints.maxWidth >= 900;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 24 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktop ? 1100 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang di NARATA',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Baca dan kelola artikel terbaru.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Category>>(
                        future: _categoriesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              'Memuat kategori…',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colorScheme.outline),
                            );
                          }
                          if (snapshot.hasError) {
                            return _CategoryFilterError(
                              onRetry: _load,
                            );
                          }
                          return _CategoryFilterRow(
                            categories: snapshot.data ?? const [],
                            selectedId: _selectedCategoryId,
                            onSelected: (id) {
                              setState(() => _selectedCategoryId = id);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Artikel Terbaru',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 19,
                                ),
                      ),
                      const SizedBox(height: 12),
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
                            return _PostLoadError(onRetry: _load);
                          }

                          final posts = _filterByCategory(
                            snapshot.data ?? const [],
                          );
                          if (posts.isEmpty) {
                            return _EmptyState(
                              hasCategoryFilter:
                                  _selectedCategoryId != null,
                            );
                          }

                          if (useGrid) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                              itemBuilder: (context, index) => _card(
                                context,
                                posts[index],
                                fixedImageHeight: 150,
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: posts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) => _card(
                              context,
                              posts[index],
                              maxImageHeight: desktop ? 300 : null,
                            ),
                          );
                        },
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
  }

  List<Post> _filterByCategory(List<Post> posts) {
    if (_selectedCategoryId == null) return posts;
    return posts
        .where((post) => post.categoryId == _selectedCategoryId)
        .toList();
  }

  Widget _card(
    BuildContext context,
    Post post, {
    double? maxImageHeight,
    double? fixedImageHeight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrl;
    final date = formatPostDate(post.createdAt);
    final isGrid = fixedImageHeight != null;

    final cover = _buildCover(
      context,
      imageUrl,
      colorScheme,
      fixedHeight: fixedImageHeight,
      maxHeight: maxImageHeight,
    );

    Widget body = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isGrid ? MainAxisSize.max : MainAxisSize.min,
        children: [
          CategoryBadge(label: post.categoryName),
          const SizedBox(height: 4),
          Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 13,
                color: colorScheme.outline,
              ),
              const SizedBox(width: 4),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              const Spacer(),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );

    if (isGrid) {
      body = Expanded(child: body);
    }

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
          mainAxisSize: isGrid ? MainAxisSize.max : MainAxisSize.min,
          children: [
            ?cover,
            body,
          ],
        ),
      ),
    );
  }

  Widget? _buildCover(
    BuildContext context,
    String? imageUrl,
    ColorScheme colorScheme, {
    double? fixedHeight,
    double? maxHeight,
  }) {
    if (imageUrl == null) return null;

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
          color: colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 40),
          ),
        );
      },
    );

    if (fixedHeight != null) {
      return SizedBox(height: fixedHeight, child: image);
    }
    if (maxHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: image,
      );
    }
    return image;
  }
}

class _CategoryFilterRow extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const _CategoryFilterRow({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Semua'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(category.name),
                selected: selectedId == category.id,
                onSelected: (_) => onSelected(category.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryFilterError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CategoryFilterError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 18, color: colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Gagal memuat kategori',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.outline),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    );
  }
}

class _PostLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _PostLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Text(
              'Gagal memuat artikel',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Pastikan backend NARATA sedang berjalan.',
              style: Theme.of(context).textTheme.bodySmall,
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
  final bool hasCategoryFilter;

  const _EmptyState({required this.hasCategoryFilter});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.article_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              hasCategoryFilter
                  ? 'Tidak ada artikel pada kategori ini'
                  : 'Belum ada artikel',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              hasCategoryFilter
                  ? 'Pilih kategori lain untuk melihat artikel.'
                  : 'Tambahkan artikel pertama.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
