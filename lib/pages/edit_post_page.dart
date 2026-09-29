import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../utils/news_theme.dart';
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
    final oldImageUrl = widget.post.imageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: const NewsAppBar(
        title: 'Edit Artikel',
        showBack: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 600;
          final double cap = isDesktop ? 720 : double.infinity;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            number: '1',
                            title: 'Gambar Sampul',
                            trailing: 'Opsional',
                          ),
                          const SizedBox(height: 12),
                          _buildImageSection(oldImageUrl),
                          if (_newImage == null &&
                              (oldImageUrl == null ||
                                  _removeExistingImage)) ...[
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 15,
                                  color: NewsColors.subtitle,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Pilih gambar dari galeri / file perangkat bila ingin menambah sampul.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: NewsColors.subtitle,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            number: '2',
                            title: 'Judul & Isi',
                          ),
                          const SizedBox(height: 12),
                          _fieldLabel(context, 'Judul Artikel'),
                          TextField(
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontSize: 15,
                              color: NewsColors.ink,
                            ),
                            onChanged: (_) {
                              if (_titleError != null) {
                                setState(() => _titleError = null);
                              }
                            },
                            decoration: _inputDecoration(
                              hint: 'Masukkan judul artikel',
                              errorText: _titleError,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel(context, 'Isi Artikel'),
                          TextField(
                            controller: _contentController,
                            maxLines: 10,
                            minLines: 5,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: NewsColors.ink,
                            ),
                            onChanged: (_) {
                              if (_contentError != null) {
                                setState(() => _contentError = null);
                              }
                            },
                            decoration: _inputDecoration(
                              hint: 'Tulis isi artikel di sini…',
                              errorText: _contentError,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(
                            number: '3',
                            title: 'Kategori',
                          ),
                          const SizedBox(height: 12),
                          _buildCategoryDropdown(context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: NewsColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, String? errorText}) {
    const radius = BorderRadius.all(Radius.circular(16));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14.5,
        color: NewsColors.muted,
      ),
      errorText: errorText,
      filled: true,
      fillColor: NewsColors.searchBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: NewsColors.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      style: const TextStyle(fontSize: 15, color: NewsColors.ink),
      decoration: _inputDecoration(
        hint: _isLoadingCategories ? 'Memuat kategori…' : 'Pilih kategori',
        errorText: _categoryError,
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
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: NewsColors.ink,
        ),
      ),
    );
  }
}

/// Kartu putih pembungkus tiap seksi form (konsisten dengan Add page).
class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Judul seksi bernomor.
class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  final String? trailing;

  const _SectionHeader({
    required this.number,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: NewsColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: NewsColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: NewsColors.ink,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: NewsColors.searchBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: NewsColors.subtitle,
              ),
            ),
          ),
      ],
    );
  }
}
