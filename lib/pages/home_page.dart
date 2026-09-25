import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import 'add_post_page.dart';
import 'detail_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';

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

  String _snippet(String content, [int max = 100]) {
    final clean = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}....';
  }

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
        leading: IconButton(
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
        title: const Text(
          'NARATA',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        actions: [
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
          final bool useGrid = constraints.maxWidth >= 700;
          final double cap = isDesktop ? 1120 : double.infinity;
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

                            final bool wideHero =
                                constraints.maxWidth >= 900;
                            final List<Post> latest = filtered.length > 1
                                ? filtered.skip(1).take(4).toList()
                                : <Post>[];
                            final List<Post> rest = filtered.length >
                                    1 + latest.length
                                ? filtered
                                    .skip(1 + latest.length)
                                    .toList()
                                : <Post>[];
                            final Widget tabs = catSnapshot.connectionState ==
                                    ConnectionState.waiting
                                ? Text(
                                    'Memuat kategori…',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                  )
                                : _categoryTabs(context, categories);
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
                                const SizedBox(height: 20),
                                if (filtered.isEmpty)
                                  _emptyState(context)
                                else if (useGrid) ...[
                                  if (wideHero)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: _featuredCard(
                                            context,
                                            filtered.first,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 3,
                                          child: _latestList(
                                            context,
                                            latest,
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _featuredCard(
                                      context,
                                      filtered.first,
                                    ),
                                    if (latest.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _latestList(context, latest),
                                    ],
                                  ],
                                  const SizedBox(height: 20),
                                  tabs,
                                  if (rest.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Text(
                                      'Jelajahi Artikel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 19,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: rest.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            constraints.maxWidth >= 1050
                                                ? 3
                                                : 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.8,
                                      ),
                                      itemBuilder: (context, index) =>
                                          _gridCard(
                                        context,
                                        rest[index],
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  _featuredCard(context, filtered.first),
                                  const SizedBox(height: 20),
                                  tabs,
                                  const SizedBox(height: 8),
                                  if (filtered.length > 1)
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: filtered.length - 1,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) =>
                                          _rowCard(
                                        context,
                                        filtered[index + 1],
                                      ),
                                    ),
                                ],
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

  Widget _categoryTabs(BuildContext context, List<Category> categories) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget tab(String label, bool active, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(right: 20),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    active ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: active
                ? TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  )
                : TextStyle(color: colorScheme.outline),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          tab(
            'Semua',
            _selectedCategoryId == null,
            () => setState(() => _selectedCategoryId = null),
          ),
          ...categories.map(
            (category) => tab(
              category.name,
              _selectedCategoryId == category.id,
              () => setState(() => _selectedCategoryId = category.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverImage(String imageUrl, {double iconSize = 40}) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Icon(Icons.image_not_supported, size: iconSize),
          ),
        );
      },
    );
  }

  Widget _coverPlaceholder(BuildContext context,
      {IconData icon = Icons.article_outlined, double iconSize = 40}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(icon, size: iconSize, color: colorScheme.outline),
      ),
    );
  }

  Widget _dateText(BuildContext context, String date) {
    return Text(
      date,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }

  Widget _featuredCard(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 600;
    final imageUrl = post.imageUrl;
    final date = _formatDate(post.createdAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openDetail(post),
        child: SizedBox(
          height: isDesktop ? 280 : 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                _coverImage(imageUrl, iconSize: 44)
              else
                _coverPlaceholder(context, iconSize: 48),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    post.categoryName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xB3000000),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _snippet(post.content, 90),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
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
    );
  }

  Widget _gridCard(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrl;
    final date = _formatDate(post.createdAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _openDetail(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: imageUrl != null
                  ? _coverImage(imageUrl, iconSize: 44)
                  : _coverPlaceholder(context, iconSize: 44),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _snippet(post.content),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                    const Spacer(),
                    if (date.isNotEmpty) _dateText(context, date),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _latestList(BuildContext context, List<Post> latest) {
    if (latest.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artikel Terbaru',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latest.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _latestRow(context, latest[index]),
        ),
      ],
    );
  }

  Widget _latestRow(BuildContext context, Post post) {
    final imageUrl = post.imageUrl;
    final date = _formatDate(post.createdAt);
    return InkWell(
      onTap: () => _openDetail(post),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: imageUrl != null
                  ? _coverImage(imageUrl, iconSize: 20)
                  : _coverPlaceholder(context, iconSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                if (date.isNotEmpty) _dateText(context, date),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowCard(BuildContext context, Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrl;
    final date = _formatDate(post.createdAt);
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _openDetail(post),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 120,
                  child: imageUrl != null
                      ? _coverImage(imageUrl)
                      : _coverPlaceholder(
                          context,
                          icon: Icons.image_not_supported,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post.categoryName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (date.isNotEmpty)
                          _dateText(context, date),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _snippet(post.content, 80),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
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
              ),
            ],
          ),
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
