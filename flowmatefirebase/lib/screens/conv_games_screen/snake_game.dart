import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flowmatefirebase/screens/levels_screen/level_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';

class SnakeLadderGame extends StatelessWidget {
  final String language;
  final String topic;
  final String subtopic;
  final String level;
  final int levelno;

  const SnakeLadderGame({
    super.key,
    required this.language,
    required this.topic,
    required this.subtopic,
    required this.level,
    required this.levelno,
  });

  @override
  Widget build(BuildContext context) {
    return GameBoard(
      language: language,
      topic: topic,
      subtopic: subtopic,
      level: level,
      levelno: levelno,
    );
  }
}

class GameBoard extends StatefulWidget {
  final String language;
  final String topic;
  final String subtopic;
  final String level;
  final int levelno;
  const GameBoard({
    super.key,
    required this.language,
    required this.topic,
    required this.subtopic,
    required this.level,
    required this.levelno,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  int playerPos = 1;
  final random = Random();
  String message = "Roll the dice 🎲";
  int correctAnswers = 0;
  final LevelService _levelService = LevelService();
  final FlutterTts tts = FlutterTts();
  final apiKey = dotenv.env['Api_key'];
  final Map<int, int> snakes = {
    16: 6,
    47: 26,
    49: 11,
    56: 53,
    62: 19,
    87: 24,
    93: 73,
    95: 75,
    98: 78,
  };

  final Map<int, int> ladders = {
    3: 22,
    5: 8,
    15: 25,
    18: 45,
    21: 82,
    28: 53,
    36: 44,
    51: 67,
    71: 91,
    80: 99,
  };

  late ConfettiController _confettiController;
  bool diceRolling = false;
  int diceValue = 1;

  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    tts.setLanguage("en-US");
    tts.setSpeechRate(0.5);

    fetchMultipleQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void rollDice() async {
    if (diceRolling) return;
    diceRolling = true;

    int roll = random.nextInt(6) + 1;
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() => diceValue = random.nextInt(6) + 1);
    }
    diceValue = roll;

    setState(() {
      playerPos += roll;
      if (playerPos > 100) playerPos = 100;
      message = "You rolled a $roll → now on $playerPos";
    });

    diceRolling = false;

    if (playerPos < 100) {
      await checkSnakeOrLadder();
    } else {
      _confettiController.play();
      await tts.speak("🎉 Congratulations! You reached 100! You win!");
      showFinalScore();
    }
  }

  Future<void> checkSnakeOrLadder() async {
    if (snakes.containsKey(playerPos) || ladders.containsKey(playerPos)) {
      if (currentQuestionIndex >= questions.length) {
        message = "No more questions left!";
        showFinalScore();
        return;
      }

      final q = questions[currentQuestionIndex];
      final correct = await askQuestion(q);

      setState(() {
        if (snakes.containsKey(playerPos)) {
          if (correct) {
            message = "🐍 You avoided the snake!";
            correctAnswers++;
          } else {
            playerPos = snakes[playerPos]!;
            message = "❌ Wrong! Snake bit you → down to $playerPos";
          }
        } else if (ladders.containsKey(playerPos)) {
          if (correct) {
            playerPos = ladders[playerPos]!;
            message = "✅ Correct! Climbed ladder → up to $playerPos";
            correctAnswers++;
          } else {
            message = "❌ Wrong! Missed the ladder.";
          }
        }
        currentQuestionIndex++;
      });

      await tts.speak(message);

      if (currentQuestionIndex >= questions.length) {
        showFinalScore();
      }
    }
  }

  Future<void> fetchMultipleQuestions() async {
    for (int i = 0; i < 15; i++) {
      final q = await fetchAIQuestion();
      questions.add(q);
    }
    setState(() {});
  }

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
    List<Map<String, dynamic>> fallbackQuestions = [
      {
        "question": "What is the output of print(2 ** 3) in Python?",
        "options": ["5", "6", "8", "9"],
        "answerIndex": 2,
      },
      // {
      //   "question": "Which of the following is a valid variable name in C?",
      //   "options": ["2count", "_count", "count#", "count-num"],
      //   "answerIndex": 1,
      // },
      // {
      //   "question": "Which tag is used to create a hyperlink in HTML?",
      //   "options": ["<a>", "<link>", "<href>", "<url>"],
      //   "answerIndex": 0,
      // },
      // {
      //   "question": "What does CSS stand for?",
      //   "options": [
      //     "Cascading Style Sheets",
      //     "Colorful Style Syntax",
      //     "Computer Styling System",
      //     "Creative Sheet Styles",
      //   ],
      //   "answerIndex": 0,
      // },
      // {
      //   "question": "Which keyword is used to define a function in Python?",
      //   "options": ["def", "function", "fun", "define"],
      //   "answerIndex": 0,
      // },
      // {
      //   "question": "Which data structure works on LIFO principle?",
      //   "options": ["Queue", "Stack", "Array", "Linked List"],
      //   "answerIndex": 1,
      // },
      // {
      //   "question": "In C, what is the size of int on most 32-bit systems?",
      //   "options": ["2 bytes", "4 bytes", "8 bytes", "1 byte"],
      //   "answerIndex": 1,
      // },
      // {
      //   "question": "Which operator is used to compare two values in Java?",
      //   "options": ["=", "==", "===", "!="],
      //   "answerIndex": 1,
      // },
      // {
      //   "question": "In Flutter, which widget is used for scrollable content?",
      //   "options": ["Column", "ListView", "Container", "Stack"],
      //   "answerIndex": 1,
      // },
      {
        "question": "Which symbol is used to start comments in Python?",
        "options": ["//", "#", "/* */", "--"],
        "answerIndex": 1,
      },
    ];

    final randomIndex = Random().nextInt(fallbackQuestions.length);
    return fallbackQuestions[randomIndex];
  }

  Future<bool> askQuestion(Map<String, dynamic> q) async {
    const Color gold = Color(0xFFFFD24A);
    const Color darkSurface = Color(0xFF2E3236);
    const Color cyberBlue = Color(0xFF4DD0E1);

    bool result = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: gold, width: 2.0),
          ),
          title: Row(
            children: const [
              Icon(Icons.flash_on, color: gold, size: 28),
              SizedBox(width: 10),
              Text(
                "Challenge",
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                q["question"],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...q["options"].asMap().entries.map((entry) {
                int idx = entry.key;
                String option = entry.value;
                return ElevatedButton(
                  onPressed: () {
                    result = idx == q["answerIndex"];
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: cyberBlue, width: 2),
                  ),
                  child: Text(option),
                );
              }),
            ],
          ),
        );
      },
    );
    return result;
  }

  // firebase usageeee
  Future<void> showFinalScore() async {
    await _levelService.updateLevelInFirebase(
      language: widget.language,
      topic: widget.topic,
      levelNumber: widget.levelno,
      total: currentQuestionIndex,
      answered: correctAnswers,
      isCompleted: true,
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "🏆 Game Over",
            style: TextStyle(color: Colors.amber),
          ),
          content: Text(
            "You got $correctAnswers out of $currentQuestionIndex correct!",
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: ()async {
                // Navigator.popUntil(
                //   context,
                //   ModalRoute.withName('LevelsScreen'),
                // );
                //Navigator.popUntil(context,ModalRoute.withName('ConversationScreen'));
                  await tts.stop(); 
                 Navigator.pop(context); 
                Navigator.pop(context, true);

              },
              child: Text("Go to levels", style: TextStyle(color: Colors.cyan)),
            ),
          ],
        );
      },
    );
  }

  Widget buildCell(int num) {
    bool isPlayerHere = num == playerPos;
    bool isSnake = snakes.containsKey(num);
    bool isLadder = ladders.containsKey(num);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient:
            isPlayerHere
                ? const LinearGradient(
                  colors: [Colors.teal, Colors.cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : const LinearGradient(
                  colors: [Colors.black87, Colors.black54],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "$num",
            style: TextStyle(
              fontSize: isPlayerHere ? 16 : 11,
              color: isPlayerHere ? Colors.white : Colors.white54,
              fontWeight: isPlayerHere ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSnake)
            const Text(
              "🐍",
              style: TextStyle(fontSize: 22, color: Colors.redAccent),
            ),
          if (isLadder)
            const Text(
              "🪜",
              style: TextStyle(fontSize: 22, color: Colors.amber),
            ),
          if (isPlayerHere)
            const Icon(Icons.circle, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Increased height
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(40), // Curved bottom
          ),
          child: AppBar(
            backgroundColor: Colors.deepPurple,
            centerTitle: true,
            title: const Text(
              "🐍 Snake & Ladder AI",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            elevation: 4,
          ),
        ),
      ),

      body: Stack(
        children: [
          GridView.builder(
            padding: EdgeInsets.only(
              top: kToolbarHeight + 16,
              left: 2,
              right: 2,
              bottom: 2,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
            ),
            itemCount: 100,
            itemBuilder: (context, index) {
              int num = 100 - index;
              return buildCell(num);
            },
          ),
          Positioned(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).size.height * 0.60,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    "✅ Correct answers: $correctAnswers",
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  ElevatedButton.icon(
                    onPressed: playerPos == 100 ? null : rollDice,
                    icon: const Icon(Icons.casino),
                    label: Text(
                      diceRolling ? "Rolling..." : "Roll Dice ($diceValue)",
                      style: const TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
