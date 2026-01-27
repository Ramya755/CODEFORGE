import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 


class AppColors {
  static const Color circuitBoardBlack = Color(0xFF0F1724);
  static const Color neonCyan = Color(0xFF0CF5D8); // Shield accent
  static const Color neonBlue = Color.fromARGB(255, 161, 50, 156); // Link accent
}

enum MedalType { bronze, silver, gold }

class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});
  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _positions = List.generate(
      30, (_) => Offset(Random().nextDouble() * 400, Random().nextDouble() * 800));

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(_positions, _controller.value),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Offset> positions;
  final double progress;
  ParticlePainter(this.positions, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyan.withOpacity(0.2);
    for (var pos in positions) {
      final dx = (pos.dx + progress * size.width) % size.width;
      final dy = (pos.dy + progress * 20) % size.height;
      canvas.drawCircle(Offset(dx, dy), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}




class MiniMedalPainter extends CustomPainter {
  final Color color;
  MiniMedalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), size.width * 0.35, p);
    final path = Path();
    path.moveTo(size.width * 0.35, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height * 0.95);
    path.lineTo(size.width * 0.75, size.height * 0.7);
    path.close();
    canvas.drawPath(path, p);
    final inner = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), size.width * 0.15, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LevelTile extends StatefulWidget {
  final int level;
  final bool isLocked;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback onTap;

  const LevelTile({
    super.key,
    required this.level,
    required this.isLocked,
    required this.isCompleted,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  State<LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<LevelTile> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _sparkController;
  final List<Offset> _sparkOffsets =
      List.generate(6, (_) => Offset(Random().nextDouble(), Random().nextDouble()));

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) _pulseController.repeat(reverse: true);

    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LevelTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sparkController.dispose();
    super.dispose();
  }

  Color _levelColor() {
    if (widget.level <= 5) return const Color(0xFF9B6B2B); // bronze
    if (widget.level <= 10) return const Color(0xFFBFCBD6); // silver
    return const Color(0xFFFFD24A); // gold
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor();
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _sparkController]),
        builder: (context, _) {
          final shadowSpread =
              widget.isCurrent ? _pulseAnim.value : (widget.isCompleted ? 6.0 : 2.0);
          final shadowColor =
              widget.isCurrent ? color.withOpacity(0.9) : color.withOpacity(0.22);

          return SizedBox(
            width: 90,
            height: 100,
            child: Stack(
              children: [
                
                
                if (widget.isCurrent)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 12 + _pulseAnim.value,
                          spreadRadius: 1.5,
                        ),
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 20 + _pulseAnim.value,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  ),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: widget.isCompleted
                        ? LinearGradient(
                            colors: [color.withOpacity(0.2), Colors.transparent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: widget.isLocked ? Colors.grey.shade900 : AppColors.circuitBoardBlack,
                    boxShadow: [
                      BoxShadow(
                          color: shadowColor,
                          blurRadius: shadowSpread,
                          spreadRadius: widget.isCurrent ? 1.2 : 0.5),
                      BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                    border: Border.all(
                      color: widget.isCurrent ? color.withOpacity(0.85) : Colors.white10,
                      width: widget.isCurrent ? 2.2 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: widget.isLocked
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock, color: Colors.white24, size: 26),
                              const SizedBox(height: 6),
                              Text('${widget.level}',
                                  style: const TextStyle(
                                      color: Colors.white24, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${widget.level}',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isCompleted ? color : Colors.white)),
                              const SizedBox(height: 6),
                              if (widget.isCompleted)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomPaint(
                                        size: const Size(18, 18),
                                        painter: MiniMedalPainter(color: color)),
                                    const SizedBox(width: 6),
                                    const Text('Complete',
                                        style:
                                            TextStyle(fontSize: 12, color: Colors.white70)),
                                  ],
                                )
                              else if (widget.isCurrent)
                                const Text('Current',
                                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                  ),
                ),

                
                
                if (widget.isCompleted || widget.isCurrent)
                  ..._sparkOffsets.map((offset) {
                    final dx = offset.dx * 50 + 4 * sin(_sparkController.value * pi * 2);
                    final dy = offset.dy * 50 + 4 * cos(_sparkController.value * pi * 2);
                    return Positioned(
                      left: 16 + dx,
                      top: 16 + dy,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}


class MedalPainter extends CustomPainter {
  final Color color;
  MedalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2.2;
    final Paint p = Paint()..shader = RadialGradient(colors: [color, color.withOpacity(0.7), Colors.black.withOpacity(0.2)], stops: const [0.0, 0.7, 1.0]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.45));
    // outer ring
    canvas.drawCircle(Offset(cx, cy), size.width * 0.45, p);
    // inner circle
    final inner = Paint()..color = Colors.black.withOpacity(0.12);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.28, inner);
    // center emblem - star
    final starPaint = Paint()..color = Colors.white.withOpacity(0.92);
    final path = Path();
    final r = size.width * 0.12;
    for (int i = 0; i < 5; i++) {
      final a = (pi * 2 * i / 5) - pi / 2;
      final x = cx + cos(a) * r * 1.2;
      final y = cy + sin(a) * r * 1.2;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      final a2 = a + pi / 5;
      final x2 = cx + cos(a2) * r * 0.5;
      final y2 = cy + sin(a2) * r * 0.5;
      path.lineTo(x2, y2);
    }
    path.close();
    canvas.drawPath(path, starPaint);

    // ribbon
    final ribbonPaint = Paint()..shader = LinearGradient(colors: [color.withOpacity(0.95), color.withOpacity(0.6)]).createShader(Rect.fromLTWH(cx - 50, cy + 40, 100, 80));
    final rPath = Path();
    rPath.moveTo(cx - 48, cy + 30);
    rPath.lineTo(cx - 20, cy + 80);
    rPath.lineTo(cx - 2, cy + 60);
    rPath.lineTo(cx + 20, cy + 80);
    rPath.lineTo(cx + 48, cy + 30);
    rPath.close();
    canvas.drawPath(rPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// SHIELD PAINTER (draws an emblematic shield)
class ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const top = 30.0;
    final shieldRect = Rect.fromLTWH(cx - 80, top, 160, 200);
    final Paint base = Paint()..shader = const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonBlue], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(shieldRect);
    final path = Path();
    path.moveTo(cx - 80, top + 30);
    path.quadraticBezierTo(cx, top, cx + 80, top + 30);
    path.lineTo(cx + 60, top + 120);
    path.quadraticBezierTo(cx + 60, top + 170, cx, top + 200);
    path.quadraticBezierTo(cx - 60, top + 170, cx - 60, top + 120);
    path.close();
    canvas.drawShadow(path, Colors.black, 8, true);
    canvas.drawPath(path, base);
    // inner crest
    final inner = Paint()..color = Colors.white.withOpacity(0.12);
    canvas.drawPath(Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, top + 110), width: 90, height: 110)), inner);
    // star/crest
    final star = Paint()..color = Colors.white.withOpacity(0.95);
    const r = 18.0;
    const cY = top + 110;
    final cX = cx;
    final p = Path();
    for (int i = 0; i < 5; i++) {
      final a = (pi * 2 * i / 5) - pi / 2;
      final x = cX + cos(a) * r;
      final y = cY + sin(a) * r;
      if (i == 0) p.moveTo(x, y); else p.lineTo(x, y);
      final a2 = a + pi / 5;
      final x2 = cX + cos(a2) * r * 0.45;
      final y2 = cY + sin(a2) * r * 0.45;
      p.lineTo(x2, y2);
    }
    p.close();
    canvas.drawPath(p, star);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




class MedalOverlay extends StatefulWidget {
  final MedalType medalType;
  final String title;
  final String quote;
  const MedalOverlay({super.key, required this.medalType, required this.title, required this.quote});

  @override
  State<MedalOverlay> createState() => _MedalOverlayState();
}

class _MedalOverlayState extends State<MedalOverlay> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Color _colorByType() {
    switch (widget.medalType) {
      case MedalType.bronze:
        return const Color(0xFF9B6B2B);
      case MedalType.silver:
        return const Color(0xFFD1D8DD);
      case MedalType.gold:
        return const Color(0xFFFFD24A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colorByType();
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container( // **ADDED STYLING CONTAINER**
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.circuitBoardBlack.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: c.withOpacity(0.5),
                      blurRadius: 25,
                    )
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ScaleTransition(
                  scale: _scaleAnim, 
                  child: RotationTransition(
                    turns: _rotateController, 
                    child: CustomPaint(
                      size: const Size(180, 180), 
                      painter: MedalPainter(color: c)
                    )
                  )
                ),
                const SizedBox(height: 20),
                Text(widget.title, 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: c)), // Added color
                const SizedBox(height: 8),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 18.0), 
                  child: Text('"${widget.quote}"', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    backgroundColor: c, // Use medal color for button
                  ), 
                  child: const Text('Awesome',style: TextStyle(color: Colors.black),)),
              ]),
          ),
        ),
      ),
    );
  }
}

class ShieldOverlay extends StatefulWidget {
  final String title;
  final String quote;
  const ShieldOverlay({super.key, required this.title, required this.quote});

  @override
  State<ShieldOverlay> createState() => _ShieldOverlayState();
}

class _ShieldOverlayState extends State<ShieldOverlay> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;
  late AnimationController _rotateController; 

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const shieldColor = AppColors.neonCyan; 
    

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container( 
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.circuitBoardBlack.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: shieldColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: shieldColor.withOpacity(0.5),
                    blurRadius: 25,
                  )
                ]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ScaleTransition(
                scale: _scaleAnim, 
                child: RotationTransition(
                  turns: _rotateController, 
                  child: CustomPaint(
                    size: const Size(220, 260), 
                    painter: ShieldPainter()
                  )
                )
              ),
              const SizedBox(height: 10),
              Text(widget.title, 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: shieldColor)), // Use shield color
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 18.0), 
                  child: Text('"${widget.quote}"', style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center)),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(), 
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: shieldColor, 
                ), 
                child: const Text('Keep Learning',style: TextStyle(color: Colors.black),)),
            ]),
          ),
        ),
      ),
    );
  }
}

class LinkOverlay extends StatelessWidget {
  final String title;
  final String quote;
  final String linkTitle;
  final String linkUrl;

  const LinkOverlay({
    super.key,
    required this.title,
    required this.quote,
    required this.linkTitle,
    required this.linkUrl,
  });
  
  
  void _launchUrl(BuildContext context) async {
    final Uri uri = Uri.parse(linkUrl);
    
   
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $linkUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, 
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.circuitBoardBlack.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonBlue, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonBlue.withOpacity(0.5),
                  blurRadius: 25,
                )
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.neonBlue, size: 50),
                const SizedBox(height: 10),
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.neonBlue)),
                const SizedBox(height: 8),
                Text('"$quote"', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(context), 
                  icon: const Icon(Icons.link),
                  label: Text(linkTitle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonBlue,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                      backgroundColor: Colors.white12,
                  ),
                  child: const Text('Continue Game'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}