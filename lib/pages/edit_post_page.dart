import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class EditPostPage extends StatefulWidget {
  final Post post;

  const EditPostPage({
    super.key,
    required this.post,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final ApiService apiService = ApiService();

  late TextEditingController titleController;
  late TextEditingController contentController;

  List<Category> categories = [];
  int? selectedCategoryId;

  bool isLoading = false;
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.post.title,
    );

    contentController = TextEditingController(
      text: widget.post.content,
    );

    selectedCategoryId = widget.post.categoryId;

    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final data = await apiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = data;
        isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil kategori: $e'),
        ),
      );
    }
  }

  Future<void> updatePost() async {
    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data wajib diisi'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await apiService.updatePost(
        id: widget.post.id,
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        categoryId: selectedCategoryId!,
        image: widget.post.image,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil diubah'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah artikel: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Artikel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Artikel',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Isi Artikel',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: isLoadingCategories
                  ? null
                  : (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
              hint: isLoadingCategories
                  ? const Text('Memuat kategori...')
                  : const Text('Pilih kategori'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : updatePost,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}