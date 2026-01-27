
import 'package:flowmatefirebase/models/language_topics_data.dart';
import 'package:flowmatefirebase/screens/home_screens/home_screen.dart';
import 'package:flowmatefirebase/screens/home_screens/subtopics.dart';
import 'package:flowmatefirebase/screens/levels_screen/levels_screen.dart';
import 'package:flutter/material.dart';

Color electricCyan = Color(0xFF4A90E2);

const double circleSize = 85.0;
const double connectorHeight = 90.0;

class TimelineConnectorPainter extends CustomPainter {
  final Color color;
  TimelineConnectorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.cubicTo(
      size.width / 2,
      size.height * 0.25,
      size.width * 0.75,
      size.height * 0.75,
      size.width / 2,
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TopicsScreen extends StatefulWidget {
  final String language;
  const TopicsScreen({super.key, required this.language});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen>
    with SingleTickerProviderStateMixin {
  final List<List<Color>> stepRingGradients = [
    [Colors.orange, Colors.deepOrange],
    [Colors.pink, Colors.red],
    [Colors.purple, Colors.deepPurple],
    [Colors.blue, Colors.lightBlue],
    [Colors.green, Colors.lightGreen],
    [Colors.teal, Colors.cyan],
    [Colors.indigo, Colors.blueGrey],
    [Colors.amber, Colors.orangeAccent],
    [Colors.brown, Colors.grey],
    [Colors.lime, Colors.lightGreenAccent],
  ];

  late final List<String> topicNames;

  late AnimationController _appBarController;
  late Animation<Color?> colorAnimation1;
  late Animation<Color?> colorAnimation2;

  @override
  void initState() {
    super.initState();

    topicNames = ConceptsR.conceptsByLanguage[widget.language]!.keys.toList();

    _appBarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    colorAnimation1 = ColorTween(
      begin: Colors.deepPurple,
      end: Colors.blueAccent,
    ).animate(_appBarController);

    colorAnimation2 = ColorTween(
      begin: Colors.indigo,
      end: Colors.purpleAccent,
    ).animate(_appBarController);
  }

  @override
  void dispose() {
    _appBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1E0A3A),
                  Color(0xFF6B3AB9),
                  Color(0xFF4A90E2),
                  Color(0xFF0A0F1A),
                  Color(0xFFF000FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              // Animated Gradient AppBar with border
              AnimatedBuilder(
                animation: _appBarController,
                builder: (context, child) {
                  return Container(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                        side: const BorderSide(color: Colors.black, width: 3),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          colorAnimation1.value!,
                          colorAnimation2.value!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: child,
                  );
                },
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 28),
                      color: Colors.white,
                      onPressed: () {
                        //Navigator.push(context,MaterialPageRoute(builder: (context)=>HomeScreen()));
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${widget.language} RoadMap",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              " Power Up Your Brain,",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Step by Step , Skill by Skill",
                              style: TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topicNames.length,
                        itemBuilder: (context, index) {
                          bool isLast = index == topicNames.length - 1;
                          Color lineColor =
                              stepRingGradients[index %
                                  stepRingGradients.length][0];

                          final topic = topicNames[index];

                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Step Circle Click → goes to SubTopicsScreen
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20.0),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LevelsScreen(
                                              language: widget.language,
                                              topic: topic,
                                            ),
                                            settings: RouteSettings(name: 'LevelsScreen'),
                                          ),
                                        );
                                      },
                                      child: StepCircle(
                                        stepNumber: index + 1,
                                        gradientColors:
                                            stepRingGradients[index %
                                                stepRingGradients.length],
                                        size: circleSize,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  // Topic Name Click → also goes to SubTopicsScreen
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 20.0,
                                        top: 10.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SubTopicsScreen(
                                               language: widget.language,
                                                topic: topic,
                                                subtopics:
                                                    ConceptsR.conceptsByLanguage[
                                                        widget.language]![topic]!,
                                                topicMap:
                                                    ConceptsR.conceptsByLanguage[
                                                        widget.language]!,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          topic,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 5.0,
                                                color: lineColor.withOpacity(
                                                  0.4,
                                                ),
                                                offset: const Offset(0, 0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!isLast)
                                SizedBox(
                                  height: connectorHeight,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 20.0,
                                        child: SizedBox(
                                          width: circleSize,
                                          height: connectorHeight,
                                          child: CustomPaint(
                                            painter: TimelineConnectorPainter(
                                              lineColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StepCircle extends StatelessWidget {
  final int stepNumber;
  final List<Color> gradientColors;
  final double size;

  const StepCircle({
    super.key,
    required this.stepNumber,
    required this.gradientColors,
    this.size = circleSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.6),
            blurRadius: 16,
            spreadRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.90,
          height: size * 0.88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black87,
          ),
          child: Center(
            child: Text(
              "STEP\n${stepNumber.toString().padLeft(2, '0')}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
