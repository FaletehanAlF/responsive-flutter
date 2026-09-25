import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/narata_app_bar.dart';

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

  String? titleError;
  String? contentError;
  String? categoryError;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil kategori: $e')));
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
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

  void _removeNewImage() {
    setState(() {
      _newImage = null;
    });
  }

  bool _validate() {
    setState(() {
      titleError = titleController.text.trim().isEmpty
          ? 'Judul artikel wajib diisi'
          : null;
      contentError = contentController.text.trim().isEmpty
          ? 'Isi artikel wajib diisi'
          : null;
      categoryError = selectedCategoryId == null
          ? 'Pilih salah satu kategori'
          : null;
    });
    return titleError == null && contentError == null && categoryError == null;
  }

  Future<void> updatePost() async {
    if (isLoading) return;
    if (!_validate()) return;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Artikel berhasil diubah')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengubah artikel: $e')));
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
    final colorScheme = Theme.of(context).colorScheme;
    final oldImageUrl = widget.post.imageUrl;

    return Scaffold(
      appBar: const NarataAppBar(title: Text('Edit Artikel'), showBack: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          final double cap = isDesktop ? 760 : double.infinity;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perbarui informasi artikel.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 20),
                      _fieldLabel(context, 'Judul Artikel'),
                      TextField(
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (titleError != null) {
                            setState(() => titleError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Masukkan judul artikel',
                          errorText: titleError,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Isi Artikel'),
                      TextField(
                        controller: contentController,
                        maxLines: 8,
                        minLines: 5,
                        onChanged: (_) {
                          if (contentError != null) {
                            setState(() => contentError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Tulis isi artikel di sini…',
                          errorText: contentError,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Kategori'),
                      DropdownButtonFormField<int>(
                        initialValue: selectedCategoryId,
                        decoration: InputDecoration(
                          hintText: isLoadingCategories
                              ? 'Memuat kategori…'
                              : 'Pilih kategori',
                          errorText: categoryError,
                          border: const OutlineInputBorder(),
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
                                  categoryError = null;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Gambar Sampul'),
                      if (oldImageUrl != null && _newImage == null) ...[
                        Text(
                          'Gambar saat ini',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.outline),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
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
                          icon: const Icon(Icons.image_outlined, size: 20),
                          label: Text(
                            _newImage == null
                                ? 'Ubah gambar (opsional)'
                                : 'Gambar baru: ${_newImage!.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_newImage != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb
                              ? Image.network(
                                  _newImage!.path,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Gagal memuat pratinjau'),
                                    );
                                  },
                                )
                              : FutureBuilder<Uint8List>(
                                  future: _newImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.hasData) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('Gagal memuat pratinjau'),
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _removeNewImage,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Batalkan gambar baru'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
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
                      const SizedBox(height: 8),
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

  Widget _fieldLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
