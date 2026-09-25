import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../services/api_service.dart';

/// Form tambah artikel: gambar sampul di paling atas, lalu
/// judul, isi, dan kategori.
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

  String? titleError;
  String? contentError;
  String? categoryError;

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

  void _removeImage() {
    setState(() {
      _selectedImage = null;
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
      categoryError =
          selectedCategoryId == null ? 'Pilih salah satu kategori' : null;
    });
    return titleError == null &&
        contentError == null &&
        categoryError == null;
  }

  void _resetForm() {
    titleController.clear();
    contentController.clear();
    setState(() {
      _selectedImage = null;
      selectedCategoryId = null;
      titleError = null;
      contentError = null;
      categoryError = null;
    });
  }

  Future<void> savePost() async {
    if (isLoading) return;
    if (!_validate()) return;

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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: widget.onSaved == null,
        title: const Text('Tambah Artikel'),
      ),
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
                        'Publikasikan artikel baru.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 20),
                      _fieldLabel(context, 'Gambar Sampul'),
                      _imagePicker(context),
                      const SizedBox(height: 16),
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
                        maxLines: 6,
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
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
                              : const Text('Tambah Artikel'),
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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  /// Area pilih gambar di paling atas form: tampil sebagai area
  /// upload visual saat kosong, pratinjau terbatas saat terisi.
  Widget _imagePicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 600;

    if (_selectedImage == null) {
      return InkWell(
        onTap: pickImageFromGallery,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 28,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border.all(
              color: colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pilih gambar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'JPG, PNG, atau WEBP • Maks 2 MB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isDesktop ? 320 : 260,
            ),
            child: kIsWeb
                ? Image.network(
                    _selectedImage!.path,
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
                    future: _selectedImage!.readAsBytes(),
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
                      if (snapshot.hasError || !snapshot.hasData) {
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
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: pickImageFromGallery,
                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                ),
                label: const Text('Ganti gambar'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _removeImage,
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
              ),
              label: const Text('Hapus'),
            ),
          ],
        ),
      ],
    );
  }
}
