import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/category_badge.dart';
import '../widgets/narata_app_bar.dart';
import 'detail_page.dart';

class ArticlesPage extends StatefulWidget {
  final int refreshSignal;
  final ValueChanged<int>? onOpenDetail;

  const ArticlesPage({super.key, this.refreshSignal = 0, this.onOpenDetail});

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
    await Future.wait([_postsFuture, _categoriesFuture]);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const NarataAppBar(title: Text('Semua Artikel')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool useGrid = constraints.maxWidth >= 1100;
          final bool isDesktop = constraints.maxWidth >= 600;
          final double cap = useGrid ? 1100 : (isDesktop ? 760 : double.infinity);

          return RefreshIndicator(
            onRefresh: _refresh,
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
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colorScheme.outline),
                        ),
                        const SizedBox(height: 16),
                        _buildSearchField(context, colorScheme),
                        const SizedBox(height: 12),
                        FutureBuilder<List<Category>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const SizedBox.shrink();
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (useGrid)
                                  GridView.builder(
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
                                    itemBuilder: (context, index) => _gridCard(
                                      context,
                                      filtered[index],
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) => _listCard(
                                      context,
                                      filtered[index],
                                      maxImageHeight: isDesktop ? 280 : null,
                                    ),
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

  Widget _buildSearchField(BuildContext context, ColorScheme colorScheme) {
    return TextField(
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
    );
  }

  Widget _cardShell(Post post, Widget child) {
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

  Widget _coverImage(
    BuildContext context,
    String imageUrl, {
    double? height,
  }) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.network(
        imageUrl,
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
      ),
    );
  }

  Widget _metaRow(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = formatPostDate(post.createdAt);
    return Row(
      children: [
        if (date.isNotEmpty) ...[
          Icon(Icons.calendar_today, size: 13, color: colorScheme.outline),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              date,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.outline),
            ),
          ),
        ] else
          const Spacer(),
        Icon(Icons.arrow_forward, size: 18, color: colorScheme.primary),
      ],
    );
  }

  Widget _listCard(BuildContext context, Post post, {double? maxImageHeight}) {
    final imageUrl = post.imageUrl;
    return _cardShell(
      post,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            _coverImage(context, imageUrl, height: maxImageHeight),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryBadge(label: post.categoryName),
                const SizedBox(height: 6),
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  post.snippet,
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
    final imageUrl = post.imageUrl;
    return _cardShell(
      post,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null) _coverImage(context, imageUrl, height: 150),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
                  Text(
                    post.snippet,
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
    if (categories.isEmpty && selectedId == null) {
      return const SizedBox.shrink();
    }

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
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
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
  final bool isSearching;

  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                isSearching ? Icons.search_off : Icons.article_outlined,
                size: 44,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Artikel tidak ditemukan' : 'Belum ada artikel',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Ubah kata kunci atau filter kategori.'
                  : 'Tambahkan artikel pertama untuk mulai mengisi NARATA.',
              textAlign: TextAlign.center,
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
