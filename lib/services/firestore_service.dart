import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

/// Progress and profile sync — backed by the NestJS/PostgreSQL backend.
/// Public API is identical to the old Firestore version so plan_provider
/// requires no changes.
class FirestoreService {
  static bool get isLoggedIn =>
      FirebaseAuth.instance.currentUser != null;

  // ── Progress ──────────────────────────────────────────────────────────────

  static Future<void> saveProgress({
    required int currentAyah,
    required int currentSurahIndex,
    required int currentVerseInSurah,
    required int streak,
    required String? lastStudyDate,
    required int readAyah,
    required List<int> selectedSurahs,
    required String studyMode,
    required List<Map<String, dynamic>> learnedHistory,
    required List<Map<String, dynamic>> readHistory,
    required List<String> learnedAyahKeys,
    required List<int> selectedReadSurahs,
    required int readSurahIndex,
    required int readSurahVerse,
    required int readPageNumber,
    int readJuzNumber = 1,
  }) async {
    if (!isLoggedIn) return;
    await ApiService.saveProgressState({
      'currentAyah': currentAyah,
      'currentSurahIndex': currentSurahIndex,
      'currentVerseInSurah': currentVerseInSurah,
      'streak': streak,
      'lastStudyDate': lastStudyDate ?? '',
      'readAyah': readAyah,
      'selectedSurahs': selectedSurahs,
      'studyMode': studyMode,
      'learnedHistory': learnedHistory,
      'readHistory': readHistory,
      'learnedAyahKeys': learnedAyahKeys,
      'selectedReadSurahs': selectedReadSurahs,
      'readSurahIndex': readSurahIndex,
      'readSurahVerse': readSurahVerse,
      'readPageNumber': readPageNumber,
      'readJuzNumber': readJuzNumber,
      'xp': readHistory.fold<int>(
          0, (s, e) => s + ((e['count'] as num?)?.toInt() ?? 0)),
    });
  }

  static Future<Map<String, dynamic>?> loadProgress() async {
    if (!isLoggedIn) return null;
    return ApiService.getProgressState();
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<void> saveProfile(Map<String, dynamic> data) async {
    if (!isLoggedIn) return;
    await ApiService.saveProfileData(data);
  }

  static Future<Map<String, dynamic>?> loadProfile() async {
    if (!isLoggedIn) return null;
    return ApiService.getProfileData();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts the backend progress map to SharedPreferences-compatible types.
  static Map<String, dynamic> normalizeProgress(Map<String, dynamic> raw) {
    return {
      'currentAyah': (raw['currentAyah'] as num?)?.toInt() ?? 1,
      'currentSurahIndex': (raw['currentSurahIndex'] as num?)?.toInt() ?? 0,
      'currentVerseInSurah': (raw['currentVerseInSurah'] as num?)?.toInt() ?? 1,
      'streak': (raw['streak'] as num?)?.toInt() ?? 0,
      'lastStudyDate': raw['lastStudyDate']?.toString(),
      'readAyah': (raw['readAyah'] as num?)?.toInt() ?? 1,
      'studyMode': raw['studyMode']?.toString() ?? 'Жаттау',
      'selectedSurahs': (raw['selectedSurahs'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          <int>[],
      'learnedHistory': jsonEncode(raw['learnedHistory'] ?? []),
      'readHistory': jsonEncode(raw['readHistory'] ?? []),
      'learnedAyahKeys': (raw['learnedAyahKeys'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      'selectedReadSurahs': (raw['selectedReadSurahs'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          <int>[],
      'readSurahIndex': (raw['readSurahIndex'] as num?)?.toInt() ?? 0,
      'readSurahVerse': (raw['readSurahVerse'] as num?)?.toInt() ?? 1,
      'readPageNumber': (raw['readPageNumber'] as num?)?.toInt() ?? 1,
      'readJuzNumber': (raw['readJuzNumber'] as num?)?.toInt() ?? 1,
    };
  }
}
