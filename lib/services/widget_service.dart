import 'package:flutter/services.dart';
import '../providers/plan_provider.dart';
import '../providers/goal_provider.dart';
import 'quran_api.dart';

class WidgetService {
  static const _ch = MethodChannel('com.example.qari_flutter/overlay');

  static Future<void> update({
    required PlanProvider plan,
    required GoalProvider goals,
    required bool isRu,
  }) async {
    try {
      String surahKz = '', surahRu = '', arabicText = '';
      int verse = 0, total = 0;

      // 1. Memorization — specific surahs selected
      if (plan.selectedSurahs.isNotEmpty) {
        final idx = plan.selectedSurahs[
          plan.currentSurahIndex.clamp(0, plan.selectedSurahs.length - 1)
        ];
        surahKz = surahNames[idx];
        surahRu = surahNamesRu[idx];
        verse = plan.currentVerseInSurah;
        total = ayahCounts[idx];
        arabicText = getAyahArabic(idx + 1, verse) ?? '';
      }
      // 2. Reading — specific surahs selected (when not memorizing)
      else if (plan.selectedReadSurahs.isNotEmpty) {
        final idx = plan.selectedReadSurahs[
          plan.readSurahIndex.clamp(0, plan.selectedReadSurahs.length - 1)
        ];
        surahKz = surahNames[idx];
        surahRu = surahNamesRu[idx];
        verse = plan.readSurahVerse;
        total = ayahCounts[idx];
        arabicText = getAyahArabic(idx + 1, verse) ?? '';
      }
      // 3. Global memorization — full Quran mode, no specific surahs
      else if (plan.currentAyah > 0) {
        final pos = getChapterAndVerse(plan.currentAyah);
        final chapter = pos['chapter']!;
        final idx = chapter - 1;
        surahKz = surahNames[idx];
        surahRu = surahNamesRu[idx];
        verse = pos['verse']!;
        total = ayahCounts[idx];
        arabicText = getAyahArabic(chapter, verse) ?? '';
      }

      // Goals — always check regardless of surah state
      int goalDays = -1;
      String goalType = '';
      final learnGoal =
          goals.learnGoals.isNotEmpty ? goals.learnGoals.first : null;
      final readGoal =
          goals.readGoals.isNotEmpty ? goals.readGoals.first : null;
      if (learnGoal != null && learnGoal.daysRemaining > 0) {
        goalDays = learnGoal.daysRemaining;
        goalType = 'learn';
      } else if (readGoal != null && readGoal.daysRemaining > 0) {
        goalDays = readGoal.daysRemaining;
        goalType = 'read';
      }

      await _save('widget_surah',        surahKz);
      await _save('widget_surah_ru',     surahRu);
      await _save('widget_ayah_arabic',  arabicText);
      await _save('widget_verse',        verse);
      await _save('widget_total_verses', total);
      await _save('widget_goal_days',    goalDays);
      await _save('widget_goal_type',    goalType);
      await _save('widget_is_ru',        isRu);
      await _ch.invokeMethod('updateWidget');
    } catch (_) {}
  }

  static Future<void> _save(String key, dynamic value) async {
    try {
      await _ch.invokeMethod('saveWidgetData', {'key': key, 'value': value});
    } catch (_) {}
  }
}
