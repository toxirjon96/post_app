import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/util/responsive.dart';
import '../bloc/login_bloc.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────

const _kBg       = Color(0xFF060A18); // deepest bg
const _kField    = Color(0xFF111E36); // input field fill
const _kBlue     = Color(0xFF2E9BFF); // primary accent
const _kTeal     = Color(0xFF00DFC4); // secondary accent
const _kPurple   = Color(0xFF8B7CF8); // tertiary accent
const _kBorder   = Color(0xFF1C2A44); // idle border
const _kText     = Color(0xFFECF0FA); // primary text
const _kTextSec  = Color(0xFF6B7FA0); // secondary text
const _kHint     = Color(0xFF415070); // hint / placeholder
const _kError    = Color(0xFFFF4D6A); // error
const _kSuccess  = Color(0xFF00D18C); // success
const _kWarning  = Color(0xFFFFAA2E); // warning

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

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.00, 0.50, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.28),
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
      begin: const Offset(-0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOutCubic),
    ));

    _formFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.28, 0.82, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.28, 0.82, curve: Curves.easeOutCubic),
    ));

    _socialFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.55, 1.00, curve: Curves.easeOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            context.go('/home/posts');
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(_buildErrorSnack(context, state.message));
          }
        },
        child: Scaffold(
          backgroundColor: _kBg,
          resizeToAvoidBottomInset: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _GridPainter()),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (ctx, child) =>
                    _GlowLayer(p1: _pulse1.value, p2: _pulse2.value),
              ),
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
  //  PORTRAIT
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
            padding: EdgeInsets.symmetric(
                horizontal: context.dp(isTablet ? 44 : 22)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: context.dp(isTablet ? 60 : 48)),
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: _LogoBlock(isTablet: isTablet),
                  ),
                ),
                SizedBox(height: context.dp(isTablet ? 40 : 28)),
                SlideTransition(
                  position: _formSlide,
                  child: FadeTransition(
                    opacity: _formFade,
                    child: _buildFormCard(context, isTablet: isTablet),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _socialFade,
                  child: _SocialSection(),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                    opacity: _socialFade, child: _buildFooter()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LANDSCAPE  — visual identity panel | form panel
  //  Inspired by: Linear, Vercel, Stripe, Airbnb, Slack
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLandscape(BuildContext context) {
    final isTablet     = context.isTablet;
    final w            = context.screenWidth;
    // When the keyboard is open on a phone the available height drops to
    // ~100-160 px, which overflows the brand-panel Column (~260 px).
    // Collapsing the panel gives the form ScrollView the full width.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 50;
    final showPanel    = isTablet || !keyboardOpen;

    // Proportions: phone 40/60, tablet 42/58
    final leftW = w * (isTablet ? 0.42 : 0.40);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: Visual identity panel ──────────────────────────────────
        // AnimatedContainer animates the width to 0 when the keyboard opens.
        // ClipRect prevents any paint overflow during the transition.
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          width: showPanel ? leftW : 0,
          child: ClipRect(
            child: showPanel
                ? SlideTransition(
                    position: _panelSlide,
                    child: FadeTransition(
                      opacity: _panelFade,
                      child: _LandscapeBrandPanel(isTablet: isTablet),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // ── Right: Form panel ─────────────────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: showPanel
                    ? const BorderSide(color: _kBorder, width: 1)
                    : BorderSide.none,
              ),
            ),
            child: SingleChildScrollView(
              // ClampingScrollPhysics ensures the focused field always
              // scrolls into view above the keyboard on both platforms.
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: context.dp(isTablet ? 40 : 28),
                vertical:   context.dp(isTablet ? 22 : 14),
              ),
              child: SlideTransition(
                position: _formSlide,
                child: FadeTransition(
                  opacity: _formFade,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 520 : double.infinity,
                      ),
                      child: _buildLandscapeForm(context, isTablet: isTablet),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Landscape-optimised form (no card wrapper, tighter rhythm) ────────────
  Widget _buildLandscapeForm(BuildContext context, {bool isTablet = false}) {
    final lh  = context.screenHeight;
    final gap = lh < 480
        ? context.dp(7)
        : lh < 600
            ? context.dp(isTablet ? 10 : 8)
            : context.dp(isTablet ? 14 : 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Heading + live status chip ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      color: _kText,
                      fontSize: context.sp(isTablet ? 22 : 18),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign in to your DUONET account',
                    style: TextStyle(
                      color: _kTextSec,
                      fontSize: context.sp(11.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Live status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _kSuccess.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _kSuccess.withValues(alpha: 0.20), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: _kSuccess,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _kSuccess.withValues(alpha: 0.70),
                            blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: _kSuccess,
                      fontSize: context.sp(10),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: gap + 4),

        // ── Username ──
        _DuonetTextField(
          controller: _usernameCtrl,
          label: 'Username or Email',
          icon: Icons.alternate_email_rounded,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        SizedBox(height: gap),

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
            suffixIcon: GestureDetector(
              onTap: () => _passwordVisible.value = !visible,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _kHint,
                  size: 19,
                ),
              ),
            ),
          ),
        ),

        // ── Strength bar ──
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: _pwStrength,
          builder: (ctx, s, child) => _PasswordStrengthBar(strength: s),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _pwError,
          builder: (ctx, err, child) {
            if (err == null && _passwordCtrl.text.isNotEmpty) {
              return _hint(Icons.verified_rounded, 'Strong password', _kSuccess);
            }
            if (err != null && err.isNotEmpty) {
              return _hint(Icons.info_outline_rounded, err, _kWarning);
            }
            return const SizedBox.shrink();
          },
        ),

        SizedBox(height: gap),

        // ── Remember me + Forgot ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _rememberMe,
              builder: (ctx, val, child) => _AnimCheckbox(
                value: val,
                label: 'Remember me',
                onTap: () => _rememberMe.value = !val,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: _kBlue,
                  fontSize: context.sp(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: gap + 2),

        // ── Sign in button ──
        BlocBuilder<LoginBloc, LoginState>(
          builder: (ctx, state) {
            final loading = state is LoginLoading;
            return _SignInButton(
              isLoading: loading,
              onTap: loading ? null : () => _submit(context),
            );
          },
        ),

        const SizedBox(height: 14),
        FadeTransition(
            opacity: _socialFade,
            child: _SocialSection(compact: true)),
        const SizedBox(height: 10),
        FadeTransition(
            opacity: _socialFade,
            child: _buildFooter(compact: true)),
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
    final p = compact ? context.dp(14) : context.dp(isTablet ? 30 : 22);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(p),
          decoration: BoxDecoration(
            // Two-stop gradient: top slightly lighter, bottom darker
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F1830).withValues(alpha: 0.95),
                const Color(0xFF090E1E).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact) ...[
                Text(
                  'Welcome back',
                  style: TextStyle(
                    color: _kText,
                    fontSize: context.sp(22),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to your DUONET account',
                  style: TextStyle(
                    color: _kTextSec,
                    fontSize: context.sp(13),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
              ] else ...[
                Text(
                  'Sign in',
                  style: TextStyle(
                    color: _kText,
                    fontSize: context.sp(17),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Username ──
              _DuonetTextField(
                controller: _usernameCtrl,
                label: 'Username or Email',
                icon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              SizedBox(height: compact ? 10 : 12),

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
                  suffixIcon: GestureDetector(
                    onTap: () => _passwordVisible.value = !visible,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(
                        visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _kHint,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Strength bar ──
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: _pwStrength,
                builder: (ctx, s, child) =>
                    _PasswordStrengthBar(strength: s),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: _pwError,
                builder: (ctx, err, child) {
                  if (err == null && _passwordCtrl.text.isNotEmpty) {
                    return _hint(Icons.verified_rounded,
                        'Strong password', _kSuccess);
                  }
                  if (err != null && err.isNotEmpty) {
                    return _hint(Icons.info_outline_rounded, err, _kWarning);
                  }
                  return const SizedBox.shrink();
                },
              ),

              SizedBox(height: compact ? 10 : 14),

              // ── Remember me + Forgot password ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _rememberMe,
                    builder: (ctx, val, child) => _AnimCheckbox(
                      value: val,
                      label: 'Remember me',
                      onTap: () => _rememberMe.value = !val,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: _kBlue,
                        fontSize: context.sp(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: compact ? 14 : 18),

              // ── Sign in button ──
              BlocBuilder<LoginBloc, LoginState>(
                builder: (ctx, state) {
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

  // ─── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter({bool compact = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusPill(color: _kTeal, label: 'System Online'),
            const SizedBox(width: 14),
            _StatusPill(color: _kBlue, label: 'Secure TLS'),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 10),
          Text(
            '© 2025 DUONET — Smart Mobility Platform',
            style: TextStyle(
              color: const Color(0xFF2A3A5A),
              fontSize: context.sp(10),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _hint(IconData icon, String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(top: context.dp(6), left: context.dp(2)),
      child: Row(
        children: [
          Icon(icon, color: color, size: context.dp(13)),
          SizedBox(width: context.dp(6)),
          Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontSize: context.sp(11), height: 1.3)),
          ),
        ],
      ),
    );
  }

  SnackBar _buildErrorSnack(BuildContext context, String msg) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF131D33),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kError, width: 1),
      ),
      content: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: _kError, size: context.dp(18)),
          SizedBox(width: context.dp(10)),
          Text(msg,
              style: TextStyle(color: _kText, fontSize: context.sp(13))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LOGO BLOCK
// ═══════════════════════════════════════════════════════════════════════════════

class _LogoBlock extends StatelessWidget {
  const _LogoBlock({this.isTablet = false});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final outerD = context.dp(isTablet ? 92 : 76);
    final innerD = outerD * 0.765;
    final nameSz = context.sp(isTablet ? 38 : 32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: outerD, height: outerD,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer subtle ring
              Container(
                width: outerD, height: outerD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _kBlue.withValues(alpha: 0.18), width: 1),
                ),
              ),
              // Icon circle
              Container(
                width: innerD, height: innerD,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A7AFF), Color(0xFF00C9A7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.55),
                      blurRadius: 28,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: _kTeal.withValues(alpha: 0.22),
                      blurRadius: 48,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.route_rounded,
                      color: Colors.white,
                      size: innerD * 0.42,
                    ),
                    Positioned(
                      right: innerD * 0.16,
                      top:   innerD * 0.16,
                      child: Container(
                        width: innerD * 0.14,
                        height: innerD * 0.14,
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

        SizedBox(height: context.dp(18)),

        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Colors.white, Color(0xFFAAC8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(b),
          child: Text(
            'DUONET',
            style: TextStyle(
              color: Colors.white,
              fontSize: nameSz,
              fontWeight: FontWeight.w900,
              letterSpacing: 9,
            ),
          ),
        ),

        const SizedBox(height: 5),
        Text(
          'Smart Mobility Platform',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kTextSec,
            fontSize: context.sp(12),
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: context.dp(14)),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: const [
            _FeatureChip(icon: Icons.map_outlined,             label: 'MAPS'),
            _FeatureChip(icon: Icons.directions_car_outlined,  label: 'FLEET'),
            _FeatureChip(icon: Icons.groups_outlined,          label: 'WORKFORCE'),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LANDSCAPE BRAND PANEL  — gradient bg + decorative painter + brand content
//  Design inspiration: Linear, Vercel, Stripe, Airbnb, Slack
// ═══════════════════════════════════════════════════════════════════════════════

class _LandscapeBrandPanel extends StatelessWidget {
  const _LandscapeBrandPanel({this.isTablet = false});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final iconSize  = context.dp(isTablet ? 64 : 52);
    final innerSize = iconSize * 0.76;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Layer 1: Gradient background ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D2050), // rich deep blue top-left
                Color(0xFF081428), // dark navy bottom-right
              ],
            ),
          ),
        ),

        // ── Layer 2: Decorative painter (dots, routes, markers) ──
        const CustomPaint(painter: _BrandPanelPainter()),

        // ── Layer 3: Right-edge gradient fade → seamless blend ──
        Positioned(
          right: 0, top: 0, bottom: 0,
          child: Container(
            width: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Color(0xFF060A18)],
              ),
            ),
          ),
        ),

        // ── Layer 4: Brand content ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 24,
            isTablet ? 24 : 16,
            isTablet ? 52 : 44, // extra right for the fade
            isTablet ? 24 : 16,
          ),
          child: LayoutBuilder(
            builder: (_, constraints) {
              // Adapt content to whatever height the panel actually has.
              // This prevents overflow when the keyboard is open, the device
              // has a large navigation bar, or the app is in split-screen.
              final availH        = constraints.maxHeight;
              final showFeatures  = isTablet && availH >= 580;
              final useCompact    = availH < 500;
              final showTaglines  = availH >= 300;
              final showPills     = availH >= 380;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo icon with layered glow
                  SizedBox(
                    width: iconSize, height: iconSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: iconSize, height: iconSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _kBlue.withValues(alpha: 0.20), width: 1),
                          ),
                        ),
                        // Gradient circle
                        Container(
                          width: innerSize, height: innerSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A7AFF), Color(0xFF00C9A7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kBlue.withValues(alpha: 0.60),
                                blurRadius: 28,
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: _kTeal.withValues(alpha: 0.22),
                                blurRadius: 44,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.route_rounded,
                                  color: Colors.white, size: innerSize * 0.42),
                              Positioned(
                                right: innerSize * 0.16,
                                top: innerSize * 0.15,
                                child: Container(
                                  width: innerSize * 0.15,
                                  height: innerSize * 0.15,
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

                  SizedBox(height: useCompact ? 8 : (isTablet ? 18 : 14)),

                  // Wordmark with gradient shader
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Colors.white, Color(0xFF8BBEFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(b),
                    child: Text(
                      'DUONET',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.sp(isTablet ? 26 : 21),
                        fontWeight: FontWeight.w900,
                        letterSpacing: isTablet ? 6 : 5,
                      ),
                    ),
                  ),

                  SizedBox(height: useCompact ? 5 : (isTablet ? 12 : 8)),

                  // Two-line bold tagline — hidden on very short viewports
                  if (showTaglines) ...[
                    Text(
                      'Navigate smarter.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.sp(isTablet ? 16 : 14),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Work faster.',
                      style: TextStyle(
                        color: _kBlue,
                        fontSize: context.sp(isTablet ? 16 : 14),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: useCompact ? 8 : (isTablet ? 22 : 16)),
                  ],

                  // Feature pills — hidden on very compact viewports
                  if (showPills)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _BrandPill(
                            color: _kBlue,
                            icon: Icons.map_outlined,
                            label: 'Maps'),
                        _BrandPill(
                            color: _kTeal,
                            icon: Icons.directions_car_outlined,
                            label: 'Fleet'),
                        _BrandPill(
                            color: _kPurple,
                            icon: Icons.groups_outlined,
                            label: 'Teams'),
                      ],
                    ),

                  // Feature rows — tablet only, and only when enough height
                  // (keyboard open or split-screen reduces availH below 580)
                  if (showFeatures) ...[
                    SizedBox(height: useCompact ? 12 : 16),
                    _BrandFeatureRow(
                      color: _kBlue,
                      icon: Icons.map_outlined,
                      title: 'Smart Maps',
                      sub: 'Real-time routing & intelligence',
                    ),
                    const SizedBox(height: 12),
                    _BrandFeatureRow(
                      color: _kTeal,
                      icon: Icons.directions_car_outlined,
                      title: 'Fleet Management',
                      sub: 'Track & optimize every vehicle',
                    ),
                    const SizedBox(height: 12),
                    _BrandFeatureRow(
                      color: _kPurple,
                      icon: Icons.groups_outlined,
                      title: 'Workforce',
                      sub: 'Coordinate teams at scale',
                    ),
                  ],

                  SizedBox(height: useCompact ? 8 : (isTablet ? 24 : 18)),

                  // Trust badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kSuccess.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _kSuccess.withValues(alpha: 0.18), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: _kSuccess,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: _kSuccess.withValues(alpha: 0.70),
                                  blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'All systems operational',
                          style: TextStyle(
                            color: _kSuccess,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Brand pill (compact feature tag) ─────────────────────────────────────────

class _BrandPill extends StatelessWidget {
  const _BrandPill(
      {required this.color, required this.icon, required this.label});
  final Color    color;
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(9), vertical: context.dp(5)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.dp(10), color: color),
          SizedBox(width: context.dp(5)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: context.sp(10),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Brand feature row (tablet landscape only) ─────────────────────────────────

class _BrandFeatureRow extends StatelessWidget {
  const _BrandFeatureRow({
    required this.color,
    required this.icon,
    required this.title,
    required this.sub,
  });
  final Color    color;
  final IconData icon;
  final String   title;
  final String   sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.dp(32), height: context.dp(32),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.20), width: 1),
          ),
          child: Icon(icon, color: color, size: context.dp(14)),
        ),
        SizedBox(width: context.dp(11)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: _kText,
                      fontSize: context.sp(12),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(sub,
                  style: TextStyle(
                      color: _kTextSec, fontSize: context.sp(10.5))),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Brand panel background painter ───────────────────────────────────────────

class _BrandPanelPainter extends CustomPainter {
  const _BrandPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // ── Radial center glow (behind logo area) ──
    final cx = size.width * 0.40;
    final cy = size.height * 0.44;
    final gr = size.width * 0.90;
    canvas.drawCircle(
      Offset(cx, cy),
      gr,
      Paint()
        ..shader = RadialGradient(
          colors: [_kBlue.withValues(alpha: 0.13), Colors.transparent],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: gr)),
    );

    // ── Dot grid (slightly brighter than page bg) ──
    final dotPaint = Paint()
      ..color = _kBlue.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    const step = 26.0;
    for (double x = step; x < size.width;  x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.85, dotPaint);
      }
    }

    // ── Route curves ──
    final linePaint = Paint()
      ..strokeWidth = 1.0
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    linePaint.color = _kBlue.withValues(alpha: 0.12);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.20)
        ..cubicTo(
          size.width * 0.30, size.height * 0.28,
          size.width * 0.60, size.height * 0.22,
          size.width,        size.height * 0.08,
        ),
      linePaint,
    );

    linePaint.color = _kTeal.withValues(alpha: 0.09);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.78)
        ..cubicTo(
          size.width * 0.25, size.height * 0.68,
          size.width * 0.65, size.height * 0.74,
          size.width,        size.height * 0.88,
        ),
      linePaint,
    );

    linePaint.color = _kPurple.withValues(alpha: 0.07);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.10, 0)
        ..cubicTo(
          size.width * 0.30, size.height * 0.18,
          size.width * 0.20, size.height * 0.42,
          size.width * 0.45, size.height * 0.58,
        ),
      linePaint,
    );

    // ── Map ping markers ──
    final pins = [
      (Offset(size.width * 0.14, size.height * 0.18), _kBlue.withValues(alpha: 0.38)),
      (Offset(size.width * 0.75, size.height * 0.72), _kTeal.withValues(alpha: 0.32)),
      (Offset(size.width * 0.82, size.height * 0.28), _kBlue.withValues(alpha: 0.26)),
    ];
    for (final pin in pins) {
      // Pulse ring
      canvas.drawCircle(
        pin.$1,
        10,
        Paint()
          ..color = pin.$2.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      // Marker triangle
      canvas.drawPath(
        Path()
          ..moveTo(pin.$1.dx,     pin.$1.dy - 7)
          ..lineTo(pin.$1.dx - 4, pin.$1.dy + 3)
          ..lineTo(pin.$1.dx + 4, pin.$1.dy + 3)
          ..close(),
        Paint()
          ..color = pin.$2
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_BrandPanelPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TEXT FIELD  — fixed: filled, all borders removed, crisp text
// ═══════════════════════════════════════════════════════════════════════════════

class _DuonetTextField extends StatefulWidget {
  const _DuonetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText      = false,
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

class _DuonetTextFieldState extends State<_DuonetTextField>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  bool _focused = false;

  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut);
    _focus.addListener(() {
      final f = _focus.hasFocus;
      setState(() => _focused = f);
      if (f) {
        _glowCtrl.forward();
      } else {
        _glowCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (ctx, child) {
        return Container(
          decoration: BoxDecoration(
            color: _focused
                ? Color.lerp(_kField, const Color(0xFF162040), _glowAnim.value)
                : _kField,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color.lerp(_kBorder, _kBlue, _glowAnim.value)!,
              width: _focused ? 1.5 : 1.0,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.18 * _glowAnim.value),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: child,
        );
      },
      child: TextField(
        controller:      widget.controller,
        focusNode:       _focus,
        obscureText:     widget.obscureText,
        onSubmitted:     widget.onSubmitted,
        textInputAction: widget.textInputAction,
        style: TextStyle(
          color: _kText,           // ← crisp white text, always visible
          fontSize: context.sp(15),
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        cursorColor: _kBlue,
        cursorWidth: 1.5,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _kHint,
            fontSize: context.sp(14),
            fontWeight: FontWeight.w400,
          ),
          floatingLabelStyle: TextStyle(
            color: _kBlue,
            fontSize: context.sp(12),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              widget.icon,
              color: _focused ? _kBlue : _kHint,
              size: context.dp(18),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffixIcon,
          // ↓ FIX: every border variant = none + filled transparent
          filled:               true,
          fillColor:            Colors.transparent,
          border:               InputBorder.none,
          enabledBorder:        InputBorder.none,
          focusedBorder:        InputBorder.none,
          disabledBorder:       InputBorder.none,
          errorBorder:          InputBorder.none,
          focusedErrorBorder:   InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              vertical: context.dp(16), horizontal: context.dp(14)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PASSWORD STRENGTH BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final int strength;

  static const _segColors = <Color>[
    Colors.transparent,
    _kError,
    _kWarning,
    Color(0xFFE8D44D),
    _kSuccess,
  ];
  static const _labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();
    final color = _segColors[strength];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4.0 : 0.0),
              decoration: BoxDecoration(
                color: i < strength ? color : _kBorder,
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
            fontSize: context.sp(10),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SIGN IN BUTTON  — scale-press + gradient glow
// ═══════════════════════════════════════════════════════════════════════════════

class _SignInButton extends StatefulWidget {
  const _SignInButton({required this.isLoading, this.onTap});
  final bool          isLoading;
  final VoidCallback? onTap;

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: context.dp(52),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isLoading
                  ? [
                      _kBlue.withValues(alpha: 0.40),
                      _kTeal.withValues(alpha: 0.40),
                    ]
                  : const [Color(0xFF1A7AFF), Color(0xFF00C9A7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: _kTeal.withValues(alpha: 0.18),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Gloss overlay
              if (!widget.isLoading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                ),
              Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login_rounded,
                              color: Colors.white, size: context.dp(17)),
                          SizedBox(width: context.dp(9)),
                          Text(
                            'SIGN IN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.sp(14),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
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

// ═══════════════════════════════════════════════════════════════════════════════
//  SOCIAL SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _SocialSection extends StatelessWidget {
  const _SocialSection({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: _kBorder, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or continue with',
                style: TextStyle(
                    color: _kHint,
                    fontSize: context.sp(compact ? 10 : 11),
                    letterSpacing: 0.3),
              ),
            ),
            Expanded(child: Divider(color: _kBorder, thickness: 1)),
          ],
        ),
        SizedBox(height: compact ? 10 : 14),
        // Buttons
        Row(
          children: [
            Expanded(child: _SocialBtn(label: 'Google', icon: _GoogleIcon())),
            const SizedBox(width: 9),
            Expanded(
                child: _SocialBtn(
              label: 'Apple',
              icon: Icon(Icons.apple, color: _kText, size: context.dp(18)),
            )),
            const SizedBox(width: 9),
            Expanded(
                child: _SocialBtn(
              label: 'SSO',
              icon: Icon(Icons.business_center_outlined,
                  color: _kBlue, size: context.dp(15)),
            )),
          ],
        ),
      ],
    );
  }
}

class _SocialBtn extends StatefulWidget {
  const _SocialBtn({required this.label, required this.icon});
  final String label;
  final Widget icon;

  @override
  State<_SocialBtn> createState() => _SocialBtnState();
}

class _SocialBtnState extends State<_SocialBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: context.dp(42),
        decoration: BoxDecoration(
          color: _pressed
              ? _kBorder.withValues(alpha: 0.8)
              : _kField,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.icon,
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: _kText,
                fontSize: context.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.dp(17), height: context.dp(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF0F9D58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text('G',
            style: TextStyle(
                color: Colors.white,
                fontSize: context.sp(9),
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ANIMATED CHECKBOX
// ═══════════════════════════════════════════════════════════════════════════════

class _AnimCheckbox extends StatelessWidget {
  const _AnimCheckbox({
    required this.value,
    required this.label,
    required this.onTap,
  });
  final bool         value;
  final String       label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: context.dp(16), height: context.dp(16),
            decoration: BoxDecoration(
              color: value ? _kBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? _kBlue : _kHint,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check, color: Colors.white, size: context.dp(10))
                : null,
          ),
          SizedBox(width: context.dp(8)),
          Text(label,
              style: TextStyle(
                  color: _kTextSec, fontSize: context.sp(12))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STATUS PILL
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.color, required this.label});
  final Color  color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.dp(6), height: context.dp(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.70), blurRadius: 5)
            ],
          ),
        ),
        SizedBox(width: context.dp(6)),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF3A4F6A),
            fontSize: context.sp(11),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FEATURE CHIP
// ═══════════════════════════════════════════════════════════════════════════════

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.dp(9), vertical: context.dp(4)),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBlue.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.dp(10), color: _kTeal),
          SizedBox(width: context.dp(4)),
          Text(label,
              style: TextStyle(
                  color: _kTeal,
                  fontSize: context.sp(9),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AMBIENT GLOW  (animated pulsing orbs)
// ═══════════════════════════════════════════════════════════════════════════════

class _GlowLayer extends StatelessWidget {
  const _GlowLayer({required this.p1, required this.p2});
  final double p1;
  final double p2;

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        // Top-left blue orb
        Positioned(
          top:  -110 + p1 * 28,
          left: -80,
          child: _Orb(
            size: 400 + p1 * 48,
            color: _kBlue.withValues(alpha: 0.09 + p1 * 0.06),
          ),
        ),
        // Bottom-right teal orb
        Positioned(
          bottom: 20 + p2 * 24,
          right:  -100,
          child: _Orb(
            size: 320,
            color: _kTeal.withValues(alpha: 0.06 + p2 * 0.04),
          ),
        ),
        // Mid-right purple accent
        Positioned(
          top:   sz.height * 0.22,
          right: -55,
          child: _Orb(
            size: 180,
            color: _kPurple.withValues(alpha: 0.04 + (1 - p1) * 0.03),
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color, Colors.transparent]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BACKGROUND GRID PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // ── Dot-grid (more modern than lines) ──
    final dotPaint = Paint()
      ..color = _kBlue.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    const step = 36.0;
    for (double x = step; x < size.width;  x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.9, dotPaint);
      }
    }

    // ── Route curves ──
    final strokePaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    strokePaint.color = _kBlue.withValues(alpha: 0.08);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.30)
        ..quadraticBezierTo(
            size.width * 0.38, size.height * 0.44,
            size.width, size.height * 0.20),
      strokePaint,
    );

    strokePaint.color = _kBlue.withValues(alpha: 0.06);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.10, size.height)
        ..quadraticBezierTo(
            size.width * 0.52, size.height * 0.70,
            size.width * 0.88, size.height * 0.34),
      strokePaint,
    );

    strokePaint.color = _kTeal.withValues(alpha: 0.05);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.62, 0)
        ..quadraticBezierTo(
            size.width * 0.78, size.height * 0.28,
            size.width, size.height * 0.52),
      strokePaint,
    );

    // ── Location ping dots ──
    final rng = math.Random(7);
    for (int i = 0; i < 7; i++) {
      final pos = Offset(
          rng.nextDouble() * size.width,
          rng.nextDouble() * size.height);
      final c = i.isEven ? _kBlue : _kTeal;
      canvas.drawCircle(pos, 8,
          Paint()..color = c.withValues(alpha: 0.05));
      canvas.drawCircle(pos, 2,
          Paint()
            ..color = c.withValues(alpha: 0.35)
            ..style = PaintingStyle.fill);
    }

    // ── Map marker triangles ──
    final markerPaint = Paint()
      ..color = _kTeal.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    for (final p in [
      Offset(size.width * 0.22, size.height * 0.33),
      Offset(size.width * 0.70, size.height * 0.57),
      Offset(size.width * 0.46, size.height * 0.80),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(p.dx,     p.dy - 6)
          ..lineTo(p.dx - 4, p.dy + 4)
          ..lineTo(p.dx + 4, p.dy + 4)
          ..close(),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}