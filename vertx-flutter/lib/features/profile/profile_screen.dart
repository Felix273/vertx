// lib/features/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  User? _user;
  Map<String, dynamic>? _sub;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getMe(),
        _api.getSubscriptionStatus(),
      ]);
      setState(() {
        _user = results[0] as User;
        _sub = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _logout() async {
    await _api.clearTokens();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (_error || _user == null) {
      return Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(title: Text(l.navProfile)),
        body: VxEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Profile unavailable',
          subtitle: 'We could not load your account details.',
          action: OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('TRY AGAIN'),
          ),
        ),
      );
    }

    final hasActiveSub = _sub?['active'] == true;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(l.navProfile),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _logout,
            child:
                Text(l.signOut, style: const TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + name
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violet.withOpacity(0.2),
                  border: Border.all(color: AppColors.violet.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    (_user!.fullName.trim().isEmpty ? '?' : _user!.fullName.trim()[0]).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.violet,
                      fontFamily: 'Syne',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.fullName ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      _user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Subscription status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasActiveSub
                  ? AppColors.gold.withOpacity(0.07)
                  : AppColors.surface,
              border: Border.all(
                color: hasActiveSub
                    ? AppColors.gold.withOpacity(0.4)
                    : AppColors.border,
              ),
            ),
            child: hasActiveSub
                ? Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERTX ${(_sub!['plan'] as String).toUpperCase()}',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (_sub!['expires_at'] != null)
                              Text(
                                'Inaisha: ${_sub!['expires_at'].toString().substring(0, 10)}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Jiandikishe kupata maudhui yote / Subscribe to unlock all content',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => context.push('/paywall/any'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: const Text('JIANDIKISHE',
                            style: TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          // Language toggle
          Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border))),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: AppColors.textMuted),
              title: const Text('Lugha / Language'),
              trailing: const Text('SW | EN',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              onTap: () {},
            ),
          ),

          Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border))),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.textMuted),
              title: const Text('Malipo / Payments'),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Continue Watching screen (replaces stub in main.dart)
// ══════════════════════════════════════════════════════════════

class ContinueWatchingScreenImpl extends StatefulWidget {
  const ContinueWatchingScreenImpl({super.key});
  @override
  State<ContinueWatchingScreenImpl> createState() =>
      _ContinueWatchingScreenImplState();
}

class _ContinueWatchingScreenImplState
    extends State<ContinueWatchingScreenImpl> {
  final _api = ApiService();
  List<WatchRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api
        .getContinueWatching()
        .then((r) => setState(() {
              _records = r;
              _loading = false;
            }))
        .catchError((_) => setState(() {
              _loading = false;
            }));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(l.continueWatch),
        backgroundColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold))
          : _records.isEmpty
              ? VxEmptyState(
                  icon: Icons.play_circle_outline,
                  title: l.noContent,
                  subtitle:
                      'Maudhui uliyoanza kutazama yataonekana hapa.\nContent you start watching will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (_, i) {
                    final r = _records[i];
                    final progress = r.episodeDurationSecs > 0
                        ? r.progressSecs / r.episodeDurationSecs
                        : 0.0;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      leading: Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 54,
                            color: AppColors.surface,
                            child: r.thumbnail.isNotEmpty
                                ? Image.network(r.thumbnail, fit: BoxFit.cover)
                                : const Icon(Icons.movie,
                                    color: AppColors.textMuted),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.transparent,
                              color: AppColors.gold,
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                      title: Text(r.seriesTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        '${l.episode} ${r.episodeNum} · ${r.episodeTitle}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.play_circle_outline,
                          color: AppColors.gold),
                      onTap: () => context
                          .push('/player/${r.seriesId}?ep=${r.episodeNum - 1}'),
                    );
                  },
                ),
    );
  }
}
