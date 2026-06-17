// lib/features/paywall/paywall_screen.dart
// VERTX — M-Pesa paywall
// Shows KES 99 weekly / KES 299 monthly plans + STK Push flow

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants.dart';
import '../../shared/models/models.dart';

enum _Plan { weekly, monthly }

class PaywallScreen extends StatefulWidget {
  final String seriesId;
  const PaywallScreen({super.key, required this.seriesId});
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _api = ApiService();

  Series? _series;
  bool _loadingSeries = true;
  _Plan _selectedPlan = _Plan.monthly;

  // Payment flow state
  bool _paying = false;
  bool _waiting = false; // waiting for STK PIN
  String? _phoneError;
  String? _paymentError;
  String? _paymentSuccess;

  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _api
        .getSeriesDetail(widget.seriesId)
        .then((s) => setState(() {
              _series = s;
              _loadingSeries = false;
            }))
        .catchError((_) => setState(() {
              _loadingSeries = false;
            }));
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  // Validate Kenyan phone number
  String? _validatePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 10) return null;
    if (digits.startsWith('254') && digits.length == 12) return null;
    if (digits.startsWith('7') && digits.length == 9) return null;
    return AppLocalizations.of(context).phoneInvalid;
  }

  Future<void> _subscribe() async {
    final l = AppLocalizations.of(context);
    final err = _validatePhone(_phoneCtrl.text);
    if (err != null) {
      setState(() {
        _phoneError = err;
      });
      return;
    }
    setState(() {
      _phoneError = null;
      _paying = true;
      _paymentError = null;
    });

    try {
      final planStr = _selectedPlan == _Plan.weekly ? 'weekly' : 'monthly';
      await _api.initiateSubscription(
          plan: planStr, phone: _phoneCtrl.text.trim());
      setState(() {
        _paying = false;
        _waiting = true;
      });
    } catch (e) {
      setState(() {
        _paying = false;
        _paymentError = l.paymentFailed;
      });
    }
  }

  Future<void> _purchaseSeries() async {
    final l = AppLocalizations.of(context);
    final err = _validatePhone(_phoneCtrl.text);
    if (err != null) {
      setState(() {
        _phoneError = err;
      });
      return;
    }
    setState(() {
      _phoneError = null;
      _paying = true;
      _paymentError = null;
    });

    try {
      await _api.purchaseSeries(
        seriesId: widget.seriesId,
        phone: _phoneCtrl.text.trim(),
      );
      setState(() {
        _paying = false;
        _waiting = true;
      });
    } catch (e) {
      final msg = e.toString().contains('already own')
          ? l.alreadyOwns
          : l.paymentFailed;
      setState(() {
        _paying = false;
        _paymentError = msg;
      });
    }
  }

  void _onPaymentConfirmed() {
    // Navigate back to series detail to recheck access
    context.pushReplacement('/series/${widget.seriesId}');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_waiting) return _WaitingScreen(l: l, onDone: _onPaymentConfirmed);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 3,
                decoration: const BoxDecoration(gradient: AppColors.actionGlow),
              ),
              const SizedBox(height: 16),
              Text(l.unlockContent,
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 6),
              if (_series != null)
                Text(
                  _series!.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.gold),
                ),

              const SizedBox(height: 32),

              // ── Plan selector ───────────────────────────
              Text(
                l.subscribeNow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 12),

              _PlanCard(
                plan: _Plan.weekly,
                selected: _selectedPlan == _Plan.weekly,
                label: l.weeklyPlan,
                price: AppConstants.weeklyPriceKes,
                perUnit: '/ wiki',
                onTap: () => setState(() => _selectedPlan = _Plan.weekly),
              ),
              const SizedBox(height: 8),
              _PlanCard(
                plan: _Plan.monthly,
                selected: _selectedPlan == _Plan.monthly,
                label: l.monthlyPlan,
                price: AppConstants.monthlyPriceKes,
                perUnit: '/ mwezi',
                badge: 'SAVE 25%',
                onTap: () => setState(() => _selectedPlan = _Plan.monthly),
              ),

              const SizedBox(height: 28),

              // ── Phone input ─────────────────────────────
              Text(
                l.enterPhone.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('+254',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14)),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: InputDecoration(hintText: l.phoneHint),
                      onChanged: (_) => setState(() => _phoneError = null),
                    ),
                  ),
                ],
              ),
              if (_phoneError != null) ...[
                const SizedBox(height: 6),
                Text(_phoneError!,
                    style:
                        const TextStyle(color: AppColors.rose, fontSize: 12)),
              ],

              const SizedBox(height: 24),

              // ── Subscribe CTA ───────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _paying ? null : _subscribe,
                  icon: _paying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.black))
                      : const Icon(Icons.phone_android, size: 18),
                  label: Text(l.payWithMpesa.toUpperCase()),
                ),
              ),

              // ── Buy series option ───────────────────────
              if (_series?.isPurchasable == true) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    l.orBuyOnce,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _paying ? null : _purchaseSeries,
                    child: Text(
                      'KES ${_series!.price} — ${_series!.title}'.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],

              if (_paymentError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppColors.rose.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.rose, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_paymentError!,
                            style: const TextStyle(
                                color: AppColors.rose, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── What you get ────────────────────────────
              _PerksSection(l: l),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool selected;
  final String label;
  final int price;
  final String perUnit;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.label,
    required this.price,
    required this.perUnit,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withOpacity(0.08) : AppColors.card,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.cyan.withOpacity(0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10))
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.gold : AppColors.border,
                  width: selected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    'Upatikanaji wote / All content access',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.textPrimary),
                    children: [
                      TextSpan(
                        text: 'KES $price',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color:
                              selected ? AppColors.gold : AppColors.textPrimary,
                          fontFamily: 'Syne',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(perUnit,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),

            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.actionGlow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Waiting for STK PIN ───────────────────────────────────────
class _WaitingScreen extends StatelessWidget {
  final AppLocalizations l;
  final VoidCallback onDone;

  const _WaitingScreen({required this.l, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing M-Pesa icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.1),
                duration: const Duration(milliseconds: 800),
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    border:
                        Border.all(color: const Color(0xFF4CAF50), width: 2),
                  ),
                  child: const Center(
                    child: Text('M',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4CAF50),
                          fontFamily: 'Syne',
                        )),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l.payWithMpesa.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.mpesaPrompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Ingiza PIN yako ya M-Pesa kwenye simu yako.\nEnter your M-Pesa PIN on your phone.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: AppColors.gold),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: onDone,
                child: Text('Nimemaliza / I\'ve paid'.toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Perks list ────────────────────────────────────────────────
class _PerksSection extends StatelessWidget {
  final AppLocalizations l;
  const _PerksSection({required this.l});

  static const _perks = [
    ('Vipindi vyote bila kikomo', 'Unlimited episodes'),
    ('Sauti ya hali ya juu', 'High quality audio & video'),
    ('Tazama wakati wowote', 'Watch anytime, anywhere'),
    ('Ghairi wakati wowote', 'Cancel anytime'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            width: 24,
            height: 2,
            decoration: const BoxDecoration(gradient: AppColors.actionGlow)),
        const SizedBox(height: 12),
        ..._perks.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, color: AppColors.gold, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        children: [
                          TextSpan(text: p.$1),
                          const TextSpan(text: ' / '),
                          TextSpan(
                              text: p.$2,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
