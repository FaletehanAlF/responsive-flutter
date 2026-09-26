import 'package:flutter/material.dart';

import '../models/post.dart';
import '../utils/formatters.dart';
import '../utils/news_theme.dart';

/// Tombol lingkaran abu seperti di referensi (hamburger / search / bell).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showDot;
  final Color? background;
  final Color? foreground;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.showDot = false,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? NewsColors.circleBtnBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: foreground ?? NewsColors.ink),
              if (showDot)
                Positioned(
                  top: 11,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header section "Breaking News ... View all".
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final String viewAllLabel;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.viewAllLabel = 'View all',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: NewsColors.ink,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              viewAllLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NewsColors.primary,
              ),
            ),
          )
        else
          const Text(
            'View all',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: NewsColors.primary,
            ),
          ),
      ],
    );
  }
}

/// Badge kategori biru mengambang di atas gambar (Sports).
class FloatingCategoryBadge extends StatelessWidget {
  final String label;

  const FloatingCategoryBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NewsColors.badgeBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Kartu Breaking News: gambar penuh + gradient + teks overlay.
class BreakingNewsCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final double height;
  final double? width;

  const BreakingNewsCard({
    super.key,
    required this.post,
    required this.onTap,
    this.height = 210,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrl;
    final meta = relativeTime(post.createdAt);

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    );
                  },
                  errorBuilder: (context, e, s) =>
                      const _ImageFallback(iconSize: 48),
                )
              else
                const _ImageFallback(iconSize: 48),
              // gradient bawah
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x33000000),
                      Color(0xCC000000),
                    ],
                    stops: [0.35, 0.65, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FloatingCategoryBadge(label: post.categoryName),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.categoryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: Color(0xFF4AA8FF),
                              ),
                              if (meta.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    meta,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile Recommendation / Discover: thumbnail kiri + teks kanan.
class NewsListTile extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final double thumbnailSize;

  const NewsListTile({
    super.key,
    required this.post,
    required this.onTap,
    this.thumbnailSize = 96,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrl;
    final date = formatPostDate(post.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: thumbnailSize,
                  height: thumbnailSize,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: const Color(0xFFF1F2F4),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, e, s) =>
                              const _ImageFallback(iconSize: 30),
                        )
                      : const _ImageFallback(iconSize: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: NewsColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: NewsColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniAvatar(name: post.categoryName, size: 20),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            post.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (date.isNotEmpty) ...[
                          const Text(
                            ' •  ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9AA0A6),
                            ),
                          ),
                          Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF9AA0A6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar kecil dari inisial.
class _MiniAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _MiniAvatar({required this.name, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarColorFor(name).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initialFor(name).isEmpty ? 'N' : initialFor(name)[0],
        style: TextStyle(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
          color: avatarColorFor(name),
        ),
      ),
    );
  }
}

class AuthorAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const AuthorAvatar({super.key, required this.name, this.radius = 11});

  @override
  Widget build(BuildContext context) {
    final bg = avatarColorFor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg.withValues(alpha: 0.15),
      child: Text(
        initialFor(name).isEmpty ? 'N' : initialFor(name)[0],
        style: TextStyle(
          fontSize: radius,
          fontWeight: FontWeight.w700,
          color: bg,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final double iconSize;

  const _ImageFallback({this.iconSize = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE4E6EB),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: iconSize,
          color: const Color(0xFF9AA0A6),
        ),
      ),
    );
  }
}

/// Search bar ala Discover.
class DiscoverSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onFilterTap;

  const DiscoverSearchBar({
    super.key,
    required this.controller,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: NewsColors.searchBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(left: 6, right: 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.search, size: 22, color: Color(0xFF8E8E93)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(fontSize: 15, color: Color(0xFF9AA0A6)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15, color: NewsColors.ink),
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onFilterTap,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.tune,
                  size: 20,
                  color: NewsColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deretan chip kategori ala Discover (All biru aktif).
class CategoryPills extends StatelessWidget {
  final List<({int? id, String label})> items;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const CategoryPills({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Pill(
              label: items[i].label,
              selected: selectedId == items[i].id,
              onTap: () => onSelected(items[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? NewsColors.primary : const Color(0xFFF1F2F4),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

/// Indikator dots carousel.
class CarouselDots extends StatelessWidget {
  final int count;
  final int active;

  const CarouselDots({super.key, required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? NewsColors.primary : const Color(0xFFD9D9DE),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
