import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../services/api_service.dart';
import '../utils/news_theme.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
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
          final device = deviceForWidth(constraints.maxWidth);
          final contentMax =
              device == AppDevice.mobile ? double.infinity : 720.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMax),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HeaderBanner(),
                    const SizedBox(height: 14),
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
                          _buildImagePicker(context),
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
                            maxLines: 8,
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
                          : const Text('Tambah Artikel'),
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

  Widget _buildImagePicker(BuildContext context) {
    final image = _selectedImage;
    if (image == null) {
      return CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFC9CDD3),
          radius: 20,
        ),
        child: InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            child: const Column(
              children: [
                _DropIcon(),
                SizedBox(height: 12),
                Text(
                  'Pilih gambar sampul',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: NewsColors.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'JPG, PNG, atau WEBP • Maks 2 MB',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: NewsColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPreview(context, image),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Ganti gambar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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

/// Banner gradasi pembuka form.
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E88FF), Color(0xFF0F5FCC)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          _BannerIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat Artikel Baru',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bagikan cerita dan wawasanmu kepada pembaca.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerIcon extends StatelessWidget {
  const _BannerIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.edit_note_rounded,
        size: 28,
        color: Colors.white,
      ),
    );
  }
}

/// Kartu putih pembungkus tiap seksi form.
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

/// Judul seksi bernomor (1 · Sampul, 2 · Judul & Isi, ...).
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

class _DropIcon extends StatelessWidget {
  const _DropIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: NewsColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.cloud_upload_outlined,
        size: 30,
        color: NewsColors.primary,
      ),
    );
  }
}

/// Bingkai putus-putus untuk area unggah gambar.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, this.radius = 20});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 8.0;
    const dashGap = 6.0;
    const strokeWidth = 1.5;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromLTRBR(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth / 2,
      size.height - strokeWidth / 2,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        dashPath.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
