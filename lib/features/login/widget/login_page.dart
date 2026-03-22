import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../face_id/widget/face_id_page.dart';
import '../bloc/login_bloc.dart';

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

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordVisible = ValueNotifier<bool>(false);
  late final AnimationController _entranceController;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordVisible.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<LoginBloc>().add(
          LoginSubmitted(
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, anim, _) => const FaceIdPage(),
                transitionsBuilder: (_, anim, _, child) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          } else if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF1E2340),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFF4D6A), width: 1),
                ),
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFFF4D6A), size: 18),
                    const SizedBox(width: 10),
                    Text(state.message,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF07091A),
          resizeToAvoidBottomInset: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Map grid background
              const CustomPaint(painter: _DuonetMapPainter()),
              // Ambient glow blobs
              _buildAmbientGlow(),
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          SlideTransition(
                            position: _logoSlide,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: _buildLogo(),
                            ),
                          ),
                          const SizedBox(height: 52),
                          SlideTransition(
                            position: _formSlide,
                            child: FadeTransition(
                              opacity: _formFade,
                              child: _buildForm(context),
                            ),
                          ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: _formFade,
                            child: _buildFooter(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientGlow() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -100,
          child: Container(
            width: 380,
            height: 380,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Color(0x281B8EF8),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          right: -120,
          child: Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Color(0x1E00E5CC),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Icon cluster
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1B8EF8).withOpacity(0.25),
                    width: 1,
                  ),
                ),
              ),
              // Inner gradient circle
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B8EF8), Color(0xFF00E5CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B8EF8).withOpacity(0.45),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.route_rounded,
                        color: Colors.white, size: 30),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 10,
                        height: 10,
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
        const SizedBox(height: 22),
        // DUONET wordmark
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFB8D4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'DUONET',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Tag row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tagChip(Icons.map_outlined, 'MAPS'),
            const SizedBox(width: 10),
            _tagChip(Icons.directions_car_outlined, 'FLEET'),
            const SizedBox(width: 10),
            _tagChip(Icons.groups_outlined, 'WORKFORCE'),
          ],
        ),
      ],
    );
  }

  Widget _tagChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B8EF8).withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF1B8EF8).withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF00E5CC)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF00E5CC),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1629).withOpacity(0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF1B8EF8).withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to your DUONET account',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),
              _DuonetTextField(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.person_outline_rounded,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<bool>(
                valueListenable: _passwordVisible,
                builder: (_, visible, __) => _DuonetTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !visible,
                  onSubmitted: (_) => _submit(context),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        _passwordVisible.value = !_passwordVisible.value,
                    icon: Icon(
                      visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  final isLoading = state is LoginLoading;
                  return GestureDetector(
                    onTap: isLoading ? null : () => _submit(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLoading
                              ? [
                                  const Color(0xFF1B8EF8).withOpacity(0.5),
                                  const Color(0xFF00E5CC).withOpacity(0.5),
                                ]
                              : const [
                                  Color(0xFF1B8EF8),
                                  Color(0xFF00E5CC),
                                ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF1B8EF8)
                                      .withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.login_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statusDot(const Color(0xFF00E5CC), 'System Online'),
            const SizedBox(width: 20),
            _statusDot(const Color(0xFF1B8EF8), 'Secure Connection'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '© 2025 DUONET — Smart Mobility Platform',
          style: TextStyle(
            color: Colors.white.withOpacity(0.22),
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _statusDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Custom Text Field ────────────────────────────────────────────────────────

class _DuonetTextField extends StatelessWidget {
  const _DuonetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1B8EF8).withOpacity(0.20),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: const Color(0xFF1B8EF8),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.38),
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF1B8EF8),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF1B8EF8), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}

// ─── Background Map Painter ───────────────────────────────────────────────────

class _DuonetMapPainter extends CustomPainter {
  const _DuonetMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1B8EF8).withOpacity(0.055)
      ..strokeWidth = 0.5;

    const step = 38.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Route lines suggesting roads/paths
    final routePaint = Paint()
      ..color = const Color(0xFF1B8EF8).withOpacity(0.10)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(0, size.height * 0.28)
      ..quadraticBezierTo(
          size.width * 0.35, size.height * 0.42, size.width, size.height * 0.18);
    canvas.drawPath(path1, routePaint);

    final path2 = Path()
      ..moveTo(size.width * 0.15, size.height)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.72, size.width * 0.85, size.height * 0.35);
    canvas.drawPath(path2, routePaint);

    // GPS location dots
    final rng = math.Random(42); // fixed seed for deterministic positions
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 7; i++) {
      final pos = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      final color = i.isEven
          ? const Color(0xFF1B8EF8)
          : const Color(0xFF00E5CC);

      // Outer ring
      canvas.drawCircle(
        pos,
        8,
        Paint()..color = color.withOpacity(0.08),
      );
      // Inner dot
      dotPaint.color = color.withOpacity(0.45);
      canvas.drawCircle(pos, 2.5, dotPaint);
    }

    // Car / worker icons (small triangles as simplified vehicle markers)
    final markerPaint = Paint()
      ..color = const Color(0xFF00E5CC).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final markerPositions = [
      Offset(size.width * 0.22, size.height * 0.35),
      Offset(size.width * 0.68, size.height * 0.55),
      Offset(size.width * 0.48, size.height * 0.78),
    ];
    for (final pos in markerPositions) {
      final tri = Path()
        ..moveTo(pos.dx, pos.dy - 6)
        ..lineTo(pos.dx - 4, pos.dy + 4)
        ..lineTo(pos.dx + 4, pos.dy + 4)
        ..close();
      canvas.drawPath(tri, markerPaint);
    }
  }

  @override
  bool shouldRepaint(_DuonetMapPainter old) => false;
}