import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import '../services/notification_service.dart';

class GoalProvider extends ChangeNotifier {
  static const _key = 'goals_v2';
  static const _legacyKey = 'goal_v1';

  List<GoalItem> _goals = [];
  List<GoalItem> get goals => _goals;

  List<GoalItem> get learnGoals =>
      _goals.where((g) => g.type == GoalType.learn && g.surahIndex >= 0).toList();

  List<GoalItem> get readGoals =>
      _goals.where((g) => g.type == GoalType.read && g.pagesPerDay >= 1).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final all = list
            .map((e) => GoalItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _goals = all.where((g) {
          if (g.type == GoalType.learn) return g.surahIndex >= 0;
          if (g.type == GoalType.read) return g.pagesPerDay >= 1;
          return false;
        }).toList();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('GoalProvider: failed to parse goals_v2: $e');
      }
    }
    // One-time migration from old goal_v1 single-goal format
    final legacy = prefs.getString(_legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      try {
        _goals = migrateGoalV1(
            jsonDecode(legacy) as Map<String, dynamic>);
        await _save(prefs);
      } catch (e) {
        debugPrint('GoalProvider: failed to migrate goal_v1: $e');
      }
    }
    notifyListeners();
  }

  Future<void> add(GoalItem item) async {
    _goals.add(item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
    await _scheduleOne(item);
  }

  Future<void> remove(String id) async {
    final item = _goals.where((g) => g.id == id).firstOrNull;
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
    if (item != null) await _cancelOne(item);
  }

  Future<void> update(GoalItem item) async {
    final idx = _goals.indexWhere((g) => g.id == item.id);
    if (idx < 0) return;
    await _cancelOne(_goals[idx]);
    _goals[idx] = item;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs);
    await _scheduleOne(item);
  }

  Future<void> _save(SharedPreferences prefs) async {
    await prefs.setString(
        _key, jsonEncode(_goals.map((g) => g.toJson()).toList()));
  }

  Future<void> _scheduleOne(GoalItem g) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRu = (prefs.getString('appLang') ?? 'kz') == 'ru';
      final isLearn = g.type == GoalType.learn;
      final title = isRu
          ? 'Dudi — ${isLearn ? 'Цель заучивания' : 'Цель чтения'}'
          : 'Dudi — ${isLearn ? 'Жаттау' : 'Оқу'} мақсаты';
      await NotificationService.scheduleGoalNotifications(
        baseId: g.notifId,
        title: title,
        hour: g.notifHour,
        minute: g.notifMinute,
        deadline: g.deadline,
        isLearn: isLearn,
        isRu: isRu,
      );
    } catch (_) {}
  }

  Future<void> _cancelOne(GoalItem g) async {
    try {
      await NotificationService.cancelGoalNotifications(g.notifId);
    } catch (_) {}
  }
}
