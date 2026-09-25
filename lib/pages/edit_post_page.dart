import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/post.dart';
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
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  List<Category> _categories = const [];
  int? _selectedCategoryId;

  XFile? _newImage;
  Future<Uint8List>? _previewFuture;
  bool _removeExistingImage = false;

  String? _titleError;
  String? _contentError;
  String? _categoryError;

  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
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
        _selectedCategoryId = data.any((c) => c.id == widget.post.categoryId)
            ? widget.post.categoryId
            : null;
        _isLoadingCategories = false;
        if (_selectedCategoryId == null) {
          _categoryError = 'Kategori asli sudah tidak tersedia, pilih ulang';
        }
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
        _newImage = image;
        _previewFuture = image.readAsBytes();
        _removeExistingImage = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showMessage('Gagal memilih gambar: ${e.message}');
    }
  }

  void _cancelNewImage() {
    setState(() {
      _newImage = null;
      _previewFuture = null;
      if (widget.post.imageUrl == null) {
        _removeExistingImage = false;
      }
    });
  }

  void _toggleRemoveExistingImage() {
    setState(() {
      _removeExistingImage = !_removeExistingImage;
      if (_removeExistingImage) {
        _newImage = null;
        _previewFuture = null;
      }
    });
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    setState(() {
      _titleError = title.isEmpty ? 'Judul artikel wajib diisi' : null;
      _contentError = content.isEmpty ? 'Isi artikel wajib diisi' : null;
      _categoryError =
          _selectedCategoryId == null ? 'Pilih salah satu kategori' : null;
    });

    return _titleError == null && _contentError == null && _categoryError == null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await apiService.updatePost(
        id: widget.post.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: _selectedCategoryId!,
        image: _removeExistingImage ? '' : widget.post.image,
        newImage: _newImage,
      );

      if (!mounted) return;
      _showMessage('Artikel berhasil diubah');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal mengubah artikel: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final oldImageUrl = widget.post.imageUrl;

    return Scaffold(
      appBar: const NarataAppBar(
        title: Text('Edit Artikel'),
        showBack: true,
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
                        'Perbarui informasi artikel.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      const SizedBox(height: 20),
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
                        maxLines: 12,
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
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Gambar Sampul'),
                      _buildImageSection(context, colorScheme, oldImageUrl),
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

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        hintText: _isLoadingCategories ? 'Memuat kategori…' : 'Pilih kategori',
        errorText: _categoryError,
        errorMaxLines: 2,
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

  Widget _buildImageSection(
    BuildContext context,
    ColorScheme colorScheme,
    String? oldImageUrl,
  ) {
    final newImage = _newImage;
    final currentImageUrl =
        oldImageUrl != null && !_removeExistingImage ? oldImageUrl : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (newImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildNewImagePreview(context, newImage),
          )
        else if (currentImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              currentImageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
          )
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 32,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tanpa gambar sampul',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, size: 20),
                label: Text(newImage == null ? 'Ganti gambar' : 'Ganti lagi'),
              ),
            ),
            if (oldImageUrl != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _toggleRemoveExistingImage,
                icon: Icon(
                  _removeExistingImage
                      ? Icons.restore
                      : Icons.delete_outline,
                  size: 18,
                ),
                label: Text(
                  _removeExistingImage ? 'Batal hapus' : 'Hapus gambar',
                ),
              ),
            ],
          ],
        ),
        if (newImage != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _cancelNewImage,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Batalkan gambar baru'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNewImagePreview(BuildContext context, XFile image) {
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
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
    );
  }
}
