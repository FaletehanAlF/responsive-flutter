import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../utils/news_theme.dart';

/// Area pilih gambar sampul — KHUSUS file dari perangkat (klik / drag & drop).
///
/// Sengaja TANPA fitur tempel link (Pinterest/Chrome dsb) karena link
/// hotlink sering gagal diunduh server (403/CORS/bukan file langsung).
/// Alur yang didukung dan stabil:
/// - Klik area -> [onPick] (galeri / file picker).
/// - Drag & drop file lokal dari komputer -> [onDroppedFile].
/// - [imageUrl] hanya untuk gambar lama dari server (/uploads/...)
///   pada halaman edit, BUKAN link tempelan user.
class ImageDropZone extends StatefulWidget {
  /// Gambar baru yang sudah dipilih (via picker maupun drop).
  final XFile? image;

  /// URL gambar lama dari server (dipakai halaman edit).
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

  /// Cek apakah nama file berekstensi gambar yang didukung backend.
  static bool isSupportedImageName(String fileName) {
    final lower = fileName.toLowerCase();
    return kSupportedImageExtensions.any(lower.endsWith);
  }

  @override
  State<ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<ImageDropZone> {
  bool _dragging = false;

  void _handleDragDone(DropDoneDetails details) {
    setState(() => _dragging = false);
    try {
      if (details.files.isEmpty) {
        widget.onDropError(
          'Tidak ada file yang diterima. Seret file gambar dari perangkatmu.',
        );
        return;
      }

      for (final file in details.files) {
        if (file is DropItemDirectory) continue;
        final name = file.name;
        if (name.isNotEmpty && ImageDropZone.isSupportedImageName(name)) {
          widget.onDroppedFile(file);
          return;
        }
        if (name.isEmpty && ImageDropZone.isSupportedImageName(file.path)) {
          final fallbackName = file.path.split(RegExp(r'[\\/]')).last;
          widget.onDroppedFile(XFile(file.path, name: fallbackName));
          return;
        }
      }

      if (details.files.every((file) => file is DropItemDirectory)) {
        widget.onDropError(
          'Yang diseret adalah folder. Seret file gambarnya langsung.',
        );
        return;
      }

      widget.onDropError(
        'Format tidak didukung. Gunakan JPG, PNG, atau WEBP.',
      );
    } catch (_) {
      widget.onDropError(
        'Gagal memproses file. Coba pilih lewat tombol.',
      );
    }
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
          _previewCard(_buildNewPreview(image)),
          const SizedBox(height: 10),
          _fileNameChip(image.name),
          const SizedBox(height: 6),
          Text(
            _dragging
                ? 'Lepaskan gambar di sini untuk mengganti'
                : 'Seret gambar lain ke sini untuk mengganti',
            style: const TextStyle(
              fontSize: 12,
              color: NewsColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _actionButtons(),
        ],
      );
    }

    final imageUrl = widget.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _previewCard(
            Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _PreviewError(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _dragging
                ? 'Lepaskan gambar di sini untuk mengganti'
                : 'Seret gambar baru ke sini untuk mengganti',
            style: const TextStyle(
              fontSize: 12,
              color: NewsColors.subtitle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _actionButtons(),
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
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      : Icons.add_photo_alternate_outlined,
                  size: 30,
                  color: NewsColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _dragging
                    ? 'Lepaskan gambar di sini'
                    : 'Pilih gambar sampul',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: NewsColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ketuk untuk memilih dari galeri / file',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: NewsColors.subtitle,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NewsColors.searchBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'JPG • PNG • WEBP — Maks 2 MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NewsColors.subtitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: child,
        ),
      ),
    );
  }

  Widget _fileNameChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NewsColors.searchBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.image_outlined,
            size: 16,
            color: NewsColors.subtitle,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name.isEmpty ? 'gambar' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: NewsColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    final replaceButton = OutlinedButton.icon(
      onPressed: widget.onPick,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Ganti gambar'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
    final removeButton = widget.onRemove == null
        ? null
        : TextButton.icon(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus'),
          );

    if (removeButton == null) {
      return SizedBox(width: double.infinity, child: replaceButton);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              replaceButton,
              const SizedBox(height: 4),
              Center(child: removeButton),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: replaceButton),
            const SizedBox(width: 10),
            removeButton,
          ],
        );
      },
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
      color: colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 40),
      ),
    );
  }
}
