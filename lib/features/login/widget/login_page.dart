import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/util/responsive.dart';
import '../bloc/login_bloc.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF07091A);
const _kSurface = Color(0xFF0D1527);
const _kBlue    = Color(0xFF1B8EF8);
const _kTeal    = Color(0xFF00E5CC);
const _kPurple  = Color(0xFF9B8EF8);
const _kBorder  = Color(0xFF1B2645);
const _kTextSec = Color(0xFF7A8CAA);
const _kError   = Color(0xFFFF4D6A);
const _kSuccess = Color(0xFF00D68F);
const _kWarning = Color(0xFFFFB347);

// ─── Entry Point ──────────────────────────────────────────────────────────────

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: const _LoginView(),
    );
  }
}

// ─── Stateful View ────────────────────────────────────────────────────────────

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> with TickerProviderStateMixin {
  final _usernameCtrl    = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _passwordVisible = ValueNotifier<bool>(false);
  final _rememberMe      = ValueNotifier<bool>(false);
  final _pwStrength      = ValueNotifier<int>(0);
  final _pwError         = ValueNotifier<String?>('');

  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _logoFade;
  late final Animation<Offset>  _logoSlide;
  late final Animation<double> _panelFade;
  late final Animation<Offset>  _panelSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset>  _formSlide;
  late final Animation<double> _socialFade;
  late final Animation<double> _pulse1;
  late final Animation<double> _pulse2;

  @override
  void initState() {
    super.initState();

    // ── Entrance (1.2 s staggered) ──
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.00, 0.50, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.00, 0.50, curve: Curves.easeOutCubic),
    ));

    _panelFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOut),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOutCubic),
    ));

    _formFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.80, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.80, curve: Curves.easeOutCubic),
    ));

    _socialFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.55, 1.00, curve: Curves.easeOut),
    );

    // ── Ambient pulse (4 s loop) ──
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulse1 = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _pulse2 = CurvedAnimation(
      parent: _pulseCtrl,
      curve: const Interval(0.30, 1.0, curve: Curves.easeInOut),
    );

    _passwordCtrl.addListener(() {
      final pw = _passwordCtrl.text;
      _pwStrength.value = _computeStrength(pw);
      _pwError.value    = _validatePassword(pw);
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordVisible.dispose();
    _rememberMe.dispose();
    _pwStrength.dispose();
    _pwError.dispose();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  int _computeStrength(String pw) {
    if (pw.isEmpty) return 0;
    int s = 0;
    if (pw.length >= 6) s++;
    if (pw.contains(RegExp(r'[A-Z]'))) s++;
    if (pw.contains(RegExp(r'[0-9]'))) s++;
    if (pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`\[\]\\;/]'))) s++;
    return s;
  }

  String? _validatePassword(String pw) {
    if (pw.isEmpty) return null;
    if (pw.length < 6) return 'At least 6 characters';
    if (!pw.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
    if (!pw.contains(RegExp(r'[a-z]'))) return 'Add a lowercase letter';
    if (!pw.contains(RegExp(r'[0-9]'))) return 'Add a number';
    if (!pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`\[\]\\;/]'))) {
      return 'Add a special character';
    }
    return null;
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    final err = _validatePassword(_passwordCtrl.text);
    if (err != null) {
      _pwError.value = err;
      return;
    }
    context.read<LoginBloc>().add(LoginSubmitted(
      username: _usernameCtrl.text,
      password: _passwordCtrl.text,
    ));
  }

  // ─── Root Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            context.go('/face-id');
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(_errorSnack(state.message));
          }
        },
        child: Scaffold(
          backgroundColor: _kBg,
          resizeToAvoidBottomInset: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1 — grid
              const CustomPaint(painter: _DuonetMapPainter()),
              // Layer 2 — animated ambient glows
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) => _AmbientGlow(p1: _pulse1.value, p2: _pulse2.value),
              ),
              // Layer 3 — content
              SafeArea(
                child: context.isLandscape
                    ? _buildLandscape(context)
                    : _buildPortrait(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PORTRAIT LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPortrait(BuildContext context) {
    final isTablet = context.isTablet;
    final safeH    = context.screenHeight
        - MediaQuery.of(context).padding.top
        - MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: safeH,
            maxWidth: isTablet ? 560.0 : double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 48.0 : 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: isTablet ? 64.0 : 52.0),

                // ── Logo block ──
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: _LogoBlock(isTablet: isTablet),
                  ),
                ),
                SizedBox(height: isTablet ? 44.0 : 32.0),

                // ── Form card ──
                SlideTransition(
                  position: _formSlide,
                  child: FadeTransition(
                    opacity: _formFade,
                    child: _buildFormCard(context, isTablet: isTablet),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Social section ──
                FadeTransition(
                  opacity: _socialFade,
                  child: _buildSocialSection(),
                ),
                const SizedBox(height: 28),

                // ── Footer ──
                FadeTransition(opacity: _socialFade, child: _buildFooter()),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LANDSCAPE LAYOUT  — Slack-style split panel
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLandscape(BuildContext context) {
    final isTablet = context.isTablet;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: Brand panel ──────────────────────────────────────────────
        Expanded(
          flex: isTablet ? 45 : 40,
          child: SlideTransition(
            position: _panelSlide,
            child: FadeTransition(
              opacity: _panelFade,
              child: _BrandPanel(isTablet: isTablet),
            ),
          ),
        ),

        // ── Divider ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: VerticalDivider(
            color: _kBlue.withOpacity(0.10),
            width: 1,
            thickness: 1,
          ),
        ),

        // ── Right: Form panel ─────────────────────────────────────────────
        Expanded(
          flex: isTablet ? 55 : 60,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40.0 : 28.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SlideTransition(
                  position: _formSlide,
                  child: FadeTransition(
                    opacity: _formFade,
                    child: _buildFormCard(context, compact: true),
                  ),
                ),
                const SizedBox(height: 14),
                FadeTransition(
                  opacity: _socialFade,
                  child: _buildSocialSection(compact: true),
                ),
                const SizedBox(height: 12),
                FadeTransition(opacity: _socialFade, child: _buildFooter(compact: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FORM CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFormCard(
    BuildContext context, {
    bool isTablet = false,
    bool compact  = false,
  }) {
    final p = compact ? 18.0 : (isTablet ? 32.0 : 26.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.all(p),
          decoration: BoxDecoration(
            color: _kSurface.withOpacity(0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBlue.withOpacity(0.14), width: 1),
            boxShadow: [
              BoxShadow(color: _kBlue.withOpacity(0.04), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Heading ──
              if (!compact) ...[
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to your DUONET account',
                  style: TextStyle(color: _kTextSec, fontSize: 13),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Username ──
              _DuonetTextField(
                controller: _usernameCtrl,
                label: 'Username or Email',
                icon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 12),

              // ── Password ──
              ValueListenableBuilder<bool>(
                valueListenable: _passwordVisible,
                builder: (ctx, visible, child) => _DuonetTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !visible,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(context),
                  suffixIcon: IconButton(
                    onPressed: () => _passwordVisible.value = !visible,
                    icon: Icon(
                      visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white30,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // ── Strength bar + hint ──
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: _pwStrength,
                builder: (ctx, s, child) => _PasswordStrengthBar(strength: s),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: _pwError,
                builder: (ctx, err, child) {
                  if (err == null && _passwordCtrl.text.isNotEmpty) {
                    return _inlineHint(
                        Icons.verified_outlined, 'Strong password', _kSuccess);
                  }
                  if (err != null && err.isNotEmpty) {
                    return _inlineHint(
                        Icons.info_outline_rounded, err, _kWarning);
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 14),

              // ── Remember me + Forgot password ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _rememberMe,
                    builder: (ctx, val, child) => _AnimatedCheckbox(
                      value: val,
                      label: 'Remember me',
                      onTap: () => _rememberMe.value = !val,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: _kBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: compact ? 16 : 20),

              // ── Sign in button ──
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  final loading = state is LoginLoading;
                  return _SignInButton(
                    isLoading: loading,
                    onTap: loading ? null : () => _submit(context),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Social Section ─────────────────────────────────────────────────────────

  Widget _buildSocialSection({bool compact = false}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                  color: _kBorder.withOpacity(0.55), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or continue with',
                style: TextStyle(
                    color: _kTextSec, fontSize: 11, letterSpacing: 0.4),
              ),
            ),
            Expanded(
              child: Divider(
                  color: _kBorder.withOpacity(0.55), thickness: 1),
            ),
          ],
        ),
        SizedBox(height: compact ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                icon: const _GoogleBadge(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SocialButton(
                label: 'Apple',
                icon: const Icon(Icons.apple, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SocialButton(
                label: 'SSO',
                icon: const Icon(
                  Icons.business_center_outlined,
                  color: _kBlue,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter({bool compact = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusDot(color: _kTeal, label: 'System Online'),
            const SizedBox(width: 18),
            _StatusDot(color: _kBlue, label: 'Secure TLS'),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 12),
          Text(
            '© 2025 DUONET — Smart Mobility Platform',
            style: TextStyle(
              color: Colors.white.withOpacity(0.18),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Small helpers ──────────────────────────────────────────────────────────

  Widget _inlineHint(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  SnackBar _errorSnack(String msg) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E2340),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kError, width: 1),
      ),
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _kError, size: 18),
          const SizedBox(width: 10),
          Text(msg, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LOGO BLOCK
// ═══════════════════════════════════════════════════════════════════════════════

class _LogoBlock extends StatelessWidget {
  const _LogoBlock({this.isTablet = false, this.compact = false});

  final bool isTablet;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final outerD  = compact ? 64.0 : (isTablet ? 100.0 : 84.0);
    final innerD  = outerD * 0.77;
    final nameSz  = compact ? 26.0 : (isTablet ? 42.0 : 36.0);
    final spacing = compact ? 8.0  : 10.0;
    final align   = compact ? CrossAxisAlignment.start : CrossAxisAlignment.center;

    return Column(
      crossAxisAlignment: align,
      children: [
        // ── Icon ──
        SizedBox(
          width: outerD, height: outerD,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: outerD, height: outerD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _kBlue.withOpacity(0.22), width: 1),
                ),
              ),
              Container(
                width: innerD, height: innerD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kBlue, _kTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withOpacity(0.50),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _kTeal.withOpacity(0.20),
                      blurRadius: 52,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.route_rounded,
                        color: Colors.white, size: 28),
                    Positioned(
                      right: 11, top: 11,
                      child: Container(
                        width: 9, height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 14 : 20),

        // ── Wordmark ──
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Colors.white, Color(0xFFB8D4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(b),
          child: Text(
            'DUONET',
            style: TextStyle(
              color: Colors.white,
              fontSize: nameSz,
              fontWeight: FontWeight.w900,
              letterSpacing: spacing,
            ),
          ),
        ),

        if (!compact) ...[
          const SizedBox(height: 6),
          Text(
            'Smart Mobility Platform',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kTextSec,
              fontSize: isTablet ? 13 : 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          // ── Feature chips ──
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: const [
              _Chip(icon: Icons.map_outlined,              label: 'MAPS'),
              _Chip(icon: Icons.directions_car_outlined,   label: 'FLEET'),
              _Chip(icon: Icons.groups_outlined,           label: 'WORKFORCE'),
            ],
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BRAND PANEL  (landscape left column — Slack-style)
// ═══════════════════════════════════════════════════════════════════════════════

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.isTablet = false});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40.0 : 28.0,
        vertical: 24.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogoBlock(compact: true),
          const SizedBox(height: 32),
          _buildFeatureList(),
          const SizedBox(height: 24),
          _buildTrustBadge(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    const features = [
      (_kBlue,   Icons.map_outlined,             'Smart Maps',       'Real-time routing & location intelligence'),
      (_kTeal,   Icons.directions_car_outlined,   'Fleet Management', 'Track & optimize your entire fleet'),
      (_kPurple, Icons.groups_outlined,            'Workforce',        'Coordinate teams across locations'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map<Widget>((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: f.$1.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: f.$1.withOpacity(0.22), width: 1),
                ),
                child: Icon(f.$2, color: f.$1, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.$3,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.$4,
                      style: const TextStyle(
                          color: _kTextSec, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrustBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _kSuccess.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kSuccess.withOpacity(0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: _kSuccess,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _kSuccess.withOpacity(0.7), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'All systems operational',
            style: TextStyle(
              color: _kSuccess,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PASSWORD STRENGTH BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final int strength; // 0–4

  static const _colors = [
    Colors.transparent,
    _kError,
    _kWarning,
    Color(0xFFFFE566),
    _kSuccess,
  ];
  static const _labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();

    final color = _colors[strength];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < strength
                    ? color
                    : Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text(
          _labels[strength],
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SIGN IN BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _SignInButton extends StatefulWidget {
  const _SignInButton({required this.isLoading, this.onTap});
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isLoading
                  ? [_kBlue.withOpacity(0.45), _kTeal.withOpacity(0.45)]
                  : const [_kBlue, _kTeal],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: _kBlue.withOpacity(0.42),
                      blurRadius: 22,
                      offset: const Offset(0, 7),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'SIGN IN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SOCIAL LOGIN BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _SocialButton extends StatefulWidget {
  const _SocialButton({required this.label, required this.icon});
  final String label;
  final Widget icon;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withOpacity(0.09)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? _kBlue.withOpacity(0.35)
                  : _kBorder.withOpacity(0.55),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Google Badge ─────────────────────────────────────────────────────────────

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF0F9D58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ANIMATED CHECKBOX  (Remember me)
// ═══════════════════════════════════════════════════════════════════════════════

class _AnimatedCheckbox extends StatelessWidget {
  const _AnimatedCheckbox({
    required this.value,
    required this.label,
    required this.onTap,
  });
  final bool   value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: _kBlue.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 17, height: 17,
              decoration: BoxDecoration(
                color: value ? _kBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: value ? _kBlue : _kBlue.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 11)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: _kTextSec, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STATUS DOT
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});
  final Color  color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.65), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.30),
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CHIP  (feature tag)
// ═══════════════════════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kBlue.withOpacity(0.09),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBlue.withOpacity(0.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _kTeal),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _kTeal,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FOCUSED TEXT FIELD
// ═══════════════════════════════════════════════════════════════════════════════

class _DuonetTextField extends StatefulWidget {
  const _DuonetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText       = false,
    this.suffixIcon,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String                 label;
  final IconData               icon;
  final bool                   obscureText;
  final Widget?                suffixIcon;
  final ValueChanged<String>?  onSubmitted;
  final TextInputAction?       textInputAction;

  @override
  State<_DuonetTextField> createState() => _DuonetTextFieldState();
}

class _DuonetTextFieldState extends State<_DuonetTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused
            ? _kBlue.withOpacity(0.07)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? _kBlue.withOpacity(0.55)
              : _kBorder.withOpacity(0.60),
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: _kBlue.withOpacity(0.10), blurRadius: 10)]
            : [],
      ),
      child: TextField(
        controller:       widget.controller,
        focusNode:        _focus,
        obscureText:      widget.obscureText,
        onSubmitted:      widget.onSubmitted,
        textInputAction:  widget.textInputAction,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: _kBlue,
        decoration: InputDecoration(
          labelText:           widget.label,
          labelStyle:          TextStyle(
              color: Colors.white.withOpacity(0.35), fontSize: 14),
          floatingLabelStyle:  const TextStyle(color: _kBlue, fontSize: 12),
          prefixIcon:          Icon(
            widget.icon,
            color: _focused ? _kBlue : _kBlue.withOpacity(0.50),
            size: 19,
          ),
          suffixIcon:          widget.suffixIcon,
          border:              InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AMBIENT GLOW  (pulsing radial gradients)
// ═══════════════════════════════════════════════════════════════════════════════

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.p1, required this.p2});
  final double p1; // 0..1
  final double p2; // 0..1

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left blue orb
        Positioned(
          top:  -120 + p1 * 30,
          left: -90,
          child: Container(
            width:  420 + p1 * 50,
            height: 420 + p1 * 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _kBlue.withOpacity(0.10 + p1 * 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom-right teal orb
        Positioned(
          bottom: 30 + p2 * 25,
          right:  -110,
          child: Container(
            width:  340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _kTeal.withOpacity(0.07 + p2 * 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Top-right purple accent
        Positioned(
          top:   MediaQuery.sizeOf(context).height * 0.20,
          right: -60,
          child: Container(
            width:  200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _kPurple.withOpacity(0.05 + (1 - p1) * 0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND GRID + MAP PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _DuonetMapPainter extends CustomPainter {
  const _DuonetMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // ── Fine grid ──
    final gridPaint = Paint()
      ..color       = _kBlue.withOpacity(0.048)
      ..strokeWidth = 0.5;

    const step = 38.0;
    for (double x = 0; x < size.width;  x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── Route curves ──
    final routePaint = Paint()
      ..color       = _kBlue.withOpacity(0.09)
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.28)
        ..quadraticBezierTo(
            size.width * 0.35, size.height * 0.42,
            size.width,        size.height * 0.18),
      routePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.15, size.height)
        ..quadraticBezierTo(
            size.width * 0.50, size.height * 0.72,
            size.width * 0.85, size.height * 0.35),
      routePaint,
    );
    // Subtle tertiary route
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.60, 0)
        ..quadraticBezierTo(
            size.width * 0.75, size.height * 0.30,
            size.width,        size.height * 0.55),
      routePaint..color = _kTeal.withOpacity(0.06),
    );

    // ── Location dots ──
    final rng     = math.Random(42);
    final dotFill = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final pos   = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      final color = i.isEven ? _kBlue : _kTeal;
      canvas.drawCircle(pos, 9, Paint()..color = color.withOpacity(0.06));
      dotFill.color = color.withOpacity(0.40);
      canvas.drawCircle(pos, 2.5, dotFill);
    }

    // ── Map markers (triangles) ──
    final markerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _kTeal.withOpacity(0.28);

    for (final pos in [
      Offset(size.width * 0.22, size.height * 0.35),
      Offset(size.width * 0.68, size.height * 0.55),
      Offset(size.width * 0.48, size.height * 0.78),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(pos.dx,     pos.dy - 6)
          ..lineTo(pos.dx - 4, pos.dy + 4)
          ..lineTo(pos.dx + 4, pos.dy + 4)
          ..close(),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DuonetMapPainter _) => false;
}
