import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/api_service.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final ApiService apiService = ApiService();
  final TextEditingController nameController = TextEditingController();

  late Future<List<Category>> categories;

  @override
  void initState() {
    super.initState();
    categories = apiService.getCategories();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      categories = apiService.getCategories();
    });
  }

  Future<void> addCategory() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kategori wajib diisi')),
      );
      return;
    }

    try {
      await apiService.addCategory(nameController.text.trim());
      nameController.clear();
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori berhasil ditambahkan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan kategori: $e')),
      );
    }
  }

  Future<void> editCategory(Category category) async {
    final controller = TextEditingController(text: category.name);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Kategori'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                try {
                  await apiService.updateCategory(
                    category.id,
                    controller.text.trim(),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!mounted) return;
                  _reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil diubah')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengubah kategori: $e')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Kategori'),
          content: Text(
            'Apakah kamu yakin ingin menghapus kategori "${category.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await apiService.deleteCategory(category.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus kategori: $e')),
      );
    }
  }

  void _showAddDialog() {
    nameController.clear();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Kategori'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await addCategory();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Kategori'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Kategori',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          double horizontalPadding = 16;
          if (isDesktop) {
            horizontalPadding = (constraints.maxWidth - 700) / 2;
            if (horizontalPadding < 16) horizontalPadding = 16;
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: FutureBuilder<List<Category>>(
              future: categories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('Belum ada kategori'));
                }

                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = data[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Ubah',
                              onPressed: () => editCategory(category),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              onPressed: () => deleteCategory(category),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
