import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../utils/news_theme.dart';

/// Area drag & drop + klik untuk memilih gambar sampul artikel.
///
/// Widget ini HANYA menangani UI dan validasi ekstensi file.
/// - Klik area -> [onPick] (file picker yang sudah ada di page).
/// - Drop file -> validasi ekstensi, lalu [onDroppedFile].
/// - File tidak valid -> [onDropError] dengan pesan yang jelas.
/// - Jika beberapa file di-drop sekaligus, hanya satu file gambar
///   valid pertama yang dipakai (form hanya butuh satu gambar).
///
/// Logic upload/HTTP tetap di service/page. Validasi ukuran (2 MB)
/// tetap di page/service agar tidak ada duplikasi aturan.
///
/// Catatan Pinterest: drag langsung dari website seperti Pinterest
/// hanya berfungsi jika browser/OS memberikan file nyata ke Flutter.
/// Jika browser hanya memberikan URL (karena CORS), drop akan ditolak
/// dengan pesan error. Drag file lokal selalu didukung.
class ImageDropZone extends StatefulWidget {
  /// Gambar baru yang sudah dipilih (via picker maupun drop).
  final XFile? image;

  /// URL gambar lama (dipakai halaman edit saat belum ada gambar baru).
  final String? imageUrl;

  /// Future bytes untuk preview di platform non-web.
  final Future<Uint8List>? previewFuture;

  /// Dipanggil saat user mengklik area (buka file picker).
  final VoidCallback onPick;

  /// Dipanggil dengan file valid hasil drop.
  final ValueChanged<XFile> onDroppedFile;

  /// Dipanggil dengan pesan error saat file drop tidak valid.
  final ValueChanged<String> onDropError;

  /// Dipanggil saat user menghapus gambar baru. Null = sembunyikan tombol.
  final VoidCallback? onRemove;

  const ImageDropZone({
    super.key,
    required this.image,
    this.imageUrl,
    this.previewFuture,
    required this.onPick,
    required this.onDroppedFile,
    required this.onDropError,
    this.onRemove,
  });

  @override
  State<ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<ImageDropZone> {
  bool _dragging = false;

  bool _isSupportedImage(String fileName) {
    final lower = fileName.toLowerCase();
    return kSupportedImageExtensions.any(lower.endsWith);
  }

  void _handleDragDone(DropDoneDetails details) {
    setState(() => _dragging = false);
    if (details.files.isEmpty) {
      // Terjadi saat drag dari website (mis. Pinterest): browser tidak
      // memberikan file nyata, hanya URL. Jelaskan ke user.
      widget.onDropError(
        'Tidak ada file gambar yang diterima. Seret file gambar dari komputer Anda.',
      );
      return;
    }

    for (final file in details.files) {
      final name = file.name;
      if (name.isNotEmpty && _isSupportedImage(name)) {
        // Teruskan objek file ASLI (jangan dibuat ulang dari path) agar
        // isi file (terutama blob URL di web) tidak hilang.
        widget.onDroppedFile(file);
        return;
      }
      // Fallback: sebagian browser mengisi path tanpa name.
      if (name.isEmpty && _isSupportedImage(file.path)) {
        final fallbackName = file.path.split(RegExp(r'[\\/]')).last;
        widget.onDroppedFile(XFile(file.path, name: fallbackName));
        return;
      }
    }

    widget.onDropError(
      'Format gambar tidak didukung. Hanya jpg, jpeg, png, webp yang diizinkan',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _handleDragDone,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _dragging
              ? NewsColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          border: _dragging
              ? Border.all(color: NewsColors.primary, width: 2)
              : null,
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final image = widget.image;
    if (image != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildNewPreview(image),
            ),
          ),
          const SizedBox(height: 8),
          _fileNameRow(image.name),
          const SizedBox(height: 4),
          Text(
            _dragging
                ? 'Lepaskan gambar di sini untuk mengganti'
                : 'Seret gambar baru ke sini atau klik Ganti',
            style: const TextStyle(
              fontSize: 12,
              color: NewsColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onPick,
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
              if (widget.onRemove != null) ...[
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                ),
              ],
            ],
          ),
        ],
      );
    }

    final imageUrl = widget.imageUrl;
    if (imageUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _PreviewError(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dragging
                ? 'Lepaskan gambar di sini untuk mengganti'
                : 'Seret gambar baru ke sini atau klik Ganti',
            style: const TextStyle(
              fontSize: 12,
              color: NewsColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.onPick,
            icon: const Icon(Icons.image_outlined, size: 20),
            label: const Text('Ganti gambar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      );
    }

    return CustomPaint(
      painter: _DashedBorderPainter(
        color: _dragging ? NewsColors.primary : const Color(0xFFC9CDD3),
        radius: 20,
      ),
      child: InkWell(
        onTap: widget.onPick,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: NewsColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _dragging
                      ? Icons.file_download_outlined
                      : Icons.cloud_upload_outlined,
                  size: 30,
                  color: NewsColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _dragging
                    ? 'Lepaskan gambar di sini'
                    : 'Seret & letakkan gambar di sini',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: NewsColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'atau klik untuk memilih gambar',
                style: TextStyle(
                  fontSize: 13,
                  color: NewsColors.subtitle,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
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

  Widget _fileNameRow(String name) {
    return Row(
      children: [
        const Icon(Icons.image_outlined, size: 16, color: NewsColors.subtitle),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: NewsColors.subtitle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPreview(XFile image) {
    if (kIsWeb) {
      return Image.network(
        image.path,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _PreviewError(),
      );
    }

    return FutureBuilder<Uint8List>(
      future: widget.previewFuture ?? image.readAsBytes(),
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
