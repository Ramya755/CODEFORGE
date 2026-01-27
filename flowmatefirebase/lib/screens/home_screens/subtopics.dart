import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flowmatefirebase/screens/levels_screen/level_service.dart';

class SubTopicsScreen extends StatefulWidget {
  final String language;
  final String topic;
  final List<String> subtopics;
  final Map<String, List<String>> topicMap;

  const SubTopicsScreen({
    super.key,
    required this.language,
    required this.topic,
    required this.subtopics,
    required this.topicMap,
  });

  @override
  State<SubTopicsScreen> createState() => _SubTopicsScreenState();
}

class _SubTopicsScreenState extends State<SubTopicsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      appBar: AppBar(
        title: Text(
          "${widget.topic} - Subtopics",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D1117),
                Color(0xFF00FFFF),
                Color(0xFFF000FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const SparkStreaks(),
          SafeArea(
            child: SizedBox.expand(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: widget.subtopics.length,
                itemBuilder: (context, index) {
                  final subtopic = widget.subtopics[index];

                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 500 + (index * 120)),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 50),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      height: 120,
                      child: Align(
                        alignment: Alignment.center,
                        child: FloatingNeonCard(
                          language: widget.language,
                          topic: widget.topic,
                          levelno: index,
                          subtopic: subtopic,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- FloatingNeonCard ----------------
class FloatingNeonCard extends StatefulWidget {
  final String language;
  final String topic;
  final String subtopic;
  final int levelno;

  const FloatingNeonCard({
    super.key,
    required this.language,
    required this.topic,
    required this.subtopic,
    required this.levelno,
  });

  @override
  State<FloatingNeonCard> createState() => _FloatingNeonCardState();
}

class _FloatingNeonCardState extends State<FloatingNeonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late Color _glowColor;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();

    // Pick one random glow color per card
    List<Color> colors = [
      const Color(0xFF00FFFF),
      const Color(0xFF6A5ACD),
      const Color(0xFFF000FF),
    ];
    _glowColor = colors[Random().nextInt(colors.length)];

    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Fetch completion status from Firebase
    _fetchCompletionStatus();
  }

  Future<void> _fetchCompletionStatus() async {
    try {
      final levelKey = widget.levelno + 1;

      final levelData = await LevelService().getLevelFromFirebase(
        language: widget.language,
        topic: widget.topic,
        levelNumber: levelKey,
      );

      if (levelData != null && mounted) {
        setState(() {
          _isComplete = levelData["isCompleted"] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching level completion: $e");
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 10,
            shadowColor: _glowColor.withOpacity(_glowAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _glowColor,
                    const Color(0xFF6A5ACD),
                    const Color(0xFFF000FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _glowColor.withOpacity(_glowAnimation.value),
                  width: 2.5,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                title: Text(
                  widget.subtopic,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.8,
                  ),
                ),
                trailing: CustomPaint(
                  size: const Size(28, 28),
                  painter: StarPainter(
                    isFilled: _isComplete,
                    color: _isComplete ? Colors.yellowAccent : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------- StarPainter ----------------
class StarPainter extends CustomPainter {
  final bool isFilled;
  final Color color;

  StarPainter({required this.isFilled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    double w = size.width;
    double h = size.height;
    double cx = w / 2;
    double cy = h / 2;
    double radius = w / 2;

    for (int i = 0; i < 5; i++) {
      double angle = (i * 72 - 90) * pi / 180;
      double x = cx + radius * cos(angle);
      double y = cy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      double innerAngle = angle + 36 * pi / 180;
      double innerRadius = radius * 0.5;
      double ix = cx + innerRadius * cos(innerAngle);
      double iy = cy + innerRadius * sin(innerAngle);
      path.lineTo(ix, iy);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) =>
      oldDelegate.isFilled != isFilled || oldDelegate.color != color;
}

// ---------------- Spark Streaks ----------------
class SparkStreaks extends StatefulWidget {
  const SparkStreaks({super.key});

  @override
  State<SparkStreaks> createState() => _SparkStreaksState();
}

class _SparkStreaksState extends State<SparkStreaks>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Spark> _sparks = [];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();

    for (int i = 0; i < 20; i++) {
      _sparks.add(Spark());
    }
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
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: SparkPainter(_sparks, _controller.value),
        );
      },
    );
  }
}

class Spark {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double length = Random().nextDouble() * 30 + 10;
  Color color = [
    const Color(0xFF00FFFF),
    const Color(0xFF6A5ACD),
    const Color(0xFFF000FF)
  ][Random().nextInt(3)];
  double speed = Random().nextDouble() * 0.002 + 0.001;
}

class SparkPainter extends CustomPainter {
  final List<Spark> sparks;
  final double progress;

  SparkPainter(this.sparks, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.5;
    for (var s in sparks) {
      double dx = (s.x + progress * s.speed) % 1;
      double dy = (s.y + progress * s.speed) % 1;
      paint.color = s.color.withOpacity(0.7);
      canvas.drawLine(
        Offset(dx * size.width, dy * size.height),
        Offset((dx * size.width + s.length), (dy * size.height + s.length)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
