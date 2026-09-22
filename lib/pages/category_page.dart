import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/api_service.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController nameController = TextEditingController();

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

      setState(() {
        categories = apiService.getCategories();
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori berhasil ditambahkan')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambahkan kategori: $e')));
    }
  }

  final ApiService apiService = ApiService();

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
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Tambah Kategori'),
                content: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Kategori'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await addCategory();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(title: const Text('Kategori')),
      body: FutureBuilder<List<Category>>(
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

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final category = data[index];

              return ListTile(
                leading: CircleAvatar(child: Text(category.id.toString())),
                title: Text(category.name),
              );
            },
          );
        },
      ),
    );
  }
}
