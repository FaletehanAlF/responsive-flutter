import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
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

  String _date(String raw) {
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
          final bool desktop = constraints.maxWidth >= 600;
          final bool grid = constraints.maxWidth >= 900;
          return RefreshIndicator(
            onRefresh: () async => _load(),
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
                          final categories = snapshot.data ?? [];
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Semua'),
                                  selected: _selectedCategoryId == null,
                                  onSelected: (_) => setState(
                                    () => _selectedCategoryId = null,
                                  ),
                                ),
                                ...categories.map(
                                  (category) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text(category.name),
                                      selected: _selectedCategoryId ==
                                          category.id,
                                      onSelected: (_) => setState(
                                        () => _selectedCategoryId =
                                            category.id,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Column(
                                  children: [
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
                                    OutlinedButton(
                                      onPressed: _load,
                                      child: const Text('Coba Lagi'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final data = snapshot.data ?? [];
                          final posts = _selectedCategoryId == null
                              ? data
                              : data
                                  .where(
                                    (post) =>
                                        post.categoryId ==
                                        _selectedCategoryId,
                                  )
                                  .toList();
                          if (posts.isEmpty) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.article_outlined,
                                      size: 48,
                                      color: colorScheme.outline,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Belum ada artikel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tambahkan artikel pertama.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (grid) {
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
                              itemBuilder: (context, index) =>
                                  _card(context, posts[index], null),
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
                              desktop ? 300 : null,
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

  Widget _card(BuildContext context, Post post, double? maxImageHeight) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = post.imageUrl;
    final date = _date(post.createdAt);

    Widget cover = AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        imageUrl ?? '',
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
      ),
    );
    if (maxImageHeight != null) {
      cover = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxImageHeight),
        child: cover,
      );
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
          children: [
            cover?,
            Padding(
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
            ),
          ],
        ),
      ),
    );
  }
}
