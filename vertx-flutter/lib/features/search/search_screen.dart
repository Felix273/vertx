// lib/features/search/search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _ctrl = TextEditingController();
  Timer? _debounce;

  List<Series> _results = [];
  bool _loading = false;
  bool _searched = false;
  bool _error = false;

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _searched = true;
      _error = false;
    });
    try {
      final results = await _api.searchSeries(q.trim());
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textMuted),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() {
                        _results = [];
                        _searched = false;
                      });
                    },
                  )
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(AppLocalizations.of(context).cancel),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold))
          : _error
              ? VxEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Search unavailable',
                  subtitle: 'Check your connection and try again.',
                  action: OutlinedButton.icon(
                    onPressed: () => _search(_ctrl.text),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('TRY AGAIN'),
                  ),
                )
          : _searched && _results.isEmpty
              ? VxEmptyState(
                  icon: Icons.search_off,
                  title: 'Hakuna matokeo / No results',
                  subtitle: '"${_ctrl.text}"',
                )
              : !_searched
                  ? VxEmptyState(
                      icon: Icons.explore_outlined,
                      title: 'Find your next story',
                      subtitle: 'Search by title, genre, or creator.',
                    )
                  : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (_, i) => SeriesPosterCard(
                    series: _results[i],
                    onTap: () => context.push('/series/${_results[i].id}'),
                    width: double.infinity,
                    height: 180,
                  ),
                ),
    );
  }
}
