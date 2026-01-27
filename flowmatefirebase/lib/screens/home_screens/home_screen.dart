
import 'package:flowmatefirebase/screens/home_screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'dart:async';
import 'dart:math';
import 'topics_data.dart';

Color electricCyan = Color(0xFF00FFFF);
Color deepSpaceBlue = Color(0xFF0D1117);
Color circuitBoardBlack = Color(0xFF0A0F1A);
Color vibrantMagenta = Color(0xFFF000FF);
const Color accentViolet = Color(0xFF6B3AB9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<String> languages = ["C", "PYTHON", "JAVA", "DART"];
  final List<String> lockedLanguages = ["DART"];
  late final List<GlobalKey<FlipCardState>> cardKeys;

  String searchQuery = "";

  // AppBar Animation
  late AnimationController _appBarController;
  late Animation<Color?> colorAnimation1;
  late Animation<Color?> colorAnimation2;

  @override
  void initState() {
    super.initState();

    cardKeys = List.generate(
      languages.length,
      (_) => GlobalKey<FlipCardState>(),
    );

    Timer.periodic(const Duration(seconds: 2), (timer) {
      for (var key in cardKeys) {
        if (key.currentState != null && mounted) key.currentState!.toggleCard();
      }
    });

    // AppBar gradient animation
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
    List<String> filteredLanguages = languages
        .where((lang) => lang.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const GamingBackground(),
          Column(
            children: [
              buildAnimatedAppBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    itemCount: filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final title = filteredLanguages[index];
                      final bool isLocked = lockedLanguages.contains(title);
                      final String backImageName =
                          "${title.toLowerCase()}_back.png";
                      final originalIndex = languages.indexOf(title);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Center(
                          child: FlipCard(
                            key: cardKeys[originalIndex],
                            flipOnTouch: false,
                            direction: FlipDirection.HORIZONTAL,
                            front: buildCard(title, isLocked, backImageName),
                            back: buildCardBack(title, isLocked, backImageName),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAnimatedAppBar() {
    return AnimatedBuilder(
      animation: _appBarController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(0),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              side: const BorderSide(
                color: Colors.black,
                width: 3,
              ), // Full black border
            ),
            gradient: LinearGradient(
              colors: [colorAnimation1.value!, colorAnimation2.value!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 65,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Hello, Gamer!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Unlock levels, Unlock Skills",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyProfileScreen()),
                  );
                },
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage("assets/prof.png"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            //autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search language...',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.black54,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildCard(String title, bool isLocked, String backImageName) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          if (isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "$title is locked 🔒",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(12),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TopicsScreen(language: title)),
            );
          }
        },
        child: Stack(
          children: [
            ClipRRect(
               borderRadius: BorderRadius.circular(18),
              child: Container(
                alignment: Alignment.center,
                height: 350,
                width: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        "assets/${title.toLowerCase()}.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLocked)
              Positioned(
                top: 10,
                left: -40,
                child: Transform.rotate(
                  angle: -pi / 4,
                  child: Container(
                    width: 150,
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: const Text(
                      "LOCKED",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildCardBack(String title, bool isLocked, String backImageName) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          if (isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "$title is locked 🔒",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(12),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TopicsScreen(language: title)),
            );
          }
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                height: 300,
                width: 230,
                child: Image.asset("assets/$backImageName", fit: BoxFit.cover),
              ),
            ),
            if (isLocked)
              Positioned(
                top: 10,
                left: -40,
                child: Transform.rotate(
                  angle: -pi / 4,
                  child: Container(
                    width: 150,
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: const Text(
                      "LOCKED",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Gaming background with animated stars
class GamingBackground extends StatefulWidget {
  const GamingBackground({super.key});

  @override
  State<GamingBackground> createState() => _GamingBackgroundState();
}

class _GamingBackgroundState extends State<GamingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int numStars = 20;
  final List<Offset> positions = [];
  final List<double> speeds = [];
  final List<double> sizes = [];
  final List<Color> colors = List.filled(6, Colors.white);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    final random = Random();
    for (int i = 0; i < numStars; i++) {
      positions.add(Offset(random.nextDouble(), random.nextDouble()));
      speeds.add(0.2 + random.nextDouble() * 0.5);
      sizes.add(2.0 + random.nextDouble() * 4.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> buildStars(double width, double height) {
    List<Widget> widgets = [];
    for (int i = 0; i < numStars; i++) {
      widgets.add(
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double dx =
                (positions[i].dx * width +
                    _controller.value * speeds[i] * width) %
                width;
            double dy =
                (positions[i].dy * height +
                    _controller.value * speeds[i] * height) %
                height;
            return Positioned(
              left: dx,
              top: dy,
              child: Container(
                width: sizes[i],
                height: sizes[i],
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i % colors.length].withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: colors[i % colors.length].withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          children: [
            Container(
              width: width,
              height: height,
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
            ...buildStars(width, height),
          ],
        );
      },
    );
  }
}
