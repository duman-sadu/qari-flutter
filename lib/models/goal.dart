// ── GoalType ──────────────────────────────────────────────────────────────────

enum GoalType { learn, read }

extension GoalTypeX on GoalType {
  String get _key {
    switch (this) {
      case GoalType.learn: return 'learn';
      case GoalType.read:  return 'read';
    }
  }

  static GoalType fromKey(String? s) {
    switch (s) {
      case 'read':  return GoalType.read;
      default:      return GoalType.learn; // includes old 'surah' type
    }
  }
}

// ── GoalItem ──────────────────────────────────────────────────────────────────

class GoalItem {
  final String id;
  final GoalType type;
  final String deadline; // '' or 'YYYY-MM-DD' — жаттау goals only
  final int notifHour;
  final int notifMinute;

  // жаттау goal: which surah to memorize (0–113, -1 if not set)
  final int surahIndex;

  // оқу goal: pages to read per day (≥ 1)
  final int pagesPerDay;

  const GoalItem({
    required this.id,
    required this.type,
    this.deadline = '',
    this.notifHour = 20,
    this.notifMinute = 0,
    this.surahIndex = -1,
    this.pagesPerDay = 1,
  });

  GoalItem copyWith({
    GoalType? type,
    String? deadline,
    int? notifHour,
    int? notifMinute,
    int? surahIndex,
    int? pagesPerDay,
  }) =>
      GoalItem(
        id: id,
        type: type ?? this.type,
        deadline: deadline ?? this.deadline,
        notifHour: notifHour ?? this.notifHour,
        notifMinute: notifMinute ?? this.notifMinute,
        surahIndex: surahIndex ?? this.surahIndex,
        pagesPerDay: pagesPerDay ?? this.pagesPerDay,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type._key,
        'deadline': deadline,
        'notifHour': notifHour,
        'notifMinute': notifMinute,
        'surahIndex': surahIndex,
        'pagesPerDay': pagesPerDay,
      };

  factory GoalItem.fromJson(Map<String, dynamic> j) {
    final typeKey = j['type'] as String? ?? 'learn';
    final type = typeKey == 'surah' ? GoalType.learn : GoalTypeX.fromKey(typeKey);
    return GoalItem(
      id: j['id'] as String? ?? _newId(),
      type: type,
      deadline: j['deadline'] as String? ?? '',
      notifHour: j['notifHour'] as int? ?? 20,
      notifMinute: j['notifMinute'] as int? ?? 0,
      surahIndex: j['surahIndex'] as int? ?? -1,
      pagesPerDay: j['pagesPerDay'] as int? ?? 1,
    );
  }

  static String _newId() => DateTime.now().millisecondsSinceEpoch.toString();

  // Each goal gets a 400-slot block to hold per-day notification IDs.
  // Range: 10000–2,009,600 — no overlap with morning(1)/evening(0) reminders.
  int get notifId => id.hashCode.abs() % 5000 * 400 + 10000;

  String get notifTimeLabel =>
      '${notifHour.toString().padLeft(2, '0')}:${notifMinute.toString().padLeft(2, '0')}';

  int get daysRemaining {
    if (deadline.isEmpty) return 0;
    try {
      final dl = DateTime.parse(deadline);
      final now = DateTime.now();
      return DateTime(dl.year, dl.month, dl.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays
          .clamp(0, 9999);
    } catch (_) {
      return 0;
    }
  }

  String get deadlineLabel {
    final d = daysRemaining;
    if (d == 0) return 'Мерзім өтті';
    if (d == 1) return '1 күн қалды';
    if (d < 8) return '$d күн қалды';
    if (d < 30) return '${(d / 7).round()} апта қалды';
    if (d < 60) return '1 ай қалды';
    return '${(d / 30).round()} ай қалды';
  }
}

// ── Migration from old goal_v1 format ────────────────────────────────────────

List<GoalItem> migrateGoalV1(Map<String, dynamic> j) {
  final items = <GoalItem>[];
  if (j['surahGoalActive'] as bool? ?? false) {
    final idx = j['surahGoalSurahIndex'] as int? ?? -1;
    if (idx >= 0) {
      items.add(GoalItem(
        id: 'legacy_surah',
        type: GoalType.learn,
        surahIndex: idx,
        deadline: j['surahGoalDeadline'] as String? ?? '',
      ));
    }
  }
  return items;
}
