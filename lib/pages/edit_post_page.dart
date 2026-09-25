import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class EditPostPage extends StatefulWidget {
  final Post post;

  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final ApiService apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController titleController;
  late TextEditingController contentController;

  List<Category> categories = [];
  int? selectedCategoryId;
  XFile? _newImage;

  bool isLoading = false;
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.post.title);
    contentController = TextEditingController(text: widget.post.content);
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final data = await apiService.getCategories();
      if (!mounted) return;
      setState(() {
        categories = data;
        selectedCategoryId = widget.post.categoryId;
        isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil kategori: $e')),
      );
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return;
      setState(() {
        _newImage = image;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: ${e.message}')),
      );
    }
  }

  Future<void> updatePost() async {
    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data wajib diisi')),
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
        newImage: _newImage,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artikel berhasil diubah')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah artikel: $e')),
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
    final oldImageUrl = widget.post.imageUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Artikel')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          double horizontalPadding = 16;
          if (isDesktop) {
            horizontalPadding = (constraints.maxWidth - 700) / 2;
            if (horizontalPadding < 16) horizontalPadding = 16;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
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
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                const SizedBox(height: 16),
                if (oldImageUrl != null && _newImage == null) ...[
                  Text(
                    'Gambar saat ini',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      oldImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Gagal memuat gambar lama'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: pickImageFromGallery,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      _newImage == null
                          ? 'Ganti Gambar (opsional)'
                          : 'Gambar baru: ${_newImage!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_newImage != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(
                            _newImage!.path,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Gagal memuat preview'),
                              );
                            },
                          )
                        : FutureBuilder<Uint8List>(
                            future: _newImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Gagal memuat preview'),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: isLoading ? null : updatePost,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
