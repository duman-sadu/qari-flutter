import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// Ramadan хатм challenge: read the whole Quran during Ramadan — 1 juz per day.
/// Self-contained (separate from the goal system): tracks how many juz the user
/// has completed and schedules a daily reminder for each Ramadan day.
class RamadanProvider extends ChangeNotifier {
  static const _key = 'ramadan_challenge_v1';

  // 1 Ramadan 1448 AH — approximate Gregorian date (depends on moon sighting).
  // Verify against the calendar closer to Ramadan and adjust if needed.
  static final DateTime startDate = DateTime(2027, 2, 8);
  static const int totalDays = 30;
  static const int notifHour = 21; // evening reminder to read the day's juz

  bool joined = false;
  int juzCompleted = 0; // 0..30
  String? _lastMarkedDate; // 'YYYY-MM-DD'

  static String get _today => DateTime.now().toString().substring(0, 10);

  /// 1 on the first day of Ramadan, ≤0 before it, >[totalDays] after it ends.
  int get dayOfRamadan {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
            .difference(DateTime(startDate.year, startDate.month, startDate.day))
            .inDays +
        1;
  }

  /// Days remaining until Ramadan begins (>0 only before the start).
  int get daysUntilStart => 1 - dayOfRamadan;

  bool get isRunning => dayOfRamadan >= 1 && dayOfRamadan <= totalDays;
  bool get finished => juzCompleted >= totalDays;
  bool get markedToday => _lastMarkedDate == _today;

  /// Show the card only around Ramadan (2 weeks before → end) or once joined.
  bool get visible =>
      joined || (dayOfRamadan >= -13 && dayOfRamadan <= totalDays);

  /// How many juz should already be read by today, to keep the хатм on pace.
  int get expectedJuz => dayOfRamadan.clamp(0, totalDays);
  bool get onTrack => juzCompleted >= expectedJuz;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        joined = j['joined'] as bool? ?? false;
        juzCompleted = j['juzCompleted'] as int? ?? 0;
        _lastMarkedDate = j['lastMarkedDate'] as String?;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'joined': joined,
        'juzCompleted': juzCompleted,
        'lastMarkedDate': _lastMarkedDate,
      }),
    );
  }

  Future<void> join({required String lang}) async {
    joined = true;
    notifyListeners();
    await _save();
    await NotificationService.scheduleRamadan(
      start: startDate,
      days: totalDays,
      notifHour: notifHour,
      lang: lang,
    );
  }

  Future<void> leave() async {
    joined = false;
    notifyListeners();
    await _save();
    await NotificationService.cancelRamadan();
  }

  /// Re-schedules the daily reminders — call on launch so timezone/language
  /// changes are reflected. No-op if not joined.
  Future<void> refreshNotifications({required String lang}) async {
    if (!joined) return;
    await NotificationService.scheduleRamadan(
      start: startDate,
      days: totalDays,
      notifHour: notifHour,
      lang: lang,
    );
  }

  /// Marks today's juz as read (once per day, only while Ramadan is running).
  Future<void> markJuzRead() async {
    if (!isRunning || markedToday || finished) return;
    juzCompleted = (juzCompleted + 1).clamp(0, totalDays);
    _lastMarkedDate = _today;
    notifyListeners();
    await _save();
  }
}
