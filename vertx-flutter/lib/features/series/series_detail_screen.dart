// lib/features/series/series_detail_screen.dart
// VERTX — Series detail: poster, info, episode list, Watch/Buy CTA

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';

class SeriesDetailScreen extends StatefulWidget {
  final String seriesId;
  const SeriesDetailScreen({super.key, required this.seriesId});
  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  final _api = ApiService();
  Series? _series;
  AccessStatus? _access;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getSeriesDetail(widget.seriesId),
        _api.checkAccess(widget.seriesId),
      ]);
      setState(() {
        _series = results[0] as Series;
        _access = results[1] as AccessStatus;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _watchEpisode(int idx) {
    if (_access?.hasAccess == true) {
      context.push('/player/${widget.seriesId}?ep=$idx');
    } else {
      context.push('/paywall/${widget.seriesId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (_series == null) {
      return Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(),
        body: VxEmptyState(icon: Icons.error_outline, title: l.error),
      );
    }

    final s = _series!;
    final access = _access;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: CustomScrollView(
        slivers: [
          // ── Hero image ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 460,
            pinned: true,
            backgroundColor: AppColors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  s.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: s.thumbnailUrl, fit: BoxFit.cover)
                      : const DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: AppColors.posterGlow)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.blue.withOpacity(0.28),
                          Colors.transparent,
                          AppColors.magenta.withOpacity(0.10),
                        ],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.black, Colors.transparent],
                        stops: [0.0, 0.6],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Genre + title ────────────────────────
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.12),
                    border: Border.all(color: AppColors.cyan.withOpacity(0.7)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.genre.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(s.title, style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text(
                  '${s.episodeCount} ${l.episodes} · ${s.producerName}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.cyan),
                ),
                const SizedBox(height: 12),
                Text(s.description,
                    style: Theme.of(context).textTheme.bodyMedium),

                const SizedBox(height: 20),

                // ── CTA buttons ──────────────────────────
                if (access?.hasAccess == true) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _watchEpisode(0),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(l.watchNow.toUpperCase()),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/paywall/${s.id}'),
                      icon: const Icon(Icons.lock_open_outlined, size: 18),
                      label: Text(l.subscribeNow.toUpperCase()),
                    ),
                  ),
                  if (access?.canPurchase == true) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push('/paywall/${s.id}'),
                        child: Text(
                          '${l.orBuyOnce} — KES ${access!.purchasePrice}'
                              .toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      _Metric(value: '${s.episodeCount}', label: 'EPISODES'),
                      const _MetricDivider(),
                      _Metric(
                          value: s.isFree ? 'FREE' : 'PREMIUM',
                          label: 'ACCESS'),
                      const _MetricDivider(),
                      _Metric(value: s.genre.toUpperCase(), label: 'GENRE'),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // ── Episodes list ────────────────────────
                Text(l.episodes, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                ...s.episodes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ep = entry.value;
                  final locked = access?.hasAccess != true;

                  return _EpisodeTile(
                    episode: ep,
                    locked: locked,
                    onTap: () => locked
                        ? context.push('/paywall/${s.id}')
                        : _watchEpisode(idx),
                  );
                }),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 9, letterSpacing: 0)),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: AppColors.border);
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool locked;
  final VoidCallback onTap;

  const _EpisodeTile({
    required this.episode,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.92),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Ep number
            SizedBox(
              width: 36,
              child: Text(
                '${episode.episodeNumber}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Thumbnail
            if (episode.thumbnailUrl.isNotEmpty)
              Container(
                width: 72,
                height: 52,
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: episode.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 72,
                height: 52,
                decoration: const BoxDecoration(gradient: AppColors.posterGlow),
                margin: const EdgeInsets.only(right: 12),
                child: const Icon(Icons.movie,
                    color: AppColors.textMuted, size: 20),
              ),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episode.durationDisplay,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            Icon(
              locked ? Icons.lock_outline : Icons.play_circle_outline,
              color: locked ? AppColors.textMuted : AppColors.gold,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
