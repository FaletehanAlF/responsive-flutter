import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/api_service.dart';
import '../utils/news_theme.dart';
import '../widgets/news_widgets.dart';

class CategoryPage extends StatefulWidget {
  final ApiService? apiService;

  const CategoryPage({super.key, this.apiService});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final ApiService apiService = widget.apiService ?? ApiService();

  late Future<({List<Category> categories, Map<int, int> counts})> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<({List<Category> categories, Map<int, int> counts})> _fetchData() async {
    final categories = await apiService.getCategories();

    final counts = <int, int>{};
    try {
      final posts = await apiService.getPosts();
      for (final post in posts) {
        counts[post.categoryId] = (counts[post.categoryId] ?? 0) + 1;
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Hitungan artikel bersifat tambahan, kegagalan tidak menghalangi daftar.
    }

    return (categories: categories, counts: counts);
  }

  void _load() {
    final next = _fetchData();
    setState(() {
      _dataFuture = next;
    });
  }

  Future<void> _refresh() async {
    _load();
    try {
      await _dataFuture;
    } catch (_) {}
  }

  Future<void> _showCategoryDialog({Category? existing}) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _CategoryNameDialog(category: existing),
    );

    if (name == null || !mounted) return;

    final trimmed = name.trim();
    try {
      if (existing == null) {
        await apiService.addCategory(trimmed);
        if (!mounted) return;
        _showMessage('Kategori berhasil ditambahkan');
      } else {
        await apiService.updateCategory(existing.id, trimmed);
        if (!mounted) return;
        _showMessage('Kategori berhasil diubah');
      }
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menyimpan kategori: $e');
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Hapus kategori?'),
          content: Text(
            'Kategori "${category.name}" akan dihapus dari daftar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
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
      await apiService.deleteCategory(category.id);
      if (!mounted) return;
      _load();
      _showMessage('Kategori berhasil dihapus');
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menghapus kategori: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: const NewsAppBar(title: 'Kategori', showBack: true),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Kategori',
        backgroundColor: NewsColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final device = deviceForWidth(constraints.maxWidth);
          final contentMax =
              device == AppDevice.mobile ? double.infinity : 720.0;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: NewsColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kelompokkan artikel agar mudah ditemukan.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: NewsColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<
                          ({List<Category> categories, Map<int, int> counts})>(
                        future: _dataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: NewsColors.primary,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEDEDEF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_off_outlined,
                                      size: 44,
                                      color: NewsColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Gagal memuat kategori',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: NewsColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: NewsColors.subtitle,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: _load,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final categories =
                              snapshot.data?.categories ?? const [];
                          final counts = snapshot.data?.counts ?? const {};

                          if (categories.isEmpty) {
                            return _EmptyCategories(
                              onAdd: () => _showCategoryDialog(),
                            );
                          }

                          final totalArticles = counts.values.fold<int>(
                            0,
                            (sum, v) => sum + v,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ringkasan alur: total kategori & artikel.
                              _SummaryStripe(
                                totalCategories: categories.length,
                                totalArticles: totalArticles,
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: RefreshIndicator(
                                  color: NewsColors.primary,
                                  onRefresh: _refresh,
                                  child: ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: categories.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      return _CategoryCard(
                                        category: category,
                                        count:
                                            counts[category.id] ?? 0,
                                        onEdit: () => _showCategoryDialog(
                                          existing: category,
                                        ),
                                        onDelete: () =>
                                            _confirmDelete(category),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Strip ringkasan: berapa kategori & artikel — memperjelas alur kelola.
class _SummaryStripe extends StatelessWidget {
  final int totalCategories;
  final int totalArticles;

  const _SummaryStripe({
    required this.totalCategories,
    required this.totalArticles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: NewsColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.dashboard_outlined,
            size: 20,
            color: NewsColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$totalCategories kategori • $totalArticles artikel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: NewsColors.primary,
              ),
            ),
          ),
          const Text(
            'Geser ke bawah untuk memuat ulang',
            style: TextStyle(
              fontSize: 11,
              color: NewsColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kategori modern: ikon warna + nama + hitungan + aksi edit/hapus.
class _CategoryCard extends StatelessWidget {
  final Category category;
  final int count;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.count,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tint = avatarColorFor(category.name);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initialFor(category.name).isEmpty
                  ? 'K'
                  : initialFor(category.name)[0],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: tint,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: NewsColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: NewsColors.searchBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count artikel',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: NewsColors.subtitle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: Icons.edit_outlined,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: Icons.delete_outline,
            background: Colors.red.withValues(alpha: 0.1),
            foreground: Colors.red.shade600,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// State kosong dengan ajakan bertindak yang jelas.
class _EmptyCategories extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyCategories({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_outlined,
              size: 48,
              color: NewsColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada kategori',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: NewsColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buat kategori pertama untuk\nmengelompokkan artikelmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: NewsColors.subtitle,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Buat Kategori'),
            style: FilledButton.styleFrom(
              backgroundColor: NewsColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  final Category? category;

  const _CategoryNameDialog({this.category});

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.category?.name ?? '',
  );

  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama kategori wajib diisi');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: NewsColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEdit ? Icons.edit_outlined : Icons.add,
              size: 22,
              color: NewsColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
          ),
        ],
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_error != null) {
            setState(() => _error = null);
          }
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Nama Kategori',
          hintText: 'Masukkan nama kategori',
          errorText: _error,
          filled: true,
          fillColor: NewsColors.searchBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(
              color: NewsColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: NewsColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
