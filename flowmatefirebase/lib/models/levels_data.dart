class ConceptsLevels {
  static String safeKey(String key) {
    return key
        .replaceAll('/', '_')
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll('\$', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_');
  }

  static Map<String, dynamic> generateLevels() {
    final Map<String, dynamic> levels = {};
    for (int i = 1; i <= 15; i++) {
      levels["level$i"] = {"total": 0, "answered": 0, "isCompleted": false};
    }
    return levels;
  }

  static final Map<String, Map<String, dynamic>> _cLanguageConcepts = {
    safeKey("Variables & Data Types"): generateLevels(),
    safeKey("Control Flow"): generateLevels(),
    safeKey("Functions"): generateLevels(),
    safeKey("Arrays & Strings"): generateLevels(),
    safeKey("Pointers"): generateLevels(),
    safeKey("Memory Management"): generateLevels(),
    safeKey("Structures & Unions"): generateLevels(),
    safeKey("File Handling"): generateLevels(),
    safeKey("Preprocessors"): generateLevels(),
    safeKey("Advanced Concepts"): generateLevels(),
  };

  static final Map<String, Map<String, dynamic>> _pythonLanguageConcepts = {
    safeKey("Variables & Data Types"): generateLevels(),
    safeKey("Control Flow"): generateLevels(),
    safeKey("Functions"): generateLevels(),
    safeKey("Data Structures"): generateLevels(),
    safeKey("Strings"): generateLevels(),
    safeKey("Modules & Packages"): generateLevels(),
    safeKey("File Handling"): generateLevels(),
    safeKey("Object-Oriented Programming"): generateLevels(),
    safeKey("Exception Handling"): generateLevels(),
    safeKey("Advanced Topics"): generateLevels(),
    safeKey("Data Science & Libraries"): generateLevels(),
    safeKey("File & OS Operations"): generateLevels(),
  };

  static final Map<String, Map<String, dynamic>> _javaLanguageConcepts = {
    safeKey("Basics & Syntax"): generateLevels(),
    safeKey("Control Flow"): generateLevels(),
    safeKey("Functions & Methods"): generateLevels(),
    safeKey("Object-Oriented Programming"): generateLevels(),
    safeKey("Arrays & Strings"): generateLevels(),
    safeKey("Collections Framework"): generateLevels(),
    safeKey("Exception Handling"): generateLevels(),
    safeKey("File Handling & I/O"): generateLevels(),
    safeKey("Multithreading"): generateLevels(),
    safeKey("Memory Management"): generateLevels(),
    safeKey("Advanced Concepts"): generateLevels(),
  };

  static final Map<String, Map<String, Map<String, dynamic>>>
  conceptsByLanguage = {
    "C": _cLanguageConcepts,
    "JAVA": _javaLanguageConcepts,
    "PYTHON": _pythonLanguageConcepts,
  };

  /// Get subtopics for a given topic (15 subtopics)
  static List<String> getSubtopics(String language, String topic) {
    return List<String>.generate(15, (i) => "Subtopic for Level ${i + 1}");
  }

  /// Get levels for a topic
  static Map<String, dynamic> getLevels(String language, String topic) {
    return conceptsByLanguage[language]?[topic] ?? {};
  }

  /// Get all languages
  static List<String> getLanguages() {
    return conceptsByLanguage.keys.toList();
  }

  /// Get all topics of a language
  static List<String> getTopics(String language) {
    return conceptsByLanguage[language]?.keys.toList() ?? [];
  }

  /// Update a specific level’s progress
  static void updateLevel(
    String language,
    String topic,
    String level, {
    int? total,
    int? answered,
    bool? isCompleted,
  }) {
    final levelData = conceptsByLanguage[language]?[topic]?[level];
    if (levelData != null) {
      if (total != null) levelData["total"] = total;
      if (answered != null) levelData["answered"] = answered;
      if (isCompleted != null) levelData["isCompleted"] = isCompleted;
    }
  }

  /// Converts full map to JSON (useful when saving to Firebase manually)
  static Map<String, dynamic> toJson() => conceptsByLanguage;

  ///  Recreates from JSON (useful when reading back from Firebase)
  static Map<String, Map<String, Map<String, dynamic>>> fromJson(
    Map<String, dynamic> json,
  ) {
    return json.map((lang, topics) {
      return MapEntry(lang, Map<String, Map<String, dynamic>>.from(topics));
    });
  }
}
