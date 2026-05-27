import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  LanguageProvider get _s => context.read<LanguageProvider>();

  String _period = 'week';
  String _statsTab = 'learn';

  List<LearnedEntry> _filtered(List<LearnedEntry> history) {
    final now = DateTime.now();
    return history.where((h) {
      final d = DateTime.parse(h.date);
      if (_period == 'week') {
        return d.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_period == 'month') {
        return d.isAfter(DateTime(now.year, now.month - 1, now.day));
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _last7Days(List<LearnedEntry> history) {
    final now = DateTime.now();
    final weekdays = _s.weekdays;
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final dateStr = d.toString().substring(0, 10);
      final found = history.where((h) => h.date == dateStr).firstOrNull;
      return {
        'label': weekdays[d.weekday - 1],
        'count': found?.count ?? 0,
        'date': dateStr,
        'isToday': i == 6,
      };
    });
  }

  String _monthName(int month) => _s.months[month - 1];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = context.watch<LanguageProvider>();
    final plan = context.watch<PlanProvider>();

    final isLearn = _statsTab == 'learn';
    final activeHistory = isLearn ? plan.learnedHistory : plan.readHistory;
    final activeColor = isLearn ? c.green : c.blue;
    final activeTint = isLearn ? c.greenTint : c.blueTint;

    final filtered = _filtered(activeHistory);
    final total = filtered.fold(0, (acc, h) => acc + h.count);
    final activeDays = filtered.length;
    final avg = activeDays > 0 ? (total / activeDays).toStringAsFixed(1) : '0';
    final days7 = _last7Days(activeHistory);
    final maxCount =
        days7.map((d) => d['count'] as int).fold(1, (a, b) => a > b ? a : b);

    final totalLearnedAll = plan.learnedHistory.fold(0, (acc, h) => acc + h.count);
    final totalReadAll = plan.readHistory.fold(0, (acc, h) => acc + h.count);

    final totalAyahsToLearn =
        plan.selectedSurahs.fold(0, (sum, i) => sum + ayahCounts[i]);
    final remaining =
        (totalAyahsToLearn - totalLearnedAll).clamp(0, totalAyahsToLearn);
    final progress = totalAyahsToLearn > 0
        ? (totalLearnedAll / totalAyahsToLearn).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: BoxDecoration(color: c.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        s.tr('back'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.tr('statsTitle'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.tr('statsSubtitle'),
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                // ── Streak card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8F00), Color(0xFFE65100)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE65100).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('🔥', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.streakLabel(plan.streak),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            s.tr('streakStat'),
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Summary totals ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tr('overallSummary'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.subtext,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SummaryTile(
                            emoji: '📘',
                            label: s.tr('memorized2'),
                            value: '$totalLearnedAll',
                            unit: s.tr('verse'),
                            color: c.green,
                            tint: c.greenTint,
                          ),
                          const SizedBox(width: 10),
                          _SummaryTile(
                            emoji: '📖',
                            label: s.tr('read3'),
                            value: '$totalReadAll',
                            unit: s.tr('verse'),
                            color: c.blue,
                            tint: c.blueTint,
                          ),
                        ],
                      ),
                      if (totalAyahsToLearn > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.memorizeProgressLabel(progress * 100),
                              style: TextStyle(
                                fontSize: 12,
                                color: c.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              s.remainingAyahs(remaining),
                              style: TextStyle(fontSize: 12, color: c.subtext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: c.border,
                            color: c.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Mode tabs ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      _TabBtn(
                        value: 'learn',
                        current: _statsTab,
                        label: s.tr('memorizeMode2'),
                        activeColor: c.green,
                        onTap: () => setState(() => _statsTab = 'learn'),
                      ),
                      _TabBtn(
                        value: 'read',
                        current: _statsTab,
                        label: s.tr('readMode2'),
                        activeColor: c.blue,
                        onTap: () => setState(() => _statsTab = 'read'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Period filter ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      _PeriodBtn('week',  s.tr('week'),  _period, activeColor, () => setState(() => _period = 'week')),
                      _PeriodBtn('month', s.tr('month'), _period, activeColor, () => setState(() => _period = 'month')),
                      _PeriodBtn('all',   s.tr('all'),   _period, activeColor, () => setState(() => _period = 'all')),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Stat cards ─────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(value: '$total',     label: isLearn ? s.tr('versesMemorized') : s.tr('versesRead'), color: activeColor, tint: activeTint),
                    const SizedBox(width: 10),
                    _StatCard(value: '$activeDays', label: s.tr('activeDays'), color: activeColor, tint: activeTint),
                    const SizedBox(width: 10),
                    _StatCard(value: avg,           label: s.tr('versesPerDay'), color: activeColor, tint: activeTint),
                  ],
                ),

                const SizedBox(height: 14),

                // ── 7-day chart ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: activeColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.tr('last7Days'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: days7.map((day) {
                            final count = day['count'] as int;
                            final isToday = day['isToday'] as bool;
                            final barH = maxCount > 0
                                ? (count / maxCount * 90).toDouble()
                                : 0.0;
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (count > 0)
                                    Text('$count',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: activeColor,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: barH > 0 ? barH : 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: count > 0
                                          ? (isToday
                                              ? activeColor
                                              : activeColor.withValues(alpha: 0.55))
                                          : c.border,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    day['label'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isToday
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                      color: isToday ? activeColor : c.subtext,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Calendar ───────────────────────────────────────────
                _buildCalendar(context, c, activeHistory, activeColor),

                const SizedBox(height: 14),

                // ── History list ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLearn ? s.tr('memorizeHistory') : s.tr('readHistory'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.subtext,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (filtered.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                const Text('📭', style: TextStyle(fontSize: 36)),
                                const SizedBox(height: 8),
                                Text(s.tr('noData'),
                                    style: TextStyle(color: c.subtext)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filtered.reversed.map(
                          (h) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: activeTint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isLearn ? '📘' : '📖',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    h.date,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: c.text,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: activeTint,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '+${h.count} аят',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: activeColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, AppColors c,
      List<LearnedEntry> history, Color activeColor) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDay.weekday;
    final studiedDates = history.map((h) => h.date).toSet();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthName(now.month),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.subtext,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _s.weekdays
                .map((d) => SizedBox(
                      width: 34,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.subtext,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth + startWeekday - 1,
            itemBuilder: (_, index) {
              if (index < startWeekday - 1) return const SizedBox();
              final day = index - startWeekday + 2;
              final dateStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final isStudied = studiedDates.contains(dateStr);
              final isToday = day == now.day;

              return Container(
                decoration: BoxDecoration(
                  color: isStudied
                      ? activeColor
                      : isToday
                          ? activeColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isStudied
                      ? Border.all(color: activeColor, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isStudied || isToday
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: isStudied
                          ? Colors.white
                          : isToday
                              ? activeColor
                              : c.subtext,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: activeColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                _statsTab == 'learn' ? _s.tr('dayMemorized') : _s.tr('dayRead'),
                style: TextStyle(fontSize: 12, color: c.subtext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color tint;

  const _SummaryTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, color: c.subtext)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                    )),
                const SizedBox(width: 4),
                Text(unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color tint;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                )),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: c.subtext, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String value;
  final String current;
  final String label;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabBtn({
    required this.value,
    required this.current,
    required this.label,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : c.subtext,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String value;
  final String label;
  final String current;
  final Color activeColor;
  final VoidCallback onTap;

  const _PeriodBtn(
      this.value, this.label, this.current, this.activeColor, this.onTap);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : c.subtext,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
