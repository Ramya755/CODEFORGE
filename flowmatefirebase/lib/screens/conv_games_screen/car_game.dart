import 'dart:convert';
import 'dart:math';
import 'package:flowmatefirebase/screens/levels_screen/level_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RaceGameApp extends StatelessWidget {
  final String language;
  final String topic;
  final String subtopic;
  final String level;
  final int levelno;
  const RaceGameApp({
    super.key,
    required this.language,
    required this.topic,
    required this.subtopic,
    required this.level,
    required this.levelno,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RaceGame(
        language: language,
        topic: topic,
        subtopic: subtopic,
        level: level,
        levelno: levelno,
      ),
    );
  }
}

class RaceGame extends StatefulWidget {
  final String language;
  final String topic;
  final String subtopic;
  final String level;
  final int levelno;
  const RaceGame({
    super.key,
    required this.language,
    required this.topic,
    required this.subtopic,
    required this.level,
    required this.levelno,
  });

  @override
  _RaceGameState createState() => _RaceGameState();
}

class _RaceGameState extends State<RaceGame>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> carX = ValueNotifier(0.0);
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<List<Obstacle>> obstacles = ValueNotifier([]);
  final ValueNotifier<QuestionBox?> activeQuestion = ValueNotifier(null);
  final ValueNotifier<String?> feedbackMessage = ValueNotifier(null);
  final LevelService _levelService = LevelService();
  final double carWidth = 0.3;
  final double finishLine = 500.0;

  late Ticker _ticker;
  Random random = Random();
  int frameCount = 0;
  bool isPaused = false;

  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int correctAnswers = 0;

  final apiKey = dotenv.env['Api_key'];
  Set<String> askedQuestions = {};

  @override
  void initState() {
    super.initState();

    obstacles.value = List.generate(6, (_) {
      return Obstacle(
        x: (random.nextDouble() * 1.6) - 0.8,
        screenY: random.nextDouble() * -1.5,
      );
    });

    _ticker = createTicker(_updateGame)..start();

    fetchMultipleQuestions(); // prefetch 10 unique questions
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Prefetch 10 unique AI questions
  Future<void> fetchMultipleQuestions() async {
    while (questions.length < 10) {
      final q = await fetchAIQuestion();
      if (q["question"] != null &&
          !questions.any((existing) => existing["question"] == q["question"])) {
        questions.add(q);
      }
    }
  }

  /// Fetch AI question from Gemini
  Future<Map<String, dynamic>> fetchAIQuestion() async {
    final prompt = '''
You are a quiz generator. 
Task: Create a UNIQUE beginner-friendly ${widget.language} question about "${widget.topic} → ${widget.subtopic}".
Difficulty: ${widget.level}.

Guidelines:
1. Alternate between theory (concept-based) and problem-solving style questions. 
2. Do NOT repeat previously asked questions. Always generate a new one.
3. Ensure the question is clear and short.
4. Provide exactly 4 answer options, all different and realistic.
5. Mark the correct answer using its index (0-based).
6. Response format must be ONLY valid JSON:
{
  "question": "Your question?",
  "options": ["Option1","Option2","Option3","Option4"],
  "answerIndex": 0
}
Do not add extra text or explanations outside JSON.
''';

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey");
    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text =
            data["candidates"][0]["content"]["parts"][0]["text"] ?? "{}";
        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start >= 0 && end > start) {
          return jsonDecode(text.substring(start, end + 1));
        }
      }
    } catch (_) {}

    // fallback question
    List<Map<String, dynamic>> fallbackQuestions = [
      {
        "question": "What is the output of print(2 ** 3) in Python?",
        "options": ["5", "6", "8", "9"],
        "answerIndex": 2,
      },
      {
        "question": "Which of the following is a valid variable name in C?",
        "options": ["2count", "_count", "count#", "count-num"],
        "answerIndex": 1,
      },
      {
        "question": "Which tag is used to create a hyperlink in HTML?",
        "options": ["<a>", "<link>", "<href>", "<url>"],
        "answerIndex": 0,
      },
      {
        "question": "What does CSS stand for?",
        "options": [
          "Cascading Style Sheets",
          "Colorful Style Syntax",
          "Computer Styling System",
          "Creative Sheet Styles",
        ],
        "answerIndex": 0,
      },
      {
        "question": "Which keyword is used to define a function in Python?",
        "options": ["def", "function", "fun", "define"],
        "answerIndex": 0,
      },
      {
        "question": "Which data structure works on LIFO principle?",
        "options": ["Queue", "Stack", "Array", "Linked List"],
        "answerIndex": 1,
      },
      {
        "question": "In C, what is the size of int on most 32-bit systems?",
        "options": ["2 bytes", "4 bytes", "8 bytes", "1 byte"],
        "answerIndex": 1,
      },
      {
        "question": "Which operator is used to compare two values in Java?",
        "options": ["=", "==", "===", "!="],
        "answerIndex": 1,
      },
      {
        "question": "In Flutter, which widget is used for scrollable content?",
        "options": ["Column", "ListView", "Container", "Stack"],
        "answerIndex": 1,
      },
      {
        "question": "Which symbol is used to start comments in Python?",
        "options": ["//", "#", "/* */", "--"],
        "answerIndex": 1,
      },
    ];

    final randomIndex = Random().nextInt(fallbackQuestions.length);
    return fallbackQuestions[randomIndex];
  }

  void _updateGame(Duration elapsed) async {
    if (isPaused) return;

    progress.value += 0.2;

    final obsList = obstacles.value;

    // Iterate through obstacles
    for (var obs in obsList) {
      // 🐢 Adjust fall speed
      obs.screenY += 0.0025; // slower fall

      // Reset obstacle after going off-screen
      if (obs.screenY > 1.2) {
        obs.screenY = -0.2;
        obs.x = (random.nextDouble() * 1.6) - 0.8;
        obs.hit = false;
      }

      // 🚗 Car position
      const double carY = 0.9;
      const double carHeight = 0.12;
      const double carWidth = 0.25;
      final double carTop = carY - carHeight / 2;
      final double carBottom = carY + carHeight / 2;

      // 🎯 Check collision
      final bool overlapX = (obs.x - carX.value).abs() < carWidth / 2;
      final bool overlapY = obs.screenY >= carTop && obs.screenY <= carBottom;

      if (!obs.hit && overlapX && overlapY) {
        obs.hit = true; // Mark hit to avoid repeat triggers

        // 🧠 Ask question popup
        await _askQuestion(obs);

        // Reset obstacle to a new random position after answering
        obs.screenY = -0.2;
        obs.x = (random.nextDouble() * 1.6) - 0.8;
        obs.hit = false;

        break; // Stop checking other obstacles this frame
      }
    }

    // Add new obstacle every 80 frames
    frameCount++;
    if (frameCount % 80 == 0) {
      obsList.add(
        Obstacle(x: (random.nextDouble() * 1.6) - 0.8, screenY: -0.2),
      );
    }

    obstacles.value = List.of(obsList);

    // 🚩 Check finish line
    if (progress.value >= finishLine) {
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _showFinalScorePopup();
      });
    }
  }

  Future<void> _askQuestion(Obstacle obs) async {
    // Pick first unasked question
    final remaining =
        questions
            .where((q) => !askedQuestions.contains(q["question"]))
            .toList();

    Map<String, dynamic> q;
    if (remaining.isEmpty) {
      // fetch a new unique question or fallback
      int retry = 0;
      do {
        q = await fetchAIQuestion();
        retry++;
        if (retry > 5) break; // avoid infinite loop
      } while (askedQuestions.contains(q["question"]));
    } else {
      q = remaining.first;
    }

    askedQuestions.add(q["question"]);
    isPaused = true;
    obs.hit = true;

    activeQuestion.value = QuestionBox(
      question: q["question"],
      options: List<String>.from(q["options"]),
      answer: q["options"][q["answerIndex"]],
      onAnswered: (correct) async {
        currentQuestionIndex++;
        if (correct)
          correctAnswers++;
        else
          progress.value = max(0, progress.value - 2);

        await _showFeedback(correct);
        activeQuestion.value = null;
        isPaused = false;
      },
    );
  }

  Future<void> _showFeedback(bool correct) async {
    if (!mounted) return;
    feedbackMessage.value = correct ? "✅ Correct!" : "❌ Wrong!";
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    feedbackMessage.value = null;
  }

  void _restartGame() {
    carX.value = 0.0;
    progress.value = 0.0;
    frameCount = 0;
    isPaused = false;
    currentQuestionIndex = 0;
    correctAnswers = 0;
    askedQuestions.clear();

    obstacles.value = List.generate(10, (_) {
      return Obstacle(
        x: (random.nextDouble() * 1.6) - 0.8,
        screenY: random.nextDouble() * -1.5,
      );
    });

    _ticker.start();
  }

  /// firebase usageeee..
  void _showFinalScorePopup() async {
    await _levelService.updateLevelInFirebase(
      language: widget.language,
      topic: widget.topic,
      levelNumber: widget.levelno,
      total: currentQuestionIndex,
      answered: correctAnswers,
      isCompleted: true,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text("🎉 Congratulations!"),
            content: Text(
              "You answered $correctAnswers out of $currentQuestionIndex correctly!",
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog only
                  _restartGame(); // Restart the race cleanly
                },
                child: const Text("Restart"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('LevelsScreen'),
                  );
                },
                child: Text("Back"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          carX.value += details.delta.dx / screenW * 2;
          carX.value = carX.value.clamp(-0.8, 0.8);
        },
        child: Stack(
          children: [
            // Finish banner
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "🏁 Finish",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ),
            // Obstacles
            ValueListenableBuilder<List<Obstacle>>(
              valueListenable: obstacles,
              builder: (_, obsList, __) {
                return Stack(
                  children:
                      obsList.map((obs) {
                        double posX = (screenW / 2) + obs.x * screenW / 2 - 30;
                        double posY = screenH * obs.screenY - 20;
                        return Positioned(
                          left: posX,
                          top: posY,
                          child: Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: obs.hit ? Colors.grey : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            ),
            // Car
            ValueListenableBuilder<double>(
              valueListenable: carX,
              builder: (_, cx, __) {
                return Positioned(
                  bottom: 40,
                  left: (screenW / 2) + cx * screenW / 2 - 28,
                  child: const Icon(
                    Icons.directions_car,
                    size: 100,
                    color: Colors.blue,
                  ),
                );
              },
            ),
            // Progress
            ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (_, prog, __) {
                return Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: LinearProgressIndicator(
                    value: (prog / finishLine).clamp(0.0, 1.0),
                    minHeight: 10,
                    valueColor: const AlwaysStoppedAnimation(
                      Colors.greenAccent,
                    ),
                    backgroundColor: Colors.white12,
                  ),
                );
              },
            ),
            // Question popup
            ValueListenableBuilder<QuestionBox?>(
              valueListenable: activeQuestion,
              builder: (_, qb, __) {
                return IgnorePointer(
                  ignoring: qb == null,
                  child: AnimatedOpacity(
                    opacity: qb == null ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Center(child: qb ?? const SizedBox()),
                  ),
                );
              },
            ),
            // Feedback popup
            ValueListenableBuilder<String?>(
              valueListenable: feedbackMessage,
              builder: (_, msg, __) {
                return Center(
                  child: AnimatedOpacity(
                    opacity: msg == null ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child:
                        msg == null
                            ? const SizedBox()
                            : Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    msg.contains("Correct")
                                        ? Colors.green
                                        : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg,
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double screenY;
  bool hit = false;
  Obstacle({required this.x, required this.screenY});
}

class QuestionBox extends StatelessWidget {
  final String question;
  final List<String> options;
  final String answer;
  final void Function(bool correct) onAnswered;

  const QuestionBox({
    super.key,
    required this.question,
    required this.options,
    required this.answer,
    required this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Colors.blueAccent],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ...options.map((opt) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => onAnswered(opt == answer),
                  child: Text(opt),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
