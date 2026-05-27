import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/onboarding_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import 'hadi_screen.dart';
import 'stats_screen.dart';
import '../providers/goal_provider.dart';
import '../models/goal.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  LanguageProvider get _s => context.read<LanguageProvider>();

  bool _editVisible = false;
  bool _surahModalVisible = false;

  late TextEditingController _firstNameC;
  late TextEditingController _lastNameC;
  late TextEditingController _ageC;
  String? _localGender;
  bool _localTajweed = false;
  List<int> _localKnownSurahs = [];

  late final Stream<Map<int, int>> _juzReadStream;

  @override
  void initState() {
    super.initState();
    _juzReadStream = GroupService.juzReadCountsStream();
    final o = context.read<OnboardingProvider>();
    _firstNameC = TextEditingController(text: o.firstName);
    _lastNameC = TextEditingController(text: o.lastName);
    _ageC = TextEditingController(text: o.age);
    _localGender = o.gender;
    _localTajweed = o.knowsTajweed;
    _localKnownSurahs = List.from(o.knownSurahs);
  }

  @override
  void dispose() {
    _firstNameC.dispose();
    _lastNameC.dispose();
    _ageC.dispose();
    super.dispose();
  }

  void _openEdit() {
    final o = context.read<OnboardingProvider>();
    setState(() {
      _firstNameC.text = o.firstName;
      _lastNameC.text = o.lastName;
      _ageC.text = o.age;
      _localGender = o.gender;
      _localTajweed = o.knowsTajweed;
      _localKnownSurahs = List.from(o.knownSurahs);
      _editVisible = true;
    });
  }

  Future<void> _saveEdit() async {
    final o = context.read<OnboardingProvider>();
    final plan = context.read<PlanProvider>();
    o.updateProfile(
      first: _firstNameC.text.trim(),
      last: _lastNameC.text.trim(),
      g: _localGender,
      a: _ageC.text.trim(),
      tajweed: _localTajweed,
      known: _localKnownSurahs,
    );
    await plan.setKnownSurahs(_localKnownSurahs);
    setState(() => _editVisible = false);
  }

  void _toggleSurah(int index) {
    setState(() {
      if (_localKnownSurahs.contains(index)) {
        _localKnownSurahs.remove(index);
      } else {
        _localKnownSurahs.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = context.watch<LanguageProvider>();
    final o = context.watch<OnboardingProvider>();
    final plan = context.watch<PlanProvider>();
    final goalProvider = context.watch<GoalProvider>();

    final totalLearnedAll =
        plan.learnedHistory.fold(0, (acc, h) => acc + h.count);
    final totalReadAll =
        plan.readHistory.fold(0, (acc, h) => acc + h.count);

    // Progress: total Quran − already known − already learned
    const totalQuranAyahs = 6236;
    final knownAyahs =
        o.knownSurahs.fold(0, (sum, i) => sum + ayahCounts[i]);
    final learnedAyahs = plan.learnedAyahKeys.length;
    final totalToLearn = (totalQuranAyahs - knownAyahs).clamp(0, totalQuranAyahs);
    final progress = totalToLearn > 0
        ? (learnedAyahs / totalToLearn).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (totalToLearn - learnedAyahs).clamp(0, totalToLearn);

    // Surahs fully learned ayah-by-ayah (one pass over learnedAyahKeys)
    final Map<int, int> learnedPerChapter = {};
    for (final key in plan.learnedAyahKeys) {
      final colon = key.indexOf(':');
      if (colon > 0) {
        final ch = int.tryParse(key.substring(0, colon));
        if (ch != null) learnedPerChapter[ch] = (learnedPerChapter[ch] ?? 0) + 1;
      }
    }
    final autoLearnedIndices = Set<int>.from(
      List.generate(114, (i) => i)
          .where((i) => (learnedPerChapter[i + 1] ?? 0) >= ayahCounts[i]),
    );
    // Combined: manually marked known + fully learned via ayahs
    final allKnownSet = {...o.knownSurahs, ...autoLearnedIndices};
    final allKnownList = allKnownSet.toList()..sort();
    final knownCount = allKnownList.length;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                decoration: BoxDecoration(color: c.primary),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_ios,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Text(s.tr('back'),
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white54)),
                            ],
                          ),
                        ),
                        _LangPicker(s: s),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          o.firstName.isNotEmpty
                              ? o.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${o.lastName} ${o.firstName}'.trim().isEmpty
                          ? s.tr('userFallback')
                          : '${o.lastName} ${o.firstName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.genderAgeLine(o.gender ?? '', o.age),
                      style: const TextStyle(fontSize: 13, color: Colors.white60),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        s.streakLabel(plan.streak),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Hadi AI card ───────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HadiScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E3B), Color(0xFF2E7D56)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            ClipOval(
                              child: Image.asset(
                                'assets/hadi/calm.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, err, stack) =>
                                    const Text('🐪',
                                        style: TextStyle(fontSize: 28)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dudi AI',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text(s.tr('dudiSub'),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white38, size: 14),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Google account ──────────────────────────────────
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snap) {
                        final user = snap.data;
                        if (user != null) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: c.blueTint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('G',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.blue)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName ?? 'Google',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: c.text),
                                      ),
                                      Text(
                                        user.email ?? '',
                                        style: TextStyle(
                                            fontSize: 12, color: c.subtext),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: c.card,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        title: Text(_s.tr('logout'),
                                            style:
                                                TextStyle(color: c.text)),
                                        content: Text(
                                            _s.tr('signOutQ'),
                                            style: TextStyle(
                                                color: c.subtext)),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: Text(_s.tr('no'),
                                                style: TextStyle(
                                                    color: c.subtext)),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: Text(_s.tr('logout'),
                                                style: const TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await AuthService.logout();
                                    }
                                  },
                                  child: Text(_s.tr('logout'),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red
                                              .withValues(alpha: 0.8))),
                                ),
                              ],
                            ),
                          );
                        }
                        // Not signed in
                        return GestureDetector(
                          onTap: () async {
                            final result = await AuthService.signInWithGoogle();
                            if (!context.mounted) return;
                            if (result.error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.error!)),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: c.blueTint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('G',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.blue)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.tr('signInGoogle'),
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: c.blue),
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: c.subtext, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // ── Edit profile ────────────────────────────────────
                    GestureDetector(
                      onTap: _openEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: c.green, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              s.tr('editData'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.green,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right, color: c.subtext, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Stats / Нәтижелер card ──────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        children: [
                          // Header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 14, 0),
                            child: Row(
                              children: [
                                Text(
                                  s.tr('resultsTitle'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: c.subtext,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const StatsScreen()),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(s.tr('all'),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: c.green,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 2),
                                      Icon(Icons.arrow_forward_ios_rounded,
                                          size: 11, color: c.green),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Ayah totals tiles
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: Row(
                              children: [
                                _StatTile(
                                  emoji: '📘',
                                  label: s.tr('memorized'),
                                  value: '$totalLearnedAll',
                                  unit: s.tr('verse'),
                                  color: c.green,
                                  tint: c.greenTint,
                                  onReset: () => _confirmReset(
                                    context, c,
                                    _s.tr('clearMemorized'),
                                    _s.tr('clearMemorizedConfirm'),
                                    () => context.read<PlanProvider>().resetLearnedStats(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _StatTile(
                                  emoji: '📖',
                                  label: s.tr('read2'),
                                  value: '$totalReadAll',
                                  unit: s.tr('verse'),
                                  color: c.blue,
                                  tint: c.blueTint,
                                  onReset: () => _confirmReset(
                                    context, c,
                                    _s.tr('clearRead'),
                                    _s.tr('clearReadConfirm'),
                                    () => context.read<PlanProvider>().resetReadStats(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Page totals tiles
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                            child: Row(
                              children: [
                                _StatTile(
                                  emoji: '📄',
                                  label: s.tr('pagesRead'),
                                  value: '${plan.readPagesTotal}',
                                  unit: s.tr('pageSuffix'),
                                  color: c.gold,
                                  tint: c.goldTint,
                                  onReset: () => _confirmReset(
                                    context, c,
                                    _s.tr('clearPages'),
                                    _s.tr('clearPagesConfirm'),
                                    () => context.read<PlanProvider>().resetPageStats(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _StatTile(
                                  emoji: '🗂️',
                                  label: s.tr('uniquePages'),
                                  value: '${plan.readPagesUnique}',
                                  unit: s.tr('pageSuffix'),
                                  color: const Color(0xFF9C27B0),
                                  tint: const Color(0xFF9C27B0).withValues(alpha: 0.08),
                                  onReset: () => _confirmReset(
                                    context, c,
                                    _s.tr('clearPages'),
                                    _s.tr('clearPagesConfirm'),
                                    () => context.read<PlanProvider>().resetPageStats(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Progress bar (always shown once user has started learning)
                          if (learnedAyahs > 0 || totalToLearn < totalQuranAyahs) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 14, 18, 0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                        style: TextStyle(
                                            fontSize: 12, color: c.subtext),
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
                              ),
                            ),
                          ],

                          // Surah counts
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                            child: Column(
                              children: [
                                _InfoRow(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: s.tr('knownSurahs'),
                                  value: '$knownCount',
                                  color: c.green,
                                  tintColor: c.greenTint,
                                ),
                                Divider(color: c.border, height: 20),
                                _InfoRow(
                                  icon: Icons.menu_book_rounded,
                                  label: s.tr('surahsToMemorize'),
                                  value: '${114 - knownCount}',
                                  color: c.green,
                                  tintColor: c.greenTint,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    _buildJuzReadCard(c),

                    const SizedBox(height: 14),
                    _buildGoalCard(context, c, goalProvider),

                    if (allKnownList.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.tr('knownSurahsSection'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.subtext,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: allKnownList.map((i) {
                                final isAuto = autoLearnedIndices.contains(i);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: c.greenTint,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: c.green.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isAuto) ...[
                                        Icon(Icons.verified_rounded,
                                            size: 12, color: c.green),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        '${i + 1}. ${(_s.isRu ? surahNamesRu : surahNames)[i]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (_editVisible) _buildEditModal(context, c, o),
        ],
      ),
    );
  }

  // ── Reset helper ─────────────────────────────────────────────────────────

  Future<void> _confirmReset(
    BuildContext context,
    AppColors c,
    String title,
    String body,
    Future<void> Function() onConfirm,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: c.text, fontSize: 16)),
        content: Text(body, style: TextStyle(color: c.subtext, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_s.tr('no'), style: TextStyle(color: c.subtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s.tr('clearBtnShort'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) await onConfirm();
  }

  // ── Juz read history card ─────────────────────────────────────────────────

  Widget _buildJuzReadCard(AppColors c) {
    return StreamBuilder<Map<int, int>>(
      stream: _juzReadStream,
      builder: (context, snap) {
        final counts = snap.data ?? {};
        final totalRead = counts.values.fold(0, (a, b) => a + b);

        return Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _s.tr('juzReadTitle'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.subtext,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  if (totalRead > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.goldTint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: c.gold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _s.totalReadFmt(totalRead),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _confirmReset(
                        context, c,
                        _s.tr('clearJuzHistory'),
                        _s.tr('clearJuzConfirm'),
                        GroupService.resetJuzReadCounts,
                      ),
                      child: Icon(Icons.refresh_rounded,
                          size: 16,
                          color: c.gold.withValues(alpha: 0.5)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              // Legend
              Row(
                children: [
                  _JuzLegendDot(color: c.border, label: _s.tr('notRead')),
                  const SizedBox(width: 12),
                  _JuzLegendDot(color: c.green, label: _s.tr('onceRead')),
                  const SizedBox(width: 12),
                  _JuzLegendDot(color: c.gold, label: _s.tr('manyRead')),
                ],
              ),
              const SizedBox(height: 12),
              // 5×6 grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemCount: 30,
                itemBuilder: (_, i) {
                  final juz = i + 1;
                  final count = counts[juz] ?? 0;
                  final Color bg;
                  final Color textColor;
                  final Color borderColor;
                  if (count == 0) {
                    bg = c.bg;
                    textColor = c.subtext;
                    borderColor = c.border;
                  } else if (count == 1) {
                    bg = c.greenTint;
                    textColor = c.green;
                    borderColor = c.green.withValues(alpha: 0.3);
                  } else {
                    bg = c.goldTint;
                    textColor = c.gold;
                    borderColor = c.gold.withValues(alpha: 0.3);
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$juz',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        if (count > 0)
                          Text(
                            '×$count',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Notification fix card ────────────────────────────────────────────────

  // ── Goal card ────────────────────────────────────────────────────────────

  Widget _buildGoalCard(BuildContext context, AppColors c, GoalProvider gp) {
    final plan = context.read<PlanProvider>();
    final goals = gp.goals;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_s.tr('goalSection'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.subtext,
                      letterSpacing: 0.3)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddGoalSheet(c, null),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.greenTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: c.green),
                      const SizedBox(width: 4),
                      Text(_s.tr('add'),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.green)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (goals.isEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flag_outlined, color: c.subtext, size: 16),
                const SizedBox(width: 8),
                Text(_s.tr('noGoal'),
                    style: TextStyle(fontSize: 13, color: c.subtext)),
              ],
            ),
          ] else ...[
            ...goals.map((item) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildGoalItemRow(c, item, plan),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalItemRow(AppColors c, GoalItem item, PlanProvider plan) {
    if (item.type == GoalType.learn) {
      return _buildLearnGoalRow(c, item, plan);
    }
    return _buildReadGoalRow(c, item);
  }

  Widget _buildLearnGoalRow(AppColors c, GoalItem item, PlanProvider plan) {
    final idx = item.surahIndex;
    if (idx < 0) return const SizedBox.shrink();
    final total = ayahCounts[idx];
    final learned = plan.surahLearnedCount(idx);
    final progress = total > 0 ? learned / total : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);
    return GestureDetector(
      onTap: () => _showAddGoalSheet(c, item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.greenTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.green.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📘', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text((_s.isRu ? surahNamesRu : surahNames)[idx],
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.green)),
                ),
                Text('$learned/$total  •  $pct%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.green)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => context.read<GoalProvider>().remove(item.id),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: c.subtext),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: c.green.withValues(alpha: 0.15),
                color: c.green,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.notifications_outlined, size: 11, color: c.subtext),
                const SizedBox(width: 3),
                Text(item.notifTimeLabel,
                    style: TextStyle(fontSize: 11, color: c.subtext)),
                if (item.deadline.isNotEmpty) ...[
                  const Spacer(),
                  Text(item.deadlineLabel,
                      style: TextStyle(fontSize: 11, color: c.subtext)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadGoalRow(AppColors c, GoalItem item) {
    return GestureDetector(
      onTap: () => _showAddGoalSheet(c, item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.blueTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.blue.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_s.tr('readingGoal'),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.text)),
                      Text(_s.pagesPerDayFmt(item.pagesPerDay),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.blue)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.read<GoalProvider>().remove(item.id),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: c.subtext),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.notifications_outlined, size: 11, color: c.subtext),
                const SizedBox(width: 3),
                Text(item.notifTimeLabel,
                    style: TextStyle(fontSize: 11, color: c.subtext)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit goal sheet ────────────────────────────────────────────────

  static const _deadlinePresets = [7, 14, 30, 90];
  List<String> get _deadlineLabels => [
    _s.tr('oneWeek'),
    _s.tr('twoWeeks'),
    _s.tr('oneMonth'),
    _s.tr('threeMonths'),
  ];

  String _deadlineFromDays(int days) {
    final dl = DateTime.now().add(Duration(days: days));
    return '${dl.year}-${dl.month.toString().padLeft(2, '0')}-${dl.day.toString().padLeft(2, '0')}';
  }

  int _nearestPreset(int remaining) {
    if (remaining <= 10) return 7;
    if (remaining <= 21) return 14;
    if (remaining <= 60) return 30;
    return 90;
  }

  void _showAddGoalSheet(AppColors c, GoalItem? existing) {
    var draft = existing ??
        GoalItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: GoalType.learn,
          deadline: _deadlineFromDays(30),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, ss) {
          // upd closes over outer 'draft', so all sub-widget updates persist
          void upd(GoalItem Function(GoalItem) fn) =>
              ss(() { draft = fn(draft); });

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          existing == null ? _s.tr('newGoalTitle') : _s.tr('editGoalTitle'),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.text),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            final gp = context.read<GoalProvider>();
                            if (existing == null) {
                              gp.add(draft);
                            } else {
                              gp.update(draft);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_s.tr('save'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Type selector (only when adding)
                    if (existing == null) ...[
                      Row(
                        children: [
                          _typeChip(c, GoalType.learn, _s.tr('memorizeMode2'), draft.type,
                              (t) => upd((d) => GoalItem(
                                  id: d.id,
                                  type: t,
                                  deadline: d.deadline,
                                  notifHour: d.notifHour,
                                  notifMinute: d.notifMinute))),
                          const SizedBox(width: 8),
                          _typeChip(c, GoalType.read, _s.tr('readMode2'), draft.type,
                              (t) => upd((d) => GoalItem(
                                  id: d.id,
                                  type: t,
                                  deadline: d.deadline,
                                  notifHour: d.notifHour,
                                  notifMinute: d.notifMinute))),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Fields based on type
                    if (draft.type == GoalType.learn)
                      _learnGoalFields(c, draft, upd)
                    else
                      _readGoalFields(c, draft, upd),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _typeChip(
    AppColors c,
    GoalType type,
    String label,
    GoalType selected,
    ValueChanged<GoalType> onSelect,
  ) {
    final sel = selected == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? c.green : c.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? c.green : c.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: sel ? Colors.white : c.subtext,
            ),
          ),
        ),
      ),
    );
  }

  // upd = void Function(GoalItem Function(GoalItem)) — closed over outer draft
  Widget _learnGoalFields(
      AppColors c, GoalItem d, void Function(GoalItem Function(GoalItem)) upd) {
    final activePreset =
        d.deadline.isEmpty ? 30 : _nearestPreset(d.daysRemaining);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showSurahPicker(c, d.surahIndex,
              (idx) => upd((cur) => cur.copyWith(surahIndex: idx))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.greenTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('📘', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    d.surahIndex >= 0
                        ? '${d.surahIndex + 1}. ${(_s.isRu ? surahNamesRu : surahNames)[d.surahIndex]}'
                        : _s.tr('surahSelectHint'),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: d.surahIndex >= 0 ? c.text : c.subtext),
                  ),
                ),
                if (d.surahIndex >= 0)
                  Text('${ayahCounts[d.surahIndex]} аят',
                      style: TextStyle(fontSize: 12, color: c.subtext)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 18, color: c.subtext),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(_s.tr('duration'), style: TextStyle(fontSize: 13, color: c.subtext)),
        const SizedBox(height: 8),
        _deadlineRow(c, activePreset,
            (days) => upd((cur) => cur.copyWith(deadline: _deadlineFromDays(days)))),
        const SizedBox(height: 12),
        _notifRow(c, c.green, d,
            (h, m) => upd((cur) => cur.copyWith(notifHour: h, notifMinute: m))),
      ],
    );
  }

  Widget _readGoalFields(
      AppColors c, GoalItem d, void Function(GoalItem Function(GoalItem)) upd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_s.tr('pagesPerDay'),
            style: TextStyle(fontSize: 13, color: c.subtext)),
        const SizedBox(height: 12),
        // Preset chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 2, 3, 5, 7, 10].map((n) {
            final sel = d.pagesPerDay == n;
            return GestureDetector(
              onTap: () => upd((cur) => cur.copyWith(pagesPerDay: n)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? c.blue : c.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? c.blue : c.border),
                ),
                child: Text(_s.pagesFmt(n),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : c.subtext)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // +/- fine-tune
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => upd((cur) =>
                  cur.copyWith(pagesPerDay: (cur.pagesPerDay - 1).clamp(1, 50))),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border)),
                child: Icon(Icons.remove, size: 18, color: c.text),
              ),
            ),
            const SizedBox(width: 16),
            Text(_s.pagesPerDayFmt(d.pagesPerDay),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.blue)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => upd((cur) =>
                  cur.copyWith(pagesPerDay: (cur.pagesPerDay + 1).clamp(1, 50))),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: c.blue,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _notifRow(c, c.blue, d,
            (h, m) => upd((cur) => cur.copyWith(notifHour: h, notifMinute: m))),
      ],
    );
  }

  Widget _deadlineRow(
      AppColors c, int activePreset, ValueChanged<int> onSelect) {
    return Row(
      children: List.generate(_deadlinePresets.length, (i) {
        final days = _deadlinePresets[i];
        final sel = activePreset == days;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(days),
            child: Container(
              margin: EdgeInsets.only(
                  right: i < _deadlinePresets.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: sel ? c.green : c.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? c.green : c.border),
              ),
              child: Text(_deadlineLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : c.subtext)),
            ),
          ),
        );
      }),
    );
  }

  Widget _notifRow(AppColors c, Color color, GoalItem d,
      void Function(int h, int m) onPicked) {
    return GestureDetector(
      onTap: () async {
        final init = TimeOfDay(hour: d.notifHour, minute: d.notifMinute);
        final picked =
            await showTimePicker(context: context, initialTime: init);
        if (picked != null) onPicked(picked.hour, picked.minute);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, size: 18, color: color),
            const SizedBox(width: 10),
            Text(_s.tr('reminder'),
                style: TextStyle(fontSize: 14, color: c.text)),
            const Spacer(),
            Text(d.notifTimeLabel,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  void _showSurahPicker(
      AppColors c, int currentIndex, ValueChanged<int> onSelect) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (_, ls) {
          final query = searchCtrl.text.toLowerCase();
          final indices = List.generate(114, (i) => i).where((i) {
            if (query.isEmpty) return true;
            return surahNames[i].toLowerCase().contains(query) ||
                surahNamesRu[i].toLowerCase().contains(query) ||
                '${i + 1}'.contains(query);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Text(_s.tr('selectSurah'),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.text)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(Icons.close, color: c.subtext, size: 22),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (_) => ls(() {}),
                    style: TextStyle(fontSize: 14, color: c.text),
                    decoration: InputDecoration(
                      hintText: _s.tr('search'),
                      hintStyle: TextStyle(color: c.subtext, fontSize: 13),
                      prefixIcon:
                          Icon(Icons.search, color: c.subtext, size: 18),
                      filled: true,
                      fillColor: c.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: c.green, width: 1.5)),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: indices.length,
                    itemBuilder: (_, j) {
                      final i = indices[j];
                      final sel = currentIndex == i;
                      return GestureDetector(
                        onTap: () {
                          onSelect(i);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: sel ? c.greenTint : c.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: sel ? c.green : c.border,
                                width: sel ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: sel ? c.green : c.surfaceAlt,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: sel
                                              ? Colors.white
                                              : c.subtext)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text((_s.isRu ? surahNamesRu : surahNames)[i],
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: sel ? c.green : c.text)),
                              ),
                              Text('${ayahCounts[i]} ${_s.tr('ayah')}',
                                  style: TextStyle(
                                      fontSize: 12, color: c.subtext)),
                              if (sel) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.check_circle,
                                    size: 18, color: c.green),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditModal(BuildContext context, AppColors c, OnboardingProvider o) {
    return Container(
      color: c.bg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            color: c.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _editVisible = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_s.tr('cancelBtn'),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
                Text(
                  _s.tr('editData'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _saveEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3AA96B).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Text(_s.tr('save'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _editLabel(c, _s.tr('lastName')),
                    _editInput(c, _lastNameC, _s.tr('lastNameHint')),
                    _editLabel(c, _s.tr('firstName')),
                    _editInput(c, _firstNameC, _s.tr('firstNameHint')),
                    _editLabel(c, _s.tr('age')),
                    _editInput(c, _ageC, _s.tr('ageHint'),
                        keyboardType: TextInputType.number),
                    _editLabel(c, _s.tr('genderLabel')),
                    Row(
                      children: [
                        Expanded(child: _genderBtn(c, 'male', '👨', _s.tr('male'))),
                        const SizedBox(width: 10),
                        Expanded(child: _genderBtn(c, 'female', '👩', _s.tr('female'))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _tajweedSwitch(c),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _surahModalVisible = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            const Text('📖', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _localKnownSurahs.isNotEmpty
                                    ? _s.knownSurahsLabel(_localKnownSurahs.length)
                                    : _s.tr('selectKnownSurahs'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _localKnownSurahs.isNotEmpty
                                      ? c.green
                                      : c.subtext,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: c.subtext, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_surahModalVisible) _buildSurahPicker(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editLabel(AppColors c, String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.subtext,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _editInput(AppColors c, TextEditingController ctrl, String hint,
          {TextInputType keyboardType = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: c.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.subtext, fontSize: 14),
          filled: true,
          fillColor: c.card,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.green, width: 1.5),
          ),
        ),
      );

  Widget _genderBtn(AppColors c, String value, String emoji, String label) {
    final selected = _localGender == value;
    return GestureDetector(
      onTap: () => setState(() => _localGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? c.greenTint : c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c.green : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? c.green : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tajweedSwitch(AppColors c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: SwitchListTile(
          value: _localTajweed,
          activeThumbColor: Colors.white,
          activeTrackColor: c.green,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _s.tr('tajweedMarks'),
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: c.text),
          ),
          subtitle: Text(
            _s.tr('tajweedSubtitle'),
            style: TextStyle(fontSize: 12, color: c.subtext),
          ),
          onChanged: (v) => setState(() => _localTajweed = v),
        ),
      );

  Widget _buildSurahPicker(AppColors c) {
    return Container(
      color: c.bg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            color: c.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _s.tr('surahsLabel'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _surahModalVisible = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3AA96B).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Text(_s.tr('done'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: surahNames.length,
              itemBuilder: (_, index) {
                final isSel = _localKnownSurahs.contains(index);
                return GestureDetector(
                  onTap: () => _toggleSurah(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? c.greenTint : c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? c.green : c.border,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSel ? c.green : c.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : c.subtext,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (_s.isRu ? surahNamesRu : surahNames)[index],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSel ? c.green : c.text,
                            ),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSel ? c.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSel ? c.green : c.border,
                              width: 2,
                            ),
                          ),
                          child: isSel
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color tint;
  final VoidCallback? onReset;

  const _StatTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.tint,
    this.onReset,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                if (onReset != null)
                  GestureDetector(
                    onTap: onReset,
                    child: Icon(Icons.refresh_rounded,
                        size: 15, color: color.withValues(alpha: 0.45)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, color: c.subtext)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color)),
                const SizedBox(width: 4),
                Text(unit,
                    style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color tintColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 14, color: c.subtext)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _JuzLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _JuzLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LangPicker extends StatelessWidget {
  final LanguageProvider s;
  const _LangPicker({required this.s});

  static const _langs = [
    ('kz', 'ҚАЗ', 'Қазақша'),
    ('ru', 'РУС', 'Русский'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final current = _langs.firstWhere(
      (l) => l.$1 == s.lang,
      orElse: () => _langs.first,
    );
    return PopupMenuButton<String>(
      onSelected: s.setLanguage,
      color: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _langs
          .map((l) => PopupMenuItem<String>(
                value: l.$1,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: s.lang == l.$1 ? c.primary : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    Text(l.$3,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: c.text)),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.$2,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
