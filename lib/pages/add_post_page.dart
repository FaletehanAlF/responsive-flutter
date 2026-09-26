import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/news_widgets.dart';
import 'articles_page.dart';
import 'profile_page.dart';

class AddPostPage extends StatefulWidget {
  final VoidCallback? onSaved;
  final ApiService? apiService;

  const AddPostPage({super.key, this.onSaved, this.apiService});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  late final ApiService apiService = widget.apiService ?? ApiService();

  XFile? _selectedImage;
  Future<Uint8List>? _previewFuture;

  List<Category> _categories = const [];
  int? _selectedCategoryId;

  String? _titleError;
  String? _contentError;
  String? _categoryError;

  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadCategories() async {
    try {
      final data = await apiService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = data;
        _isLoadingCategories = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
      _showMessage('Gagal mengambil kategori: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;

      final size = await image.length();
      if (size > kMaxImageSizeInBytes) {
        _showMessage(
          'Ukuran gambar ${(size / (1024 * 1024)).toStringAsFixed(1)} MB '
          'melebihi batas 2 MB',
        );
        return;
      }

      setState(() {
        _selectedImage = image;
        _previewFuture = image.readAsBytes();
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showMessage('Gagal memilih gambar: ${e.message}');
    }
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    setState(() {
      _titleError = title.isEmpty ? 'Judul artikel wajib diisi' : null;
      _contentError = content.isEmpty ? 'Isi artikel wajib diisi' : null;
      _categoryError = _selectedCategoryId == null
          ? 'Pilih salah satu kategori'
          : null;
    });

    return _titleError == null && _contentError == null && _categoryError == null;
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedImage = null;
      _previewFuture = null;
      _selectedCategoryId = null;
      _titleError = null;
      _contentError = null;
      _categoryError = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await apiService.addPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: _selectedCategoryId!,
        image: _selectedImage,
      );

      if (!mounted) return;

      if (widget.onSaved != null) {
        _resetForm();
        widget.onSaved!.call();
        return;
      }

      _showMessage('Artikel berhasil ditambahkan');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menambahkan artikel: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: NewsAppBar(
        title: 'Tambah Artikel',
        showBack: widget.onSaved == null,
        onProfile: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        ),
        onSearch: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ArticlesPage()),
        ),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 20),
                      _fieldLabel(context, 'Gambar Sampul'),
                      _buildImagePicker(context, colorScheme),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Judul Artikel'),
                      TextField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_titleError != null) {
                            setState(() => _titleError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Masukkan judul artikel',
                          errorText: _titleError,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Isi Artikel'),
                      TextField(
                        controller: _contentController,
                        maxLines: 10,
                        minLines: 5,
                        onChanged: (_) {
                          if (_contentError != null) {
                            setState(() => _contentError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Tulis isi artikel di sini…',
                          errorText: _contentError,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Kategori'),
                      _buildCategoryDropdown(context),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
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

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        hintText: _isLoadingCategories ? 'Memuat kategori…' : 'Pilih kategori',
        errorText: _categoryError,
        border: const OutlineInputBorder(),
      ),
      items: _categories
          .map(
            (category) => DropdownMenuItem<int>(
              value: category.id,
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _isLoadingCategories
          ? null
          : (value) {
              setState(() {
                _selectedCategoryId = value;
                _categoryError = null;
              });
            },
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, ColorScheme colorScheme) {
    final image = _selectedImage;
    if (image == null) {
      return InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border.all(color: colorScheme.outlineVariant),
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'JPG, PNG, atau WEBP • Maks 2 MB',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.outline),
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
          child: _buildPreview(context, image),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Ganti gambar'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _previewFuture = null;
                });
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Hapus'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context, XFile image) {
    if (kIsWeb) {
      return Image.network(
        image.path,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _PreviewError(),
      );
    }

    return FutureBuilder<Uint8List>(
      future: _previewFuture ?? image.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const _PreviewError();
        }
        return Image.memory(
          snapshot.data!,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      color: colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 40),
      ),
    );
  }
}
