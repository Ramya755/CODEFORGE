import 'package:flowmatefirebase/models/language_topics_data.dart';
import 'package:flowmatefirebase/models/practice_links.dart';
import 'package:flowmatefirebase/screens/conv_games_screen/conversationg.dart';
import 'package:flowmatefirebase/screens/home_screens/topics_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:confetti/confetti.dart';
import 'level_service.dart';
import 'ui_component.dart';

class LevelsScreen extends StatefulWidget {
  final String language;
  final String topic;

  const LevelsScreen({super.key, required this.language, required this.topic});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen>
    with TickerProviderStateMixin {
  int levelnum = 0;
  final LevelService _levelService = LevelService();
  late Future<Map<String, dynamic>> _levelsFuture;
  late final List<String> _subtopics;
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 1),
  );
  late AnimationController _bgPulseController;

  @override
  void initState() {
    super.initState();
    _subtopics = ConceptsR.getSubtopics(widget.language, widget.topic);
    _loadLevelData();

    _bgPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  void _loadLevelData() {
    setState(() {
      _levelsFuture = _levelService.loadLevels(widget.language, widget.topic);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _bgPulseController.dispose();
    super.dispose();
  }

  Future<void> _onLevelTap(int levelNumber, bool isLocked) async {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complete previous levels to unlock!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String diffcultlevel = '';
    if (levelNumber > 0 && levelNumber <= 5) {
      diffcultlevel = "Easy";
    } else if (levelNumber > 5 && levelNumber <= 10) {
      diffcultlevel = "Medium";
    } else {
      diffcultlevel = "Hard";
    }

    final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ConversationScreen(
        language: widget.language,
        topic: widget.topic,
        subtopic: _subtopics[levelNumber - 1],
        level: diffcultlevel,
        levelnum: levelNumber,
      ),
    ),
  );

  // Game returns true → refresh level screen
  if (result == true && mounted) {
    _loadLevelData();
    await _showRewardIfNeeded(levelNumber);
  }
    // if (result != null &&
    //     result.containsKey('answered') &&
    //     result.containsKey('total') &&
    //     mounted) {
    //   await _levelService.updateLevel(
    //     widget.language,
    //     widget.topic,
    //     levelNumber,
    //     result['answered']!,
    //     result['total']!,
    //   );

    //   _loadLevelData();
    //   await _showRewardIfNeeded(levelNumber);
    // }
  }

  Future<void> _showRewardIfNeeded(int justCompletedLevel) async {
    if (!mounted) return;

    final subtopicName = _subtopics[justCompletedLevel - 1];
    final practiceLinkUrl = PracticeLinks.getLinkForLevel(
      widget.language,
      widget.topic,
      justCompletedLevel,
    );

    // Milestone rewards: 5, 10, 15
    if (justCompletedLevel % 5 == 0) {
      _confettiController.play();

      if (justCompletedLevel == 5) {
        await showDialog(
          context: context,
          builder:
              (_) => const MedalOverlay(
                medalType: MedalType.bronze,
                title: "Bronze Warrior",
                quote:
                    "A warrior is not born from victory, but from the courage to begin.",
              ),
        );

        if (!mounted) return;

        await showDialog(
          context: context,
          builder:
              (_) => LinkOverlay(
                title: "Level 5 Practice Link!",
                quote:
                    "Here's a link to consolidate your knowledge on '$subtopicName'.",
                linkTitle: "Practice: $subtopicName",
                linkUrl: practiceLinkUrl,
              ),
        );
      } else if (justCompletedLevel == 10) {
        await showDialog(
          context: context,
          builder:
              (_) => const MedalOverlay(
                medalType: MedalType.silver,
                title: "Silver Sentinel",
                quote: "Forge ahead — steel is shaped by fire and resolve.",
              ),
        );

        if (!mounted) return;

        await showDialog(
          context: context,
          builder:
              (_) => LinkOverlay(
                title: "Level 10 Practice Link!",
                quote: "Master '$subtopicName' with this advanced problem set.",
                linkTitle: "Practice: $subtopicName",
                linkUrl: practiceLinkUrl,
              ),
        );
      } else if (justCompletedLevel == 15) {
        await showDialog(
          context: context,
          builder:
              (_) => const MedalOverlay(
                medalType: MedalType.gold,
                title: "Golden Conqueror",
                quote:
                    "You rise by lifting your limits. Shine, conquer, continue.",
              ),
        );

        if (!mounted) return;

        await showDialog(
          context: context,
          builder:
              (_) => const ShieldOverlay(
                title: "Warrior",
                quote:
                    "Levels end, learning doesn't. Wear this shield — keep growing.",
              ),
        );

        if (!mounted) return;

        await showDialog(
          context: context,
          builder:
              (_) => LinkOverlay(
                title: "Level 15 Practice Link!",
                quote:
                    "Your final challenge on '$subtopicName' is here. Conquer it!",
                linkTitle: "Practice: $subtopicName",
                linkUrl: practiceLinkUrl,
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          const FloatingParticles(),
          AnimatedBuilder(
            animation: _bgPulseController,
            builder: (context, _) {
              final t = _bgPulseController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(
                        const Color(0xFF07060A),
                        const Color(0xFF0B1020),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFF071028),
                        const Color(0xFF12001E),
                        1 - t,
                      )!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _levelsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error loading levels: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            "No levels found.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      final levelsMap = snapshot.data!;
                      final levelKeys =
                          levelsMap.keys.toList()..sort((a, b) {
                            final aNum = int.tryParse(a.substring(5)) ?? 0;
                            final bNum = int.tryParse(b.substring(5)) ?? 0;
                            return aNum.compareTo(bNum);
                          });

                      final completedCount =
                          levelsMap.values
                              .where((data) => data['isCompleted'] == true)
                              .length;
                      final nextLevelToUnlock = completedCount + 1;

                      return AnimationLimiter(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                          itemCount: levelKeys.length,
                          itemBuilder: (context, index) {
                            final levelKey = levelKeys[index];
                            final levelData = levelsMap[levelKey] ?? {};
                            final levelNumber =
                                int.tryParse(levelKey.substring(5)) ??
                                index + 1;

                            final isCompleted =
                                levelData['isCompleted'] ?? false;
                            final isLocked = levelNumber > nextLevelToUnlock;
                            final isCurrent = levelNumber == nextLevelToUnlock;

                            return AnimationConfiguration.staggeredGrid(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              columnCount: 3,
                              child: ScaleAnimation(
                                child: FadeInAnimation(
                                  child: LevelTile(
                                    level: levelNumber,
                                    isLocked: isLocked,
                                    isCompleted: isCompleted,
                                    isCurrent: isCurrent,
                                    onTap: () {
                                      levelnum = levelNumber;
                                      _onLevelTap(levelNumber, isLocked);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          Expanded(
            child: Text(
              widget.topic,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 48), // Space to balance back button
        ],
      ),
    );
  }
}
