import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final categoryController = TextEditingController();

  final ApiService apiService = ApiService();

  bool isLoading = false;

  Future<void> savePost() async {
    if (titleController.text.isEmpty ||
        contentController.text.isEmpty ||
        categoryController.text.isEmpty) {
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
      await apiService.addPost(
        title: titleController.text,
        content: contentController.text,
        categoryId: int.parse(categoryController.text),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil ditambahkan'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
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
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Artikel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Artikel',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Isi Artikel',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: categoryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID Kategori',
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : savePost,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Simpan Artikel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}