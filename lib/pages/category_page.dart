import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/narata_app_bar.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const NarataAppBar(title: Text('Kategori'), showBack: true),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Kategori',
        onPressed: _showCategoryDialog,
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          final double cap = isDesktop ? 760 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cap),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola kategori artikel.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colorScheme.outline),
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
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    size: 48,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Gagal memuat kategori',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
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
                            return const Center(
                              child: Text('Belum ada kategori'),
                            );
                          }

                          return ListView.separated(
                            itemCount: categories.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return _CategoryTile(
                                category: category,
                                count: counts[category.id] ?? 0,
                                onEdit: () => _showCategoryDialog(
                                  existing: category,
                                ),
                                onDelete: () => _confirmDelete(category),
                              );
                            },
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
      title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final int count;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.count,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.folder_outlined,
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$count artikel',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colorScheme.outline),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Ubah',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Hapus',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
