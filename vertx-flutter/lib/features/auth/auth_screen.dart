// lib/features/auth/auth_screen.dart
// VERTX — Auth screen: login + register tabs

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                decoration: BoxDecoration(
                  gradient: AppColors.posterGlow,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 42,
                        height: 3,
                        decoration: const BoxDecoration(
                            gradient: AppColors.actionGlow)),
                    const SizedBox(height: 18),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                        children: [
                          TextSpan(
                              text: 'VERT',
                              style: TextStyle(color: AppColors.textPrimary)),
                          TextSpan(
                              text: 'X',
                              style: TextStyle(color: AppColors.cyan)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'VERTICAL CINEMA FOR LOCAL STORIES',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.black,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                  tabs: [
                    Tab(text: l.signIn.toUpperCase()),
                    Tab(text: l.signUp.toUpperCase())
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  height: 410,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _LoginForm(api: _api),
                      _RegisterForm(api: _api),
                    ],
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

// ── Login form ────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  final ApiService api;
  const _LoginForm({required this.api});
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await widget.api.login(_emailCtrl.text.trim(), _passCtrl.text);
      final tokens = data['access'] != null
          ? {'access': data['access'], 'refresh': data['refresh']}
          : data['tokens'] as Map<String, dynamic>;
      await widget.api
          .saveTokens(tokens['access'] as String, tokens['refresh'] as String);
      if (mounted) context.go('/home');
    } catch (_) {
      setState(() {
        _error = l.loginFailed;
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        _VxField(
            controller: _emailCtrl,
            label: l.email,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _VxField(controller: _passCtrl, label: l.password, obscure: true),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: AppColors.rose, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.black))
                : Text(l.signIn.toUpperCase()),
          ),
        ),
      ],
    );
  }
}

// ── Register form ─────────────────────────────────────────────
class _RegisterForm extends StatefulWidget {
  final ApiService api;
  const _RegisterForm({required this.api});
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_passCtrl.text != _pass2Ctrl.text) {
      setState(() {
        _error = 'Passwords do not match.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.register(
        email: _emailCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        password: _passCtrl.text,
        password2: _pass2Ctrl.text,
      );
      final tokens = data['tokens'] as Map<String, dynamic>;
      await widget.api
          .saveTokens(tokens['access'] as String, tokens['refresh'] as String);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _error = 'Registration failed. Try again.';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          _VxField(controller: _nameCtrl, label: l.fullName),
          const SizedBox(height: 14),
          _VxField(
              controller: _emailCtrl,
              label: l.email,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _VxField(controller: _passCtrl, label: l.password, obscure: true),
          const SizedBox(height: 14),
          _VxField(
              controller: _pass2Ctrl, label: l.confirmPassword, obscure: true),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppColors.rose, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.black))
                  : Text(l.signUp.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared text field ─────────────────────────────────────────
class _VxField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;

  const _VxField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(labelText: label.toUpperCase()),
      );
}
