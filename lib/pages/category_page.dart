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

  late Future<List<Category>> categories;

  @override
  void initState() {
    super.initState();
    categories = apiService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
      ),
      body: FutureBuilder<List<Category>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(
              child: Text('Belum ada kategori'),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final category = data[index];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(category.id.toString()),
                ),
                title: Text(category.name),
              );
            },
          );
        },
      ),
    );
  }
}