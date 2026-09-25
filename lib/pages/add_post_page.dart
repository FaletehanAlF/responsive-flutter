import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../services/api_service.dart';

class AddPostPage extends StatefulWidget {
  /// Dipanggil saat berhasil menyimpan dalam mode tab MainShell.
  /// Jika null, halaman berperilaku sebagai route push dengan pop(true).
  final VoidCallback? onSaved;

  const AddPostPage({super.key, this.onSaved});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  final ApiService apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;

  List<Category> categories = [];
  int? selectedCategoryId;

  bool isLoading = false;
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
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
        _selectedImage = image;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: ${e.message}')),
      );
    }
  }

  void _resetForm() {
    titleController.clear();
    contentController.clear();
    setState(() {
      _selectedImage = null;
      selectedCategoryId = null;
    });
  }

  Future<void> savePost() async {
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
      await apiService.addPost(
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        categoryId: selectedCategoryId!,
        image: _selectedImage,
      );

      if (!mounted) return;

      // Mode tab MainShell: reset form + beri tahu shell lewat callback.
      if (widget.onSaved != null) {
        _resetForm();
        widget.onSaved!.call();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artikel berhasil ditambahkan')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
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
        centerTitle: true,
        automaticallyImplyLeading: widget.onSaved == null,
        title: const Text('Tambah Artikel'),
      ),
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
                  maxLines: 6,
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
                  hint: isLoadingCategories
                      ? const Text('Memuat kategori...')
                      : const Text('Pilih kategori'),
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
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: pickImageFromGallery,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      _selectedImage == null
                          ? 'Pilih Gambar'
                          : 'Ganti Gambar (${_selectedImage!.name})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
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
                            future: _selectedImage!.readAsBytes(),
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
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: isLoading ? null : savePost,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan Artikel'),
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
