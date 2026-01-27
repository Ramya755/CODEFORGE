import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flowmatefirebase/screens/home_screens/home_screen.dart';
import 'package:flowmatefirebase/screens/login_screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color electricCyan = Color(0xFF00FFFF);
const Color vibrantMagenta = Color(0xFFF000FF);
const Color deepSpaceBlue = Color(0xFF0D1117);
const Color circuitBoardBlack = Color(0xFF0A0F1A);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressBarController;
  late AnimationController _textColorController;
  late AnimationController _glitchController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoGlow;
  late Animation<String> _codeForgeText;
  late Animation<double> _loadingTextOpacity;
  late Animation<double> _progressBar;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    "users",
  );

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _textColorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoRotation = Tween<double>(begin: -pi / 6, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _codeForgeText = TypewriterTween(end: 'CodeForge').animate(_textController);
    _loadingTextOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressBarController,
        curve: const Interval(0.0, 0.5),
      ),
    );
    _progressBar = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressBarController, curve: Curves.easeInOut),
    );

    _gradientColor1 = ColorTween(
      begin: electricCyan,
      end: vibrantMagenta,
    ).animate(_textColorController);
    _gradientColor2 = ColorTween(
      begin: vibrantMagenta,
      end: electricCyan,
    ).animate(_textColorController);
  }

  /// Check Firebase login status
  Future<void> _checkLoginStatus() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Fetch user details from Realtime Database
      final snapshot = await _dbRef.child(currentUser.uid).get();
      if (snapshot.exists) {
        // Navigate to HomeScreen if user data exists
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        // User logged in but no data -> navigate to login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } else {
      // No user logged in -> navigate to login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _startAnimations() async {
    await _logoController.forward().orCancel;
    await _textController.forward().orCancel;
    await _progressBarController.forward().orCancel;

    // After splash animation completes, check login status
    Timer(const Duration(milliseconds: 500), _checkLoginStatus);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressBarController.dispose();
    _textColorController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- All UI code remains the same as your original design ---
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  circuitBoardBlack.withOpacity(0.8),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _glitchController,
            builder: (context, child) {
              final double offsetX = (Random().nextDouble() - 0.5) * 3;
              final double offsetY = (Random().nextDouble() - 0.5) * 3;
              return Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: child,
              );
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: electricCyan.withOpacity(
                                    0.6 * _logoGlow.value,
                                  ),
                                  blurRadius: 40.0,
                                  spreadRadius: 5.0,
                                ),
                                BoxShadow(
                                  color: vibrantMagenta.withOpacity(
                                    0.4 * _logoGlow.value,
                                  ),
                                  blurRadius: 25.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: const CustomPaint(
                      painter: InsaneLogoPainter(),
                      size: Size(130, 130),
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: _textColorController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback:
                            (bounds) => LinearGradient(
                              colors: [
                                _gradientColor1.value!,
                                _gradientColor2.value!,
                              ],
                            ).createShader(bounds),
                        child: child,
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _codeForgeText,
                      builder: (context, child) {
                        return Text(
                          _codeForgeText.value,
                          style: GoogleFonts.orbitron(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                blurRadius: 15.0,
                                color: electricCyan,
                              ),
                              const Shadow(
                                blurRadius: 25.0,
                                color: vibrantMagenta,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 70),
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _loadingTextOpacity,
                          builder:
                              (context, child) => Opacity(
                                opacity: _loadingTextOpacity.value,
                                child: Text(
                                  'Initializing Matrix...',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: _progressBar,
                          builder:
                              (context, child) => CustomPaint(
                                painter: ProgressBarPainter(
                                  progress: _progressBar.value,
                                ),
                                child: const SizedBox(height: 6, width: 250),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsaneLogoPainter extends CustomPainter {
  const InsaneLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Outer circle gradient
    paint.shader = SweepGradient(
      colors: [electricCyan, vibrantMagenta, electricCyan],
      tileMode: TileMode.repeated,
    ).createShader(rect);
    canvas.drawCircle(center, size.width / 2, paint);

    // Inner Tron-like circuit lines
    paint.shader = null;
    paint.color = electricCyan.withOpacity(0.8);
    paint.strokeWidth = 2;

    // Some arbitrary circuit paths for a tech look
    final path = Path();
    path.moveTo(center.dx, center.dy - size.width / 2);
    path.lineTo(center.dx, center.dy - 20);
    path.lineTo(center.dx - 20, center.dy);
    path.lineTo(center.dx + 20, center.dy);
    path.moveTo(center.dx, center.dy + 20);
    path.lineTo(center.dx, center.dy + size.width / 2);
    path.moveTo(center.dx - size.width / 2, center.dy);
    path.lineTo(center.dx - 20, center.dy);

    canvas.drawPath(path, paint);

    // Central Power Icon (lightning bolt)
    final iconPaint = Paint()
      ..color = electricCyan
      ..style = PaintingStyle.fill
      ..shader = const RadialGradient(
        colors: [Colors.white, electricCyan],
      ).createShader(Rect.fromCircle(center: center, radius: 25));

    final iconPath = Path();
    iconPath.moveTo(center.dx + 5, center.dy - 25);
    iconPath.lineTo(center.dx - 15, center.dy + 5);
    iconPath.lineTo(center.dx, center.dy + 5);
    iconPath.lineTo(center.dx - 5, center.dy + 25);
    iconPath.lineTo(center.dx + 15, center.dy - 5);
    iconPath.lineTo(center.dx, center.dy - 5);
    iconPath.close();

    canvas.drawPath(iconPath, iconPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for the progress bar with a new theme
class ProgressBarPainter extends CustomPainter {
  final double progress;
  ProgressBarPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()..color = Colors.white.withOpacity(0.1);
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [vibrantMagenta, electricCyan],
      ).createShader(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    final glowPaint = Paint()
      ..color = electricCyan.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final trackRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    final progressRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(trackRRect, trackPaint);
    if (progress > 0) {
      canvas.drawRRect(progressRRect, glowPaint);
      canvas.drawRRect(progressRRect, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// A custom Tween to animate text like a typewriter.
class TypewriterTween extends Tween<String> {
  TypewriterTween({String begin = '', required String end})
    : super(begin: begin, end: end);
  @override
  String lerp(double t) {
    final step = (end!.length * t).round();
    return end!.substring(0, step);
  }
}
