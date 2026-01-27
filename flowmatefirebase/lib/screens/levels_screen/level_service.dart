import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flowmatefirebase/models/levels_data.dart';

class LevelService {
  final DatabaseReference _dbRef;
  final String _uid;

  LevelService()
      : _uid = FirebaseAuth.instance.currentUser!.uid,
        _dbRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(FirebaseAuth.instance.currentUser!.uid)
            .child('concepts'); // ✔ matches your Firebase screenshot

  /// Save/Update level in Firebase
  Future<void> updateLevelInFirebase({
    required String language,
    required String topic,
    required int levelNumber,
    required int total,
    required int answered,
    required bool isCompleted,
  }) async {
    final levelKey = "level$levelNumber";

    try {
      await _dbRef
          .child(language)
          .child(topic)
          .child(levelKey)
          .update({
        'total': total,
        'answered': answered,
        'isCompleted': isCompleted,
      });

      print("✔ Firebase updated at users/$_uid/concepts/$language/$topic/$levelKey");
    } catch (e) {
      print("❌ Error updating Firebase: $e");
    }
  }

  /// Load all levels for a topic
  Future<Map<String, dynamic>> loadLevels(String language, String topic) async {
    final ref = _dbRef.child(language).child(topic);
    final snapshot = await ref.get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }

    // No levels found → create default levels
    final defaultLevels = ConceptsLevels.getLevels(language, topic);

    await ref.set(defaultLevels);

    print("✔ Default levels created for $language → $topic");

    return defaultLevels;
  }

  /// Update a single level and mark completed
  Future<void> updateLevel(
    String language,
    String topic,
    int levelNumber,
    int answeredQuestions,
    int totalQuestions,
  ) async {
    await updateLevelInFirebase(
      language: language,
      topic: topic,
      levelNumber: levelNumber,
      total: totalQuestions,
      answered: answeredQuestions,
      isCompleted: true,
    );
  }

  /// Get a single level’s data
  Future<Map<String, dynamic>?> getLevelFromFirebase({
    required String language,
    required String topic,
    required int levelNumber,
  }) async {
    final snapshot = await _dbRef
        .child(language)
        .child(topic)
        .child("level$levelNumber")
        .get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }
}
