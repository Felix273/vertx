// lib/shared/widgets/widgets.dart
// VERTX — Reusable UI components
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';

class SeriesPosterCard extends StatelessWidget {
  final Series series;
  final VoidCallback onTap;
  final double width;
  final double? height;

  const SeriesPosterCard({
    super.key,
    required this.series,
    required this.onTap,
    this.width = 140,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? width * (4 / 3);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: h + 56,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster image
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  SizedBox(
                    width: width,
                    height: h,
                    child: series.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: series.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _shimmerBox(width, h),
                            errorWidget: (_, __, ___) =>
                                _fallbackPoster(width, h),
                          )
                        : _fallbackPoster(width, h),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: AppColors.cardFade,
                      ),
                    ),
                  ),
                  if (series.isFree)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge(
                          AppLocalizations.of(context).free, AppColors.gold),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _Badge(series.genre.toUpperCase(),
                        AppColors.violet.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              series.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '${series.episodeCount} ${AppLocalizations.of(context).episodes}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPoster(double w, double h) => Container(
        width: w,
        height: h,
        decoration: const BoxDecoration(gradient: AppColors.posterGlow),
        child: const Center(
          child:
              Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 32),
        ),
      );

  Widget _shimmerBox(double w, double h) => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: AppColors.panel,
        child: Container(width: w, height: h, color: AppColors.surface),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }
}

class SeriesRow extends StatelessWidget {
  final String title;
  final List<Series> series;
  final void Function(Series) onTap;

  const SeriesRow(
      {super.key,
      required this.title,
      required this.series,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: series.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SeriesPosterCard(
                series: series[i],
                onTap: () => onTap(series[i]),
                width: 140,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget shimmerCard({double width = 140, double height = 200}) {
  return Shimmer.fromColors(
    baseColor: AppColors.surface,
    highlightColor: AppColors.panel,
    child: Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.surface,
    ),
  );
}

class FeaturedBanner extends StatelessWidget {
  final Series series;
  final VoidCallback onTap;
  const FeaturedBanner({super.key, required this.series, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 360,
            child: series.thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: series.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surface),
                  )
                : const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.posterGlow),
                    child: Center(
                        child: Icon(Icons.movie_outlined,
                            color: AppColors.textMuted, size: 64)),
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.black],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.12),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.7)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(series.genre.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan)),
                ),
                const SizedBox(height: 8),
                Text(series.title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(series.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(l.watchNow),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
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

class ShimmerSeriesRow extends StatelessWidget {
  const ShimmerSeriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.panel,
            child: Container(width: 140, height: 240, color: AppColors.surface),
          ),
        ),
      ),
    );
  }
}

class GenreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const GenreChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.panel.withOpacity(0.55),
          border: Border.all(
              color: selected
                  ? AppColors.gold
                  : AppColors.textMuted.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class VxEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const VxEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}
