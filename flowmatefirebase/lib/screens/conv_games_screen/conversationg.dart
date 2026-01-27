import 'dart:async';
import 'dart:convert';
import 'package:flowmatefirebase/screens/conv_games_screen/car_game.dart';
import 'package:flowmatefirebase/screens/conv_games_screen/snake_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';

class ConversationScreen extends StatefulWidget {
  final String language;
  final String topic;
  final String subtopic;
  final String level;
  final int levelnum;
  const ConversationScreen({
    super.key,
    required this.language,
    required this.topic,
    required this.subtopic,
    required this.level,
    required this.levelnum,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with TickerProviderStateMixin {
  final apiKey = dotenv.env['Api_key'];
  final FlutterTts tts = FlutterTts();
  List<dynamic> _availableVoices = [];
  Map<String, dynamic>? _girlVoice;
  Map<String, dynamic>? _boyVoice;
  Completer<void>? _speechCompleter;

  final List<Map<String, String>> chat = [];
  bool isTyping = false;
  int qaCount = 0;
  final int maxQA = 3;
  late AnimationController _bgController;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  // FAB animation
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _initTts();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      generateQuestion();
    });

    // Gradient animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _color1 = ColorTween(
      begin: Colors.indigo.shade600,
      end: Colors.blueAccent,
    ).animate(_bgController);
    _color2 = ColorTween(
      begin: const Color.fromARGB(255, 183, 43, 127),
      end: Colors.deepPurpleAccent,
    ).animate(_bgController);

    // FAB pulse animation
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _fabScale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      await tts.stop(); // Stop when back button pressed
      return true;
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fabController.dispose();
    qaCount = maxQA;
    _speechCompleter?.complete();
    tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await tts.setLanguage("en-US");
      await tts.setSpeechRate(0.5);
      tts.setCompletionHandler(() {
        if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
          _speechCompleter!.complete();
        }
      });

      final voices = await tts.getVoices;
      _availableVoices = voices is List ? voices : (voices as dynamic).toList();

      for (var v in _availableVoices) {
        final name = (v['name'] ?? v['voice'] ?? '').toString().toLowerCase();
        if (_girlVoice == null &&
            (name.contains('female') || name.contains('girl'))) {
          _girlVoice = Map<String, dynamic>.from(v);
        }
        if (_boyVoice == null &&
            (name.contains('male') || name.contains('boy'))) {
          _boyVoice = Map<String, dynamic>.from(v);
        }
      }

      if (_girlVoice == null && _availableVoices.isNotEmpty)
        _girlVoice = Map.from(_availableVoices.first);
      if (_boyVoice == null && _availableVoices.length > 1)
        _boyVoice = Map.from(_availableVoices[1]);
    } catch (e) {
      print("TTS init error: $e");
    }
  }

  Future<void> generateQuestion() async {
    if (qaCount >= maxQA) return;
    if (!mounted) return;
    setState(() => isTyping = true);

    final qPrompt =
        "Generate ONE simple, beginner-friendly question in ${widget.language} "
        "about '${widget.topic} → ${widget.subtopic}' for an ${widget.level} level student. "
        "Focus on definition-style questions (e.g., start with 'What is ${widget.subtopic}?' and explain if any types of ${widget.subtopic}). "
        "Keep the question very short and clear (max 2 lines). "
        "Do not repeat previously asked questions and must not the questions having same meanings repeat again and again. "
        "If the student is new, add a very brief introductory line before the question.";
    final question = await fetchFromGemini(qPrompt);
    if (question.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        chat.add({"role": "girl", "text": question});
        isTyping = false;
      });

      await speak(question, isGirl: true);

      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      generateAnswer(question);
    }
  }

  Future<void> generateAnswer(String question) async {
    if (!mounted) return;
    setState(() => isTyping = true);

    final aPrompt =
        ''' Answer the following ${widget.level}-level ${widget.language} question from the topic "${widget.topic} → ${widget.subtopic}". Question: $question Guidelines: 1. Keep the explanation very simple and beginner-friendly. 2. Use clear, plain language (avoid jargon). 3. Answer length must be under 7 lines. 4. If relevant, include a tiny example (max 3 lines). 5. Do not add unnecessary details. 6. Mostly avoid symbols like (triple quotes) and (`); use spaces or plain text formatting instead. 7.do not repeat the question having same meaning.make of them unique. ''';
    final answer = await fetchFromGemini(aPrompt);
    if (answer.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        chat.add({"role": "boy", "text": answer});
        isTyping = false;
      });

      await speak(answer, isGirl: false);
      qaCount++;
      if (qaCount < maxQA)
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          generateQuestion();
        });
    }
  }

  Future<String> fetchFromGemini(String prompt) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

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
        return data["candidates"][0]["content"]["parts"][0]["text"] ?? "";
      } else {
        return "⚠ Error: ${response.statusCode}";
      }
    } catch (e) {
      return "⚠ Failed: $e";
    }
  }

  Future<void> speak(String text, {required bool isGirl}) async {
    try {
      await tts.stop();
      _speechCompleter = Completer<void>();

      final chosen =
          isGirl
              ? _girlVoice ??
                  (_availableVoices.isNotEmpty ? _availableVoices.first : null)
              : _boyVoice ??
                  (_availableVoices.length > 1
                      ? _availableVoices[1]
                      : (_availableVoices.isNotEmpty
                          ? _availableVoices.first
                          : null));

      if (chosen != null) {
        Map<String, String> voiceToSet = {};
        chosen.forEach((k, v) => voiceToSet[k.toString()] = v.toString());
        await tts.setVoice(voiceToSet);
      }
      await tts.speak(text);
      await _speechCompleter?.future;
    } catch (e) {
      print("TTS speak error: $e");
    } finally {
      _speechCompleter = null;
    }
  }

  Widget buildBubble(String text, bool isGirl) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder:
          (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: child,
            ),
          ),
      child: Row(
        key: ValueKey(text),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isGirl ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isGirl)
            const CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                "https://cdn-icons-png.flaticon.com/512/921/921087.png",
              ),
            ),
          if (isGirl) const SizedBox(width: 8),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient:
                    isGirl
                        ? LinearGradient(
                          colors: [Colors.purpleAccent, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : LinearGradient(
                          colors: [Colors.black87, Colors.grey.shade800],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isGirl ? Colors.white : Colors.cyan.shade100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!isGirl) const SizedBox(width: 8),
          if (!isGirl)
            const CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                "https://cdn-icons-png.flaticon.com/512/236/236832.png",
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final gradientColors = [_color1.value!, _color2.value!];
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(38),
                bottomRight: Radius.circular(38),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFFE040FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.transparent, // black bottom line
                      width: 4,
                    ),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      offset: Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "Hello, Gamer!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Unlock levels, Unlock Skills",
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 130),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: chat.length,
                      itemBuilder: (context, index) {
                        final msg = chat[index];
                        final isGirl = msg["role"] == "girl";
                        return buildBubble(msg["text"]!, isGirl);
                      },
                    ),
                  ),
                  if (isTyping)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "✨ AI is thinking...",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ),
                ],
              ),
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabScale,
            child: FloatingActionButton(
              onPressed: () async {
                await tts.stop();
                final List<Widget Function()> gameScreens = [
                  () => SnakeLadderGame(
                    language: widget.language,
                    topic: widget.topic,
                    subtopic: widget.subtopic,
                    level: widget.level,
                    levelno: widget.levelnum,
                  ),
                  // () => RaceGameApp(
                  //   language: widget.language,
                  //   topic: widget.topic,
                  //   subtopic: widget.subtopic,
                  //   level: widget.level,
                  //   levelno: widget.levelnum,
                  // ),
                ];
                final randomIndex = Random().nextInt(gameScreens.length);
                final selectedScreen = gameScreens[randomIndex]();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🎮 Game Mode Activated!")),
                );
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => selectedScreen,
                    settings: RouteSettings(name: 'GameScreen'),
                  ),
                );
                if (result == true) {
                  Navigator.pop(context, true);
                }
              },
              backgroundColor: Colors.deepPurpleAccent,
              elevation: 8,
              child: const Text("🎮", style: TextStyle(fontSize: 30)),
            ),
          ),
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        );
      },
    );
  }
}
