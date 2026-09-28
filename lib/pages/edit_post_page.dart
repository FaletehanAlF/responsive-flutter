import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/image_drop_zone.dart';
import '../widgets/news_widgets.dart';

class EditPostPage extends StatefulWidget {
  final Post post;
  final ApiService? apiService;

  const EditPostPage({super.key, required this.post, this.apiService});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final ImagePicker _picker = ImagePicker();
  late final ApiService apiService = widget.apiService ?? ApiService();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _imageUrlController;

  List<Category> _categories = const [];
  int? _selectedCategoryId;

  XFile? _newImage;
  Future<Uint8List>? _previewFuture;
  bool _removeExistingImage = false;
  bool _showUrlField = false;

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
    _imageUrlController = TextEditingController();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
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

  Future<void> _handleNewFile(XFile image) async {
    // Baca bytes dulu (bukan image.length()) karena file hasil drag & drop
    // di web berupa blob URL yang tidak bisa di-stat panjangnya.
    late final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Gagal membaca file gambar. Coba pilih lewat tombol.');
      return;
    }
    if (!mounted) return;

    if (bytes.lengthInBytes > kMaxImageSizeInBytes) {
      _showMessage(
        'Ukuran gambar ${(bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1)} MB '
        'melebihi batas 2 MB',
      );
      return;
    }

    setState(() {
      _newImage = image;
      // Bytes sudah di tangan, langsung pakai agar preview tampil seketika.
      _previewFuture = Future.value(bytes);
      _removeExistingImage = false;
      // File menang atas link: kosongkan link agar tidak konflik.
      _imageUrlController.clear();
    });
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      await _handleNewFile(image);
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

  /// Link gambar yang ditempel user. Hanya dipakai bila tidak ada file baru.
  String? get _pastedImageUrl {
    final url = _imageUrlController.text.trim();
    return url.isEmpty ? null : url;
  }

  bool _validateImageUrl() {
    final url = _pastedImageUrl;
    if (_newImage == null &&
        url != null &&
        !url.startsWith('http://') &&
        !url.startsWith('https://')) {
      _showMessage('Link gambar harus diawali http:// atau https://');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validate()) return;
    if (!_validateImageUrl()) return;

    setState(() => _isSubmitting = true);

    try {
      await apiService.updatePost(
        id: widget.post.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: _selectedCategoryId!,
        image: _removeExistingImage ? '' : widget.post.image,
        newImage: _newImage,
        imageUrl: _newImage == null ? _pastedImageUrl : null,
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
      appBar: const NewsAppBar(
        title: 'Edit Artikel',
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
                      _buildImageSection(oldImageUrl),
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

  Widget _buildImageSection(String? oldImageUrl) {
    final newImage = _newImage;
    final currentImageUrl =
        oldImageUrl != null && !_removeExistingImage ? oldImageUrl : null;

    // Tanpa gambar sama sekali (tidak ada gambar lama & tidak ada yang baru).
    if (newImage == null && currentImageUrl == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageDropZone(
            image: null,
            previewFuture: _previewFuture,
            onPick: _pickImage,
            onDroppedFile: _handleNewFile,
            onDropError: _showMessage,
          ),
          if (oldImageUrl != null) ...[
            const SizedBox(height: 10),
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImageDropZone(
          image: newImage,
          imageUrl: newImage == null ? currentImageUrl : null,
          previewFuture: _previewFuture,
          onPick: _pickImage,
          onDroppedFile: _handleNewFile,
          onDropError: _showMessage,
          // Tombol "Hapus" di dalam widget sudah membatalkan gambar baru,
          // jadi tidak perlu tombol duplikat di sini.
          onRemove: newImage == null ? null : _cancelNewImage,
        ),
        // Toggle hapus gambar lama hanya relevan saat tidak ada gambar baru.
        if (newImage == null && oldImageUrl != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _toggleRemoveExistingImage,
            icon: Icon(
              _removeExistingImage ? Icons.restore : Icons.delete_outline,
              size: 18,
            ),
            label: Text(
              _removeExistingImage ? 'Batal hapus' : 'Hapus gambar',
            ),
          ),
        ],
      ],
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
