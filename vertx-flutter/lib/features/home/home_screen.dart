// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  HomeFeed? _feed;
  bool _loading = true;
  String? _error;
  String? _selectedGenre;
  final _scrollController = ScrollController();
  bool _appBarTransparent = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _scrollController.addListener(() {
      final isTop = _scrollController.offset < 200;
      if (isTop != _appBarTransparent)
        setState(() => _appBarTransparent = isTop);
    });
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feed = await _api.getHomeFeed();
      setState(() {
        _feed = feed;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load.';
        _loading = false;
      });
    }
  }

  void _openSeries(Series s) => context.push('/series/${s.id}');

  List<Series> get _filteredNew {
    if (_feed == null) return [];
    if (_selectedGenre == null) return _feed!.newContent;
    return _feed!.newContent
        .where((s) => s.genre.toLowerCase() == _selectedGenre)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _appBarTransparent
            ? Colors.transparent
            : AppColors.black.withOpacity(0.95),
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0),
            children: [
              TextSpan(text: 'VERT', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'X', style: TextStyle(color: AppColors.cyan)),
            ],
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 22),
              onPressed: () => context.go('/search')),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? _buildShimmer()
          : _error != null
              ? _buildError()
              : _buildFeed(),
    );
  }

  Widget _buildFeed() {
    final feed = _feed!;
    if (feed.featured.isEmpty &&
        feed.newContent.isEmpty &&
        feed.free.isEmpty) {
      return _buildEmptyCatalog();
    }
    final featured = feed.featured.isNotEmpty ? feed.featured.first : null;
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surface,
      onRefresh: _loadFeed,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (featured != null)
            SliverToBoxAdapter(
                child: _HeroBanner(
                    series: featured,
                    onWatch: () => _openSeries(featured),
                    onInfo: () => _openSeries(featured))),
          const SliverToBoxAdapter(child: _SignalStrip()),
          SliverToBoxAdapter(
              child: _CategoryTabs(
                  selected: _selectedGenre,
                  onSelect: (g) => setState(() => _selectedGenre = g))),
          SliverToBoxAdapter(child: _SectionHeader(title: 'New Series')),
          SliverToBoxAdapter(
            child: _filteredNew.isEmpty
                ? const SizedBox(
                    height: 200,
                    child: Center(
                        child: Text('No series found.',
                            style: TextStyle(color: AppColors.textMuted))))
                : _PosterRow(series: _filteredNew, onTap: _openSeries),
          ),
          if (feed.free.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _SectionHeader(title: 'Free to Watch')),
            SliverToBoxAdapter(
                child: _PosterRow(series: feed.free, onTap: _openSeries)),
          ],
          if (feed.featured.length > 1) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _SectionHeader(title: 'Popular Now')),
            SliverToBoxAdapter(
                child: _PosterRow(
                    series: feed.featured.skip(1).toList(),
                    onTap: _openSeries)),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyCatalog() {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surface,
      onRefresh: _loadFeed,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 150, 24, 120),
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.posterGlow,
              border: Border.all(color: AppColors.cyan.withOpacity(0.55)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.movie_filter_rounded,
                color: AppColors.cyan, size: 36),
          ),
          const SizedBox(height: 28),
          const Text(
            'Your cinema is warming up',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.05),
          ),
          const SizedBox(height: 12),
          const Text(
            'New local stories are on the way. Browse the catalog or pull to refresh when a producer publishes the first series.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('BROWSE CATALOG'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadFeed,
                tooltip: 'Refresh catalog',
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textPrimary),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const _SignalStrip(),
        ],
      ),
    );
  }

  Widget _buildShimmer() => ListView(children: [
        Container(height: 560, color: AppColors.surface),
        const SizedBox(height: 16),
        const ShimmerSeriesRow(),
        const SizedBox(height: 16),
        const ShimmerSeriesRow(),
      ]);

  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textMuted, size: 56),
          const SizedBox(height: 16),
          const Text('Failed to load',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadFeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration:
                  BoxDecoration(border: Border.all(color: AppColors.gold)),
              child: const Text('RETRY',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
}

class _HeroBanner extends StatelessWidget {
  final Series series;
  final VoidCallback onWatch, onInfo;
  const _HeroBanner(
      {required this.series, required this.onWatch, required this.onInfo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: Stack(children: [
        Positioned.fill(
          child: series.thumbnailUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: series.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.surface))
              : const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.posterGlow)),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.blue.withOpacity(0.34),
                  Colors.transparent,
                  AppColors.magenta.withOpacity(0.14),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.black.withOpacity(0.2),
                  AppColors.black.withOpacity(0.86),
                  AppColors.black
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 118,
          left: 20,
          child: Container(
            width: 2,
            height: 72,
            decoration: const BoxDecoration(gradient: AppColors.actionGlow),
          ),
        ),
        Positioned(
          bottom: 36,
          left: 20,
          right: 20,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.12),
                border: Border.all(color: AppColors.cyan.withOpacity(0.75)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(series.genre.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 10,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Text(series.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0)),
            const SizedBox(height: 8),
            Text(series.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: onWatch,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.actionGlow,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.cyan.withOpacity(0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.black, size: 20),
                          SizedBox(width: 6),
                          Text('WATCH NOW',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onInfo,
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                    color: AppColors.panel.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _SignalStrip extends StatelessWidget {
  const _SignalStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          _SignalItem(value: '9:16', label: 'VERTICAL'),
          _SignalDivider(),
          _SignalItem(value: 'LOCAL', label: 'STORIES'),
          _SignalDivider(),
          _SignalItem(value: 'M-PESA', label: 'READY'),
        ],
      ),
    );
  }
}

class _SignalItem extends StatelessWidget {
  final String value;
  final String label;
  const _SignalItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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

class _SignalDivider extends StatelessWidget {
  const _SignalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: AppColors.border);
  }
}

class _CategoryTabs extends StatelessWidget {
  final String? selected;
  final Function(String?) onSelect;
  const _CategoryTabs({required this.selected, required this.onSelect});
  static const _tabs = [
    'All',
    'Drama',
    'Romance',
    'Thriller',
    'Comedy',
    'Action',
    'Horror'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _tabs.length,
        itemBuilder: (_, i) {
          final tab = _tabs[i];
          final isSelected =
              (i == 0 && selected == null) || tab.toLowerCase() == selected;
          return GestureDetector(
            onTap: () => onSelect(i == 0 ? null : tab.toLowerCase()),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cyan
                    : AppColors.panel.withOpacity(0.35),
                border: Border.all(
                    color: isSelected
                        ? AppColors.cyan
                        : Colors.white.withOpacity(0.14)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(tab,
                  style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w500,
                      letterSpacing: 0)),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0)),
          if (onSeeAll != null)
            GestureDetector(
                onTap: onSeeAll,
                child: const Text('See all',
                    style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _PosterRow extends StatelessWidget {
  final List<Series> series;
  final Function(Series) onTap;
  const _PosterRow({required this.series, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 274,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: series.length,
        itemBuilder: (_, i) {
          final s = series[i];
          return GestureDetector(
            onTap: () => onTap(s),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: s.thumbnailUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: s.thumbnailUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorWidget: (_, __, ___) => Container(
                                    color: AppColors.surface,
                                    child: const Center(
                                        child: Icon(Icons.movie_outlined,
                                            color: AppColors.textMuted))))
                            : const DecoratedBox(
                                decoration: BoxDecoration(
                                    gradient: AppColors.posterGlow),
                                child: Center(
                                    child: Icon(Icons.movie_outlined,
                                        color: AppColors.textMuted)),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(s.genre.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.42),
                            fontSize: 10,
                            letterSpacing: 0)),
                  ]),
            ),
          );
        },
      ),
    );
  }
}
