// lib/features/player/player_screen.dart
// VERTX — Vertical swipe episode player using media_kit (HLS on all platforms)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants.dart';
import '../../shared/models/models.dart';

class PlayerScreen extends StatefulWidget {
  final String seriesId;
  final int startEpisodeIdx;
  const PlayerScreen({
    super.key,
    required this.seriesId,
    this.startEpisodeIdx = 0,
  });
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _api = ApiService();
  late PageController _pageCtrl;

  List<Episode> _episodes = [];
  int _currentIdx = 0;
  bool _loading = true;
  String? _error;

  final Map<int, Player> _players = {};
  final Map<int, VideoController> _controllers = {};
  Timer? _progressTimer;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _currentIdx = widget.startEpisodeIdx;
    _pageCtrl = PageController(initialPage: widget.startEpisodeIdx);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadEpisodes();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _progressTimer?.cancel();
    _hideControlsTimer?.cancel();
    for (final s in _subs) s.cancel();
    for (final p in _players.values) p.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodes() async {
    try {
      final series = await _api.getSeriesDetail(widget.seriesId);
      setState(() {
        _episodes = series.episodes;
        _loading = false;
      });
      if (_episodes.isNotEmpty) {
        await _initPlayer(_currentIdx);
        _startProgressTimer();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _initPlayer(int idx) async {
    if (_players.containsKey(idx)) return;
    if (idx < 0 || idx >= _episodes.length) return;
    final ep = _episodes[idx];
    try {
      final data = await _api.getStreamUrl(ep.id);
      final url = data['video_url'] as String;
      final player = Player();
      final controller = VideoController(player);
      _players[idx] = player;
      _controllers[idx] = controller;
      await player.open(Media(url), play: false);
      if (mounted && idx == _currentIdx) {
        player.play();
        _subs.add(player.stream.position.listen((p) {
          if (mounted && idx == _currentIdx) setState(() => _position = p);
        }));
        _subs.add(player.stream.duration.listen((d) {
          if (mounted && idx == _currentIdx) setState(() => _duration = d);
        }));
        _subs.add(player.stream.playing.listen((v) {
          if (mounted && idx == _currentIdx) setState(() => _isPlaying = v);
        }));
        _subs.add(player.stream.completed.listen((c) {
          if (c && mounted) _onEpisodeComplete(idx);
        }));
      }
      setState(() {});
      if (idx + 1 < _episodes.length) _initPlayer(idx + 1);
    } catch (e) {
      if (mounted && e.toString().contains('403')) {
        context.pushReplacement('/paywall/${widget.seriesId}');
      }
    }
  }

  void _onEpisodeComplete(int idx) {
    _saveProgress(idx, completed: true);
    if (idx + 1 < _episodes.length) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted)
          _pageCtrl.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut);
      });
    }
  }

  void _onPageChanged(int idx) {
    _players[_currentIdx]?.pause();
    _saveProgress(_currentIdx);
    setState(() {
      _currentIdx = idx;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
    });
    final player = _players[idx];
    if (player != null) {
      player.play();
    } else {
      _initPlayer(idx);
    }
    _showControlsTemp();
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(
        AppConstants.progressSaveInterval, (_) => _saveProgress(_currentIdx));
  }

  Future<void> _saveProgress(int idx, {bool completed = false}) async {
    if (idx >= _episodes.length) return;
    final player = _players[idx];
    if (player == null) return;
    try {
      await _api.saveProgress(
          _episodes[idx].id, player.state.position.inSeconds,
          completed: completed);
    } catch (_) {}
  }

  void _togglePlayPause() {
    final player = _players[_currentIdx];
    if (player == null) return;
    player.state.playing ? player.pause() : player.play();
    _showControlsTemp();
  }

  void _showControlsTemp() {
    setState(() => _showControls = true);
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading)
      return const Scaffold(
          backgroundColor: AppColors.black,
          body:
              Center(child: CircularProgressIndicator(color: AppColors.gold)));
    if (_error != null || _episodes.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.rose, size: 48),
          const SizedBox(height: 16),
          Text(_error ?? l.noContent,
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back',
                  style: TextStyle(color: AppColors.gold))),
        ])),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.black,
      body: GestureDetector(
        onTap: _showControlsTemp,
        child: Stack(children: [
          PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            itemCount: _episodes.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, idx) {
              final ctrl = _controllers[idx];
              if (ctrl == null)
                return Container(
                    color: AppColors.black,
                    child: const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.gold)));
              return Video(
                  controller: ctrl,
                  fill: AppColors.black,
                  controls: NoVideoControls);
            },
          ),
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: AppConstants.animNormal,
            child: _OverlayControls(
              episode: _episodes[_currentIdx],
              position: _position,
              duration: _duration,
              isPlaying: _isPlaying,
              idx: _currentIdx,
              total: _episodes.length,
              onBack: () => context.pop(),
              onPlayPause: _togglePlayPause,
              l: l,
            ),
          ),
          if (_currentIdx == 0 && _episodes.length > 1)
            _SwipeHint(text: l.swipeNext),
        ]),
      ),
    );
  }
}

class _OverlayControls extends StatelessWidget {
  final Episode episode;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final int idx;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final AppLocalizations l;
  const _OverlayControls(
      {required this.episode,
      required this.position,
      required this.duration,
      required this.isPlaying,
      required this.idx,
      required this.total,
      required this.onBack,
      required this.onPlayPause,
      required this.l});

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    return Stack(children: [
      Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 12),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.black, Colors.transparent])),
            child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                  onPressed: onBack),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(episode.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('${l.episode} ${episode.episodeNumber} / $total',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ])),
            ]),
          )),
      Center(
          child: GestureDetector(
              onTap: onPlayPause,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.black.withOpacity(0.6),
                    border: Border.all(color: Colors.white.withOpacity(0.3))),
                child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white, size: 32),
              ))),
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                top: 20),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.black, Colors.transparent])),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (episode.description.isNotEmpty)
                Text(episode.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: AppColors.gold,
                  minHeight: 2),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_fmt(position),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
                Text(_fmt(duration),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ]),
            ]),
          )),
      Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                total.clamp(0, 8),
                (i) => Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == idx
                              ? AppColors.gold
                              : Colors.white.withOpacity(0.3)),
                    )),
          ))),
    ]);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SwipeHint extends StatefulWidget {
  final String text;
  const _SwipeHint({required this.text});
  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, _anim.value), child: child),
        child: Column(children: [
          const Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 28),
          Text(widget.text,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ),
    );
  }
}
