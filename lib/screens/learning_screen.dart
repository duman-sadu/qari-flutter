import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/plan_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/language_provider.dart';
import '../models/goal.dart';
import '../services/quran_api.dart';
import '../widgets/tajweed_text.dart';
import '../widgets/slide_to_learn.dart';
import '../widgets/menu_drawer.dart';
import '../data/surah_info.dart';
import '../data/sajda_verses.dart';
import '../theme/app_colors.dart';
import '../widgets/hadi_assistant.dart';
import 'surah_select_screen.dart';
import 'book_mode_screen.dart';
import 'hadi_screen.dart';
import 'listen_screen.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with WidgetsBindingObserver {
  // Convenience accessor — resolves theme-aware colors from anywhere in the state.
  AppColors get _c => AppColors.of(context);
  LanguageProvider get _s => context.read<LanguageProvider>();

  Map<String, dynamic>? ayah;
  bool loading = false;
  bool menuVisible = false;
  bool showTranslation = true;
  bool showTransliteration = true;
  bool activeMemorization = false;
  bool _leftHanded = false;
  bool _pendingOverlayEnable = false;
  double arabicFontSize = 30;
  double bodyFontSize = 14;

  // Оқу: режим чтения
  String _readUnit = 'ayah'; // 'ayah' | 'page' | 'juz' | 'surah'
  List<Map<String, dynamic>> _surahAyahs = [];
  bool _loadingMulti = false;
  String _playingAyahKey = ''; // "chapter:verse" of currently playing ayah in multi-ayah mode

  final AudioPlayer _audioPlayer = AudioPlayer();
  static const _platform = MethodChannel('com.example.qari_flutter/overlay');

  Timer? _clockTimer;
  String _timeStr = '';

  Timer? _hintTimer;
  bool _showHint = false;

  int? _bookmarkPage;
  String? _bookmarkAyah; // "chapter:verse"
  bool _hadiDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clearAyahCache();
    _loadSettings();
    _checkFromUnlock();
    Future.microtask(() => _loadAyah());
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _hintTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showHintFor(Duration duration) {
    _hintTimer?.cancel();
    setState(() => _showHint = true);
    _hintTimer = Timer(duration, () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    if (mounted) setState(() => _timeStr = '$h:$m');
  }

  // Auto-enable after user returns from the overlay permission settings screen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingOverlayEnable) {
      _pendingOverlayEnable = false;
      _enableAfterPermissionGranted();
    }
  }

  Future<void> _enableAfterPermissionGranted() async {
    try {
      final bool has = await _platform.invokeMethod('checkOverlayPermission');
      if (has && mounted) {
        await _doSetMemorization(true);
      }
    } catch (_) {}
  }

  Future<void> _checkFromUnlock() async {
    try {
      final bool fromUnlock = await _platform.invokeMethod('isFromUnlock');
      if (fromUnlock && mounted) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } catch (e) {
      debugPrint('checkFromUnlock error: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      activeMemorization = prefs.getBool('activeMemorization') ?? false;
      arabicFontSize = prefs.getDouble('arabicFontSize') ?? 30;
      bodyFontSize = prefs.getDouble('bodyFontSize') ?? 14;
      _readUnit = prefs.getString('readUnit') ?? 'ayah';
      showTranslation = prefs.getBool('showTranslation') ?? true;
      showTransliteration = prefs.getBool('showTransliteration') ?? true;
      _leftHanded = prefs.getBool('leftHanded') ?? false;
      _bookmarkPage = prefs.getInt('bookmarkPage');
      _bookmarkAyah = prefs.getString('bookmarkAyah');
    });
    if (!(prefs.getBool('hadithWelcomeShown') ?? false)) {
      await prefs.setBool('hadithWelcomeShown', true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showHadithWelcome();
      });
    }
  }

  void _showHadithWelcome() {
    final c = _c;
    final isRu = _s.isRu;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isRu
                    ? '«Самое любимое дело перед Аллахом — то, что совершается непрерывно, пусть даже и малое.»'
                    : '«Аллаға ең сүйікті амал — аз болса да, тұрақты жасалған амал.»',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: c.text, height: 1.6),
              ),
              const SizedBox(height: 10),
              Text(
                isRu
                    ? 'Хадис: Сахих аль-Бухари и Сахих Муслим.'
                    : 'Хадис: Сахих әл-Бухари және Сахих Муслим.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.subtext, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    isRu ? 'Начать' : 'Бастау',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFontSizes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('arabicFontSize', arabicFontSize);
    await prefs.setDouble('bodyFontSize', bodyFontSize);
  }

  Future<void> _saveDisplaySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTranslation', showTranslation);
    await prefs.setBool('showTransliteration', showTransliteration);
    await prefs.setBool('leftHanded', _leftHanded);
  }

  Future<void> _saveReadUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('readUnit', unit);
  }

  void _showTajweedExplanation(BuildContext context) {
    const colors = {
      'ham_wasl':          Color(0xFFAAAAAA),
      'laam_shamsiyah':    Color(0xFFAAAAAA),
      'slnt':              Color(0xFFAAAAAA),
      'madda_necessary':   Color(0xFFCC4817),
      'madda_permissible': Color(0xFFCA8831),
      'madda_normal':      Color(0xFF537FCA),
      'ghunnah':           Color(0xFF42A44B),
      'ikhafa':            Color(0xFF9B59B6),
      'ikhafa_shafawi':    Color(0xFF9B59B6),
      'idgham':            Color(0xFF27AE60),
      'idgham_shafawi':    Color(0xFF27AE60),
      'idgham_ghunnah':    Color(0xFF27AE60),
      'idgham_wo_ghunnah': Color(0xFF209d6e),
      'qalaqah':           Color(0xFFD4AC0D),
      'iqlab':             Color(0xFFE74C3C),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final c = _c;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.93,
          minChildSize: 0.4,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _s.tr('tajweedRules'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    children: tajweedNamesKz.entries.map((e) {
                      final key = e.key;
                      final name = _s.tajweedName(key);
                      final color = colors[key] ?? const Color(0xFF888888);
                      final desc = _s.tajweedDescription(key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 10, height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: c.subtext,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
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
        );
      },
    );
  }

  Future<void> _openBookMode() async {
    final plan = context.read<PlanProvider>();
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => BookModeScreen(
          initialPage: plan.readPageNumber,
          bookmarkPage: _bookmarkPage,
        ),
      ),
    );
    if (result != null && mounted) {
      await plan.setReadPageNumber(result);
      // Sync bookmark if changed inside book mode
      final prefs = await SharedPreferences.getInstance();
      setState(() => _bookmarkPage = prefs.getInt('bookmarkPage'));
      await _loadAyah();
    }
  }

  Future<void> _togglePageBookmark() async {
    final plan = context.read<PlanProvider>();
    final prefs = await SharedPreferences.getInstance();
    final n = plan.readPageNumber;
    if (_bookmarkPage == n) {
      await prefs.remove('bookmarkPage');
      if (mounted) setState(() => _bookmarkPage = null);
    } else {
      await prefs.setInt('bookmarkPage', n);
      if (mounted) setState(() => _bookmarkPage = n);
      await plan.markPageRead(n); // count bookmark tap toward daily read goal
    }
  }

  Future<void> _toggleAyahBookmark(int chapter, int verse) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$chapter:$verse';
    if (_bookmarkAyah == key) {
      await prefs.remove('bookmarkAyah');
      if (mounted) setState(() => _bookmarkAyah = null);
    } else {
      await prefs.setString('bookmarkAyah', key);
      if (mounted) setState(() => _bookmarkAyah = key);
    }
  }

  Future<void> _loadSurahAyahs() async {
    final plan = context.read<PlanProvider>();
    setState(() { _loadingMulti = true; _surahAyahs = []; });

    if (_readUnit == 'page') {
      if (plan.readPageNumber == 1) {
        final pos = plan.currentReadPosition;
        final page = await fetchVersePageNumber(pos['chapter']!, pos['verse']!);
        if (page != null && mounted) await plan.setReadPageNumber(page);
      }
      final tid = _s.translationId;
      final ayahs = await fetchVersesByPage(plan.readPageNumber, tid);
      if (!mounted) return;
      setState(() { _surahAyahs = ayahs ?? []; _loadingMulti = false; });
    } else if (_readUnit == 'juz') {
      if (plan.readJuzNumber == 1) {
        final pos = plan.currentReadPosition;
        final page = await fetchVersePageNumber(pos['chapter']!, pos['verse']!);
        if (page != null && mounted) {
          await plan.setReadJuzNumber(((page - 1) ~/ 20) + 1);
        }
      }
      final tid = _s.translationId;
      final ayahs = await fetchVersesByJuz(plan.readJuzNumber, tid);
      if (!mounted) return;
      setState(() { _surahAyahs = ayahs ?? []; _loadingMulti = false; });
    } else {
      final pos = plan.currentReadPosition;
      final tid = _s.translationId;
      final ayahs = await fetchSurahAyahsFull(pos['chapter']!, tid);
      if (!mounted) return;
      setState(() { _surahAyahs = ayahs ?? []; _loadingMulti = false; });
    }
  }

  Future<void> _toggleActiveMemorization(bool value) async {
    if (value) {
      bool hasOverlay = true;
      try {
        hasOverlay = await _platform.invokeMethod('checkOverlayPermission');
      } catch (_) {}

      if (!hasOverlay) {
        _showOverlayPermissionDialog();
        return;
      }

      try {
        await _platform.invokeMethod('requestNotificationPermission');
      } catch (_) {}
    }

    await _doSetMemorization(value);
  }

  Future<void> _doSetMemorization(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('activeMemorization', value);
    if (mounted) {
      setState(() => activeMemorization = value);
      if (value) _showHintFor(const Duration(seconds: 4));
    }
    try {
      await _platform.invokeMethod(value ? 'enableOverlay' : 'disableOverlay');
    } catch (e) {
      debugPrint('Overlay error: $e');
    }
  }

  void _showOverlayPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _c.bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _c.greenTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.layers_outlined,
                    color: _c.green, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                _s.tr('permissionRequired'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _c.text),
              ),
              const SizedBox(height: 10),
              Text(
                _s.tr('overlayPermText'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, color: _c.subtext, height: 1.6),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _pendingOverlayEnable = true;
                    try {
                      await _platform
                          .invokeMethod('requestOverlayPermission');
                    } catch (_) {}
                  },
                  child: Text(_s.tr('allow'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    Text(_s.tr('later'), style: TextStyle(color: _c.subtext)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAyah() async {
    final plan = context.read<PlanProvider>();
    if (plan.studyMode == 'Оқу' && _readUnit != 'ayah') {
      await _loadSurahAyahs();
      return;
    }
    setState(() { loading = true; ayah = null; });
    final pos = plan.studyMode == 'Оқу'
        ? plan.currentReadPosition
        : plan.currentPosition;
    final wantTajweed = context.read<OnboardingProvider>().knowsTajweed;
    final tid = _s.translationId;
    final data = await fetchAyah(pos['chapter']!, pos['verse']!, tid,
        fetchTajweed: wantTajweed);
    if (!mounted) return;
    setState(() { ayah = data; loading = false; });
  }

  Future<void> _onSwipeForward() async {
    final plan = context.read<PlanProvider>();
    if (plan.studyMode != 'Оқу') return;
    switch (_readUnit) {
      case 'ayah':
        await plan.nextReadAyah();
      case 'surah':
        await plan.jumpToNextReadSurah();
      case 'page':
        await plan.nextReadPage();
      case 'juz':
        await plan.nextReadJuz();
    }
    await _loadAyah();
    if (mounted) setState(() {});
  }

  Future<void> _onSwipeBack() async {
    final plan = context.read<PlanProvider>();
    if (plan.studyMode != 'Оқу') return;
    switch (_readUnit) {
      case 'ayah':
        await plan.previousReadAyah();
      case 'surah':
        await plan.jumpToPrevReadSurah();
      case 'page':
        await plan.previousReadPage();
      case 'juz':
        await plan.previousReadJuz();
    }
    await _loadAyah();
    if (mounted) setState(() {});
  }

  int _sequentialAyah(int chapter, int verse) {
    int seq = 0;
    for (int i = 0; i < chapter - 1; i++) {
      seq += ayahCounts[i];
    }
    return seq + verse;
  }

  Future<void> _playAudio() async {
    final chapter = ayah?['chapter'] as int? ?? 1;
    final verse = ayah?['verse'] as int? ?? 1;
    final edition = context.read<PlanProvider>().audioEditionId;
    final num = _sequentialAyah(chapter, verse);
    final url = 'https://cdn.islamic.network/quran/audio/128/$edition/$num.mp3';
    setState(() => _playingAyahKey = '');
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> _playAyahAudio(int chapter, int verse) async {
    final key = '$chapter:$verse';
    if (_playingAyahKey == key && _audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.stop();
      setState(() => _playingAyahKey = '');
      return;
    }
    setState(() => _playingAyahKey = key);
    final edition = context.read<PlanProvider>().audioEditionId;
    final num = _sequentialAyah(chapter, verse);
    final url = 'https://cdn.islamic.network/quran/audio/128/$edition/$num.mp3';
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> _nextAyah() async {
    final plan = context.read<PlanProvider>();
    if (plan.studyMode == 'Оқу') {
      final ayahCount = (_readUnit != 'ayah' && _surahAyahs.isNotEmpty)
          ? _surahAyahs.length
          : 1;
      await plan.recordRead(count: ayahCount);
      switch (_readUnit) {
        case 'page':
          await plan.nextReadPage();
        case 'juz':
          await plan.nextReadJuz();
        case 'surah':
          await plan.jumpToNextReadSurah();
        default:
          await plan.nextReadAyah();
      }
    } else {
      // Capture context-dependent values before any async gaps
      final completingIdx = plan.selectedSurahs.isNotEmpty
          ? plan.selectedSurahs[plan.currentSurahIndex]
          : -1;
      final wasComplete = completingIdx >= 0 &&
          plan.surahLearnedCount(completingIdx) >= ayahCounts[completingIdx];
      final gp = context.read<GoalProvider>();

      await plan.recordLearned();
      await plan.nextAyah();
      await plan.updateStreak();

      // Check completion BEFORE loading next ayah so we can fix position first
      if (!wasComplete &&
          completingIdx >= 0 &&
          plan.surahLearnedCount(completingIdx) >= ayahCounts[completingIdx]) {
        // Remove the finished surah so the next _loadAyah picks the right position
        await plan.removeSurahFromSelected(completingIdx);
        final matchingGoals = gp.goals
            .where((g) =>
                g.type == GoalType.learn && g.surahIndex == completingIdx)
            .toList();
        for (final g in matchingGoals) {
          await gp.remove(g.id);
        }

        await _loadAyah();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        if (mounted) {
          setState(() {});
          _showSurahCompletedSheet(completingIdx,
              goalCompleted: matchingGoals.isNotEmpty);
        }
        return;
      }

      await _loadAyah();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (mounted) setState(() {});
      return;
    }
    await plan.updateStreak();
    await _loadAyah();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) setState(() {});
  }

  Widget _buildGoalCircle(GoalProvider gp, PlanProvider plan) {
    final goals = gp.learnGoals;
    final currentSurahIdx = plan.selectedSurahs.isNotEmpty
        ? plan.selectedSurahs[plan.currentSurahIndex]
        : -1;
    final g = goals.firstWhere(
      (g) => g.surahIndex == currentSurahIdx,
      orElse: () => goals.first,
    );
    final total = ayahCounts[g.surahIndex];
    final learned = plan.surahLearnedCount(g.surahIndex);
    final progress = total > 0 ? learned / total : 0.0;
    final pct = (progress * 100).round();
    final c = _c;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 4.5,
              backgroundColor: c.green.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(c.green),
            ),
            Center(
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: c.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadGoalCircle(GoalProvider gp, PlanProvider plan) {
    final goal = gp.readGoals.firstOrNull;
    if (goal == null) return const SizedBox();

    final pagesRead = plan.readPagesToday;
    final progress = goal.pagesPerDay > 0
        ? (pagesRead / goal.pagesPerDay).clamp(0.0, 1.0)
        : 0.0;
    final pct = (progress * 100).round();
    final c = _c;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 4.5,
              backgroundColor: c.blue.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(c.blue),
            ),
            Center(
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: c.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSurahCompletedSheet(int surahIdx, {bool goalCompleted = false}) {
    if (!mounted) return;
    final c = _c;
    final name = (_s.isRu ? surahNamesRu : surahNames)[surahIdx];
    final total = ayahCounts[surahIdx];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            28, 32, 28, 32 + MediaQuery.of(ctx).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Celebration ──────────────────────────────────────────
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.green.withValues(alpha: 0.12),
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _s.tr('mubarakTitle'),
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 15, color: c.subtext, height: 1.5),
                children: [
                  TextSpan(text: _s.tr('youHave')),
                  TextSpan(
                    text: '${surahIdx + 1}. $name',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: c.green),
                  ),
                  TextSpan(
                    text: _s.tr('surahNameSuffix') + _s.surahMemorizedSuffix(total),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Progress badge ───────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: c.greenTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: c.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$name — 100%',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Goal completed badge ─────────────────────────────────
            if (goalCompleted) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: c.greenTint,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: c.green.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_rounded, color: c.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _s.tr('goalAchieved'),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Select new surah button ──────────────────────────────
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _openSurahSelect();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _s.tr('selectNewSurah'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // ── Set new goal button (only when goal was completed) ───
            if (goalCompleted) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/profile');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.green),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _s.tr('setNewGoal'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: c.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // ── Dismiss ──────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_s.tr('chooseLater'),
                    style: TextStyle(fontSize: 14, color: c.subtext)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _readCompletedLabel {
    switch (_readUnit) {
      case 'page':  return _s.tr('pageRead');
      case 'juz':   return _s.tr('juzRead');
      case 'surah': return _s.tr('surahRead');
      default:      return _s.tr('ayahRead');
    }
  }

  void _handleOk() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    const channel = MethodChannel('com.example.qari_flutter/overlay');
    channel.invokeMethod('minimizeApp');
  }

  Future<void> _openSurahSelect() async {
    final plan = context.read<PlanProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahSelectScreen(isReadMode: plan.studyMode == 'Оқу'),
      ),
    );
    await _loadAyah();
    if (mounted) setState(() {});
  }

  void _showModeSwitcher() {
    final plan = context.read<PlanProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
        decoration: BoxDecoration(
          color: _c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _c.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _s.tr('selectReadMode'),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _c.text),
            ),
            const SizedBox(height: 16),
            _modeOption(
              plan: plan,
              mode: 'Жаттау',
              icon: '📘',
              title: _s.tr('memorizeMode'),
              subtitle: _s.tr('memorizeDesc'),
              color: _c.green,
              bgColor: _c.greenTint,
              borderColor: _c.green,
            ),
            const SizedBox(height: 10),
            _modeOption(
              plan: plan,
              mode: 'Оқу',
              icon: '📖',
              title: _s.tr('readMode'),
              subtitle: _s.tr('readDesc'),
              color: _c.blue,
              bgColor: _c.blueTint,
              borderColor: _c.blue,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _openBookMode();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _c.border),
                ),
                child: Row(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _s.tr('modeBook'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _c.text,
                            ),
                          ),
                          Text(
                            _s.tr('modeBookSub'),
                            style: TextStyle(fontSize: 12, color: _c.subtext),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: _c.subtext),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ListenScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _c.border),
                ),
                child: Row(
                  children: [
                    const Text('🎧', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _s.tr('listenTitle'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _c.text,
                            ),
                          ),
                          Text(
                            _s.tr('modeListenSub'),
                            style: TextStyle(fontSize: 12, color: _c.subtext),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: _c.subtext),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeOption({
    required PlanProvider plan,
    required String mode,
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    final selected = plan.studyMode == mode;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await plan.setStudyMode(mode);
        await _loadAyah();
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? bgColor : _c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? borderColor : _c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: selected ? color : _c.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: _c.subtext),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  void _showJuzPicker() {
    final plan = context.read<PlanProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: _c.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              _s.tr('selectJuz'),
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _c.text),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.1,
              ),
              itemCount: 30,
              itemBuilder: (_, i) {
                final n = i + 1;
                final active = plan.readJuzNumber == n;
                return GestureDetector(
                  onTap: () async {
                    await plan.setReadJuzNumber(n);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadAyah();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: active ? _c.primary : _c.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: active ? _c.primary : _c.border),
                    ),
                    child: Center(
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : _c.text,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPagePicker() {
    final plan = context.read<PlanProvider>();
    // Estimate row height: cell≈44px + spacing 8 = 52px per row (6 cols)
    const double rowH = 52.0;
    const int cols = 6;
    final initOffset =
        ((plan.readPageNumber - 1) ~/ cols * rowH).clamp(0.0, 603 * rowH);
    final scrollCtrl = ScrollController(initialScrollOffset: initOffset);

    showModalBottomSheet(
      context: context,
      backgroundColor: _c.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                _s.tr('selectPage'),
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _c.text),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  controller: scrollCtrl,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: 604,
                  itemBuilder: (_, i) {
                    final n = i + 1;
                    final active = plan.readPageNumber == n;
                    final isBookmark = _bookmarkPage == n;
                    return GestureDetector(
                      onTap: () async {
                        await plan.setReadPageNumber(n);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadAyah();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: active
                              ? _c.primary
                              : isBookmark ? _c.goldTint : _c.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active
                                ? _c.primary
                                : isBookmark ? _c.gold : _c.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : isBookmark ? _c.gold : _c.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(scrollCtrl.dispose);
  }

  void _showAyahSettings() {
    final plan = context.read<PlanProvider>();
    final pos = plan.studyMode == 'Оқу'
        ? plan.currentReadPosition
        : plan.currentPosition;
    final chapter = (pos['chapter'] ?? 1).clamp(1, 114);
    final meta = surahMeta[chapter - 1];
    final metaRu = surahMetaRu[chapter - 1];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          decoration: BoxDecoration(
            color: _c.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _c.border,
                    borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 10),

              // ── Title + surah info inline ───────────────────────────────
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: _c.primary,
                        borderRadius: BorderRadius.circular(7)),
                    child: Center(
                      child: Text('${meta.number}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_s.tr('settings'),
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _c.text)),
                        Text(_s.isRu ? metaRu.name : meta.name,
                            style: TextStyle(
                                fontSize: 11, color: _c.subtext)),
                      ],
                    ),
                  ),
                  // Badges compact
                  _infoBadge(
                    icon: Icons.location_on_outlined,
                    label: _s.isRu ? _s.placeRu(meta.place) : meta.place,
                    color: meta.place == 'Мекке'
                        ? _c.meccaFg
                        : _c.green,
                    bg: meta.place == 'Мекке'
                        ? _c.meccaBg
                        : _c.greenTint,
                  ),
                  const SizedBox(width: 4),
                  _infoBadge(
                    icon: Icons.format_list_numbered,
                    label: '${meta.ayah}',
                    color: _c.blue,
                    bg: _c.blueTint,
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(color: _c.border, height: 1),
              const SizedBox(height: 8),

              // ── Read unit (Оқу only) ────────────────────────────────────
              if (plan.studyMode == 'Оқу') ...[
                Row(
                  children: [
                    Text(_s.tr('readUnitLabel'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _c.subtext)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          _readUnitBtn('ayah', '📄', _s.tr('verse'), setModalState),
                          const SizedBox(width: 5),
                          _readUnitBtn('page', '📋', _s.tr('page'), setModalState),
                          const SizedBox(width: 5),
                          _readUnitBtn('juz', '📑', _s.tr('juzPara'), setModalState),
                          const SizedBox(width: 5),
                          _readUnitBtn('surah', '📖', _s.tr('surah'), setModalState),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: _c.border, height: 1),
                const SizedBox(height: 8),
              ],

              // ── Font size: preview + sliders ───────────────────────────
              // Preview (compact single line)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _c.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: arabicFontSize, height: 1.6, color: _c.text),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _s.tr('bismiTranslation'),
                        style: TextStyle(
                            fontSize: bodyFontSize,
                            height: 1.3,
                            color: _c.subtext),
                      ),
                    ),
                  ],
                ),
              ),
              // Arabic slider
              Row(
                children: [
                  Text('ع', style: TextStyle(fontSize: 12, color: _c.subtext, fontWeight: FontWeight.w700)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(ctx).copyWith(
                        activeTrackColor: _c.green,
                        inactiveTrackColor: _c.border,
                        thumbColor: _c.green,
                        overlayColor: _c.green.withValues(alpha: 0.1),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: arabicFontSize,
                        min: 20, max: 50, divisions: 15,
                        onChanged: (v) {
                          setModalState(() => arabicFontSize = v);
                          setState(() => arabicFontSize = v);
                        },
                        onChangeEnd: (_) => _saveFontSizes(),
                      ),
                    ),
                  ),
                  Text('ع', style: TextStyle(fontSize: 20, color: _c.subtext, fontWeight: FontWeight.w700)),
                ],
              ),
              // Body slider
              Row(
                children: [
                  Text('A', style: TextStyle(fontSize: 10, color: _c.subtext, fontWeight: FontWeight.w700)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(ctx).copyWith(
                        activeTrackColor: _c.blue,
                        inactiveTrackColor: _c.border,
                        thumbColor: _c.blue,
                        overlayColor: _c.blue.withValues(alpha: 0.1),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: bodyFontSize,
                        min: 11, max: 22, divisions: 11,
                        onChanged: (v) {
                          setModalState(() => bodyFontSize = v);
                          setState(() => bodyFontSize = v);
                        },
                        onChangeEnd: (_) => _saveFontSizes(),
                      ),
                    ),
                  ),
                  Text('A', style: TextStyle(fontSize: 18, color: _c.subtext, fontWeight: FontWeight.w700)),
                ],
              ),

              Divider(color: _c.border, height: 1),

              // ── Аударма + Транскрипция + Тыңдау in one row ─────────────
              const SizedBox(height: 6),
              Row(
                children: [
                  // Аударма toggle
                  Expanded(
                    child: _compactToggle(
                      label: _s.tr('translation'),
                      value: showTranslation,
                      onChanged: (v) {
                        setModalState(() => showTranslation = v);
                        setState(() => showTranslation = v);
                        _saveDisplaySettings();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Транскрипция toggle
                  Expanded(
                    child: _compactToggle(
                      label: _s.tr('transliteration'),
                      value: showTransliteration,
                      onChanged: (v) {
                        setModalState(() => showTransliteration = v);
                        setState(() => showTransliteration = v);
                        _saveDisplaySettings();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Audio button
                  StreamBuilder<PlayerState>(
                    stream: _audioPlayer.onPlayerStateChanged,
                    builder: (_, snap) {
                      final playing =
                          (snap.data ?? _audioPlayer.state) == PlayerState.playing;
                      return GestureDetector(
                        onTap: () {
                          if (playing) {
                            _audioPlayer.stop();
                          } else {
                            _playAudio();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: playing ? _c.surfaceAlt : _c.greenTint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: playing ? _c.border : _c.green),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                playing
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_fill,
                                color: playing ? _c.subtext : _c.green,
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                playing ? _s.tr('stop') : _s.tr('listen'),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: playing ? _c.subtext : _c.green,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Сүре таңдау
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _openSurahSelect();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _c.border),
                  ),
                  child: Row(
                    children: [
                      const Text('📚', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _s.tr('selectSurah'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _c.subtext,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _c.subtext, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _sajdaQuery => _s.isRu
      ? 'Что такое сажда тиляват, в каких аятах встречается и как совершается?'
      : 'Тіләуат сәждесі дегеніміз не, қай аяттарда кездеседі және қалай жасалады?';

  Widget _buildSajdaBanner() => GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HadiScreen(initialQuery: _sajdaQuery),
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _c.meccaBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c.meccaFg.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _c.meccaFg.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🕌', style: TextStyle(fontSize: 21))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'سَجْدَةٌ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _c.meccaFg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _s.tr('sajdaTitle'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _c.meccaFg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _s.tr('sajdaText'),
                  style: TextStyle(
                    fontSize: 12,
                    color: _c.meccaFg.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: _c.meccaFg.withValues(alpha: 0.6)),
        ],
      ),
    ),
  );

  Widget _buildMultiAyahView(Map<String, int> pos) {
    final plan = context.read<PlanProvider>();
    final showTajweed = context.read<OnboardingProvider>().knowsTajweed;
    final displayAyahs = _surahAyahs;

    if (displayAyahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(_s.tr('verseLoadError'),
                style: TextStyle(color: _c.subtext)),
          ],
        ),
      );
    }

    final String headerText;
    if (_readUnit == 'page') {
      headerText = _s.multiAyahHeader('page', plan.readPageNumber, displayAyahs.length, '');
    } else if (_readUnit == 'juz') {
      headerText = _s.multiAyahHeader('juz', plan.readJuzNumber, displayAyahs.length, '');
    } else {
      final ch = (displayAyahs.first['chapter'] as int).clamp(1, 114);
      headerText = _s.multiAyahHeader('surah', 0, displayAyahs.length, (_s.isRu ? surahNamesRu : surahNames)[ch - 1]);
    }

    return Column(
      children: [
        // Header label + settings button
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _readUnit == 'page'
                      ? _showPagePicker
                      : _readUnit == 'juz'
                          ? _showJuzPicker
                          : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _c.blueTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            headerText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _c.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_readUnit == 'page' || _readUnit == 'juz') ...[
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more_rounded,
                              size: 14, color: _c.blue),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Swipe hint
              Row(
                children: [
                  Icon(Icons.swipe, size: 13,
                      color: _c.subtext.withValues(alpha: 0.6)),
                  const SizedBox(width: 3),
                  Text(
                    _s.readUnitSwipeHint(_readUnit),
                    style: TextStyle(
                        fontSize: 11,
                        color: _c.subtext.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Bookmark button (Бет mode only)
              if (_readUnit == 'page')
                Builder(builder: (_) {
                  final marked = _bookmarkPage == plan.readPageNumber;
                  return GestureDetector(
                    onTap: _togglePageBookmark,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: marked ? _c.goldTint : _c.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: marked ? _c.gold : _c.border),
                      ),
                      child: Icon(
                        marked ? Icons.bookmark : Icons.bookmark_border,
                        size: 16,
                        color: marked ? _c.gold : _c.subtext,
                      ),
                    ),
                  );
                }),
              const SizedBox(width: 8),
              // Settings button
              GestureDetector(
                onTap: _showAyahSettings,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _c.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _c.border),
                  ),
                  child: Icon(Icons.tune,
                      size: 16, color: _c.subtext),
                ),
              ),
            ],
          ),
        ),

        // ── Surah / page info ──────────────────────────────────────────
        if (_readUnit == 'surah' && displayAyahs.isNotEmpty)
          Builder(builder: (_) {
            final ch = (displayAyahs.first['chapter'] as int).clamp(1, 114);
            final meta = surahMeta[ch - 1];
            final metaRu = surahMetaRu[ch - 1];
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _infoBadge(
                        icon: Icons.location_on_outlined,
                        label: _s.isRu ? _s.placeRu(meta.place) : meta.place,
                        color: meta.place == 'Мекке'
                            ? _c.meccaFg
                            : _c.green,
                        bg: meta.place == 'Мекке'
                            ? _c.meccaBg
                            : _c.greenTint,
                      ),
                      _infoBadge(
                        icon: Icons.format_list_numbered,
                        label: '${meta.ayah} ${_s.tr('ayah')}',
                        color: _c.blue,
                        bg: _c.blueTint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _c.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _s.isRu ? metaRu.info : meta.info,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: _c.subtext,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            );
          }),

        // Ayah list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            itemCount: displayAyahs.length,
            itemBuilder: (_, i) {
              final a = displayAyahs[i];
              final verseNum = a['verse'] as int;
              final chapter = a['chapter'] as int;
              final prevChapter =
                  i > 0 ? displayAyahs[i - 1]['chapter'] as int : -1;
              final showSurahBanner =
                  (_readUnit == 'page' || _readUnit == 'juz') &&
                      chapter != prevChapter;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSurahBanner)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8, top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _c.greenTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _c.green,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${chapter.clamp(1, 114)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            (_s.isRu ? surahNamesRu : surahNames)[(chapter - 1).clamp(0, 113)],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _c.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Verse number badge + bookmark
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _c.blueTint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${a['chapter']}:$verseNum',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _c.blue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Per-ayah audio button
                        StreamBuilder<PlayerState>(
                          stream: _audioPlayer.onPlayerStateChanged,
                          builder: (_, snap) {
                            final key = '${a['chapter']}:$verseNum';
                            final playing = _playingAyahKey == key &&
                                (snap.data ?? _audioPlayer.state) == PlayerState.playing;
                            if (!playing && _playingAyahKey == key &&
                                snap.data == PlayerState.completed) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _playingAyahKey = '');
                              });
                            }
                            return GestureDetector(
                              onTap: () => _playAyahAudio(a['chapter'] as int, verseNum),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  playing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                                  size: 20,
                                  color: playing ? _c.blue : _c.subtext.withValues(alpha: 0.4),
                                ),
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () => _toggleAyahBookmark(
                              a['chapter'] as int, verseNum),
                          child: Builder(builder: (_) {
                            final marked =
                                _bookmarkAyah == '${a['chapter']}:$verseNum';
                            return Icon(
                              marked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 18,
                              color: marked ? _c.gold : _c.subtext.withValues(alpha: 0.4),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Arabic
                    if (showTajweed && (a['tajweed'] as String? ?? '').isNotEmpty)
                      TajweedTextWidget(
                        html: a['tajweed'],
                        fontSize: arabicFontSize,
                        baseColor: _c.text,
                      )
                    else
                      Text(
                        a['arabic'] ?? '',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: arabicFontSize,
                          height: 1.8,
                          color: _c.text,
                        ),
                      ),
                    // Translation
                    if (showTranslation &&
                        (a['translation'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Divider(color: _c.border, height: 1),
                      const SizedBox(height: 8),
                      Text(
                        a['translation'],
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          height: 1.5,
                          color: _c.text,
                        ),
                      ),
                    ],
                    // Transliteration
                    if (showTransliteration &&
                        (a['transliteration'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        a['transliteration'],
                        style: TextStyle(
                          fontSize: bodyFontSize * 0.9,
                          height: 1.4,
                          color: _c.subtext,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (sajdaVerses.contains('$chapter:$verseNum'))
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HadiScreen(
                                  initialQuery: _sajdaQuery),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                            decoration: BoxDecoration(
                              color: _c.meccaBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _c.meccaFg.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: [
                                const Text('🕌',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _s.sajdaInlineText(),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: _c.meccaFg,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: _c.meccaFg.withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _readUnitBtn(
      String unit, String emoji, String label, StateSetter setModalState) {
    final active = _readUnit == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setModalState(() {});
          setState(() => _readUnit = unit);
          await _saveReadUnit(unit);
          await _loadAyah();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _c.blueTint : _c.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? _c.blue : _c.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? _c.blue : _c.subtext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );

  Widget _compactToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value ? _c.greenTint : _c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: value ? _c.green : _c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value ? Icons.check_box : Icons.check_box_outline_blank,
                size: 15,
                color: value ? _c.green : _c.subtext,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value ? _c.green : _c.subtext,
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanProvider>();
    final goalProvider = context.watch<GoalProvider>();
    final showTajweed = context.watch<OnboardingProvider>().knowsTajweed;
    final s = context.watch<LanguageProvider>();
    final isReadMode = plan.studyMode == 'Оқу';
    final pos = isReadMode ? plan.currentReadPosition : plan.currentPosition;

    return Scaffold(
      backgroundColor: _c.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: _c.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Builder(builder: (_) {
                    // ── Reusable header widgets ──────────────────────────
                    final belsendiBtn = GestureDetector(
                      onTap: () => _toggleActiveMemorization(!activeMemorization),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: activeMemorization
                              ? const Color(0xFF3AA96B).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeMemorization
                                ? const Color(0xFF81C784)
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: activeMemorization
                                    ? const Color(0xFF81C784)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: activeMemorization
                                      ? const Color(0xFF81C784)
                                      : Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: activeMemorization
                                  ? const Icon(Icons.check,
                                      size: 11, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.tr('activeLabel'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
 
                    final menuBtn = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => menuVisible = true),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                3,
                                (i) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  width: 18,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );

                    final modeIndicator = Expanded(
                      child: GestureDetector(
                        onTap: _showModeSwitcher,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isReadMode
                                    ? const Color(0xFF90CAF9).withValues(alpha: 0.6)
                                    : const Color(0xFF81C784).withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isReadMode ? '📖' : '📘',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isReadMode ? s.tr('readMode') : s.tr('memorizeMode'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isReadMode
                                        ? const Color(0xFF90CAF9)
                                        : const Color(0xFF81C784),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.swap_horiz,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    final clock = Container(
                      margin: EdgeInsets.only(
                        left: _leftHanded ? 0 : 8,
                        right: _leftHanded ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _timeStr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    );

                    return Row(
                      children: _leftHanded
                          ? [menuBtn, const SizedBox(width: 6), modeIndicator, clock, belsendiBtn]
                          : [belsendiBtn, modeIndicator, clock, const SizedBox(width: 6), menuBtn],
                    );
                  }),
                ),

                // Active memorization hint
                if (!isReadMode && activeMemorization && _showHint)
                  GestureDetector(
                    onTap: () => _showHintFor(const Duration(seconds: 20)),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _c.greenTint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _c.green.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active_outlined,
                              size: 16, color: _c.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.tr('overlayHint'),
                              style: TextStyle(
                                fontSize: 12,
                                color: _c.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Hadi assistant ────────────────────────────────────────
                if (!_hadiDismissed)
                  Builder(builder: (_) {
                    final today = DateTime.now().toString().substring(0, 10);
                    final studiedToday = plan.learnedHistory
                        .any((h) => h.date == today && h.count > 0) ||
                        plan.readHistory
                            .any((h) => h.date == today && h.count > 0);
                    final HadiState hadiState;
                    if (studiedToday && plan.streak >= 3) {
                      hadiState = HadiState.happy;
                    } else if (plan.streak >= 5) {
                      hadiState = HadiState.motivate;
                    } else if (!studiedToday && plan.lastStudyDate != today) {
                      hadiState = HadiState.reminder;
                    } else {
                      hadiState = HadiState.calm;
                    }
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HadiScreen()),
                      ),
                      child: AnimatedHadiAssistant(
                        state: hadiState,
                        onDismiss: () =>
                            setState(() => _hadiDismissed = true),
                      ),
                    );
                  }),



                // ── Ayah card ─────────────────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: isReadMode
                        ? (d) {
                            if ((d.primaryVelocity ?? 0) < -200) {
                              _onSwipeForward();
                            } else if ((d.primaryVelocity ?? 0) > 200) {
                              _onSwipeBack();
                            }
                          }
                        : null,
                    child: (loading || _loadingMulti)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: isReadMode ? _c.blue : _c.green,
                                    backgroundColor: (isReadMode
                                            ? _c.blue
                                            : _c.green)
                                        .withValues(alpha: 0.15),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(s.tr('loading'),
                                    style: TextStyle(
                                        color: _c.subtext, fontSize: 14)),
                              ],
                            ),
                          )
                        : (isReadMode && _readUnit != 'ayah')
                            ? _buildMultiAyahView(pos)
                            : ayah == null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('😔',
                                            style: TextStyle(fontSize: 40)),
                                        const SizedBox(height: 10),
                                        Text(s.tr('verseLoadError'),
                                            style:
                                                TextStyle(color: _c.subtext)),
                                      ],
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _showAyahSettings,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: _c.card,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 16,
                                            color: Colors.black
                                                .withValues(alpha: 0.07),
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(22),
                                        child: Column(
                                          children: [
                                            Builder(builder: (_) {
                                              final chIdx = (pos['chapter']! - 1).clamp(0, 113);
                                              final meta = surahMeta[chIdx];
                                              final metaRu = surahMetaRu[chIdx];
                                              final displayName = _s.isRu ? surahNamesRu[chIdx] : surahNames[chIdx];
                                              return Column(
                                                children: [
                                                  Wrap(
                                                    alignment: WrapAlignment.center,
                                                    spacing: 6,
                                                    runSpacing: 6,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: isReadMode ? _c.blueTint : _c.greenTint,
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Text(
                                                          '$displayName  •  ${pos['chapter']}:${pos['verse']}',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w700,
                                                            color: isReadMode ? _c.blue : _c.green,
                                                          ),
                                                        ),
                                                      ),
                                                      _infoBadge(
                                                        icon: Icons.location_on_outlined,
                                                        label: _s.isRu ? _s.placeRu(meta.place) : meta.place,
                                                        color: meta.place == 'Мекке'
                                                            ? _c.meccaFg
                                                            : _c.green,
                                                        bg: meta.place == 'Мекке'
                                                            ? _c.meccaBg
                                                            : _c.greenTint,
                                                      ),
                                                      _infoBadge(
                                                        icon: Icons.format_list_numbered,
                                                        label: '${meta.ayah} ${_s.tr('ayah')}',
                                                        color: _c.blue,
                                                        bg: _c.blueTint,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: _c.surfaceAlt,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      _s.isRu ? metaRu.info : meta.info,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _c.subtext,
                                                        height: 1.5,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 18),
                                                ],
                                              );
                                            }),
                                            showTajweed &&
                                                    ayah!['tajweed'] != null &&
                                                    ayah!['tajweed']
                                                        .toString()
                                                        .isNotEmpty
                                                ? TajweedTextWidget(
                                                    html: ayah!['tajweed'],
                                                    fontSize: arabicFontSize,
                                                    baseColor: _c.text,
                                                  )
                                                : Text(
                                                    ayah!['arabic'] ?? '',
                                                    textAlign:
                                                        TextAlign.right,
                                                    textDirection:
                                                        TextDirection.rtl,
                                                    style: TextStyle(
                                                      fontSize: arabicFontSize,
                                                      height: 1.9,
                                                      color: _c.text,
                                                    ),
                                                  ),
                                            if (showTranslation &&
                                                (ayah!['translation'] as String).isNotEmpty) ...[
                                              const SizedBox(height: 18),
                                              Divider(
                                                  color: _c.border, height: 1),
                                              const SizedBox(height: 14),
                                              Text(
                                                ayah!['translation'],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: bodyFontSize,
                                                  height: 1.6,
                                                  color: _c.text,
                                                ),
                                              ),
                                            ],
                                            if (showTransliteration &&
                                                (ayah!['transliteration'] as String).isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: _c.bg,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(s.tr('pronunciationLabel'),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          letterSpacing: 1,
                                                          color: _c.subtext,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        )),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      ayah!['transliteration'],
                                                      style: TextStyle(
                                                        fontSize: bodyFontSize,
                                                        color: _c.text,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            if (sajdaVerses.contains(
                                                '${pos['chapter']}:${pos['verse']}'))
                                              _buildSajdaBanner(),
                                            const SizedBox(height: 14),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.touch_app,
                                                    size: 13,
                                                    color: _c.subtext),
                                                const SizedBox(width: 4),
                                                Text(
                                                  s.tr('pressSettings'),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: _c.subtext),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                  ),
                ),

                // ── Tajweed legend ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  child: Row(
                    children: [
                      _LegendDot(color: const Color(0xFF537FCA), label: s.tr('tajweedMaddTabigi')),
                      const SizedBox(width: 14),
                      _LegendDot(color: const Color(0xFF42A44B), label: s.tr('tajweedGhunnah')),
                      const SizedBox(width: 14),
                      _LegendDot(color: const Color(0xFF9B59B6), label: s.tr('tajweedIkhfa')),
                      const SizedBox(width: 14),
                      _LegendDot(color: const Color(0xFFD4AC0D), label: s.tr('tajweedQalqala')),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showTajweedExplanation(context),
                        child: Text(
                          s.tr('tajweedExplain'),
                          style: TextStyle(
                            fontSize: 11,
                            color: _c.subtext,
                            decoration: TextDecoration.underline,
                            decorationColor: _c.subtext,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Slide to learn ────────────────────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      child: SlideToLearn(
                        onOk: _handleOk,
                        onLearned: _nextAyah,
                        completedLabel:
                            isReadMode ? _readCompletedLabel : s.tr('iMemorized'),
                        isReadMode: isReadMode,
                        leftHanded: _leftHanded,
                      ),
                    ),
                    if (!isReadMode && goalProvider.learnGoals.isNotEmpty)
                      Positioned(
                        right: 16,
                        bottom: 20,
                        child: _buildGoalCircle(goalProvider, plan),
                      ),
                    if (isReadMode)
                      Positioned(
                        right: 16,
                        bottom: 20,
                        child: _buildReadGoalCircle(goalProvider, plan),
                      ),
                  ],
                ),
              ],
            ),

            // Menu overlay
            if (menuVisible)
              MenuDrawerWidget(
                onClose: () => setState(() => menuVisible = false),
                parentContext: context,
                leftHanded: _leftHanded,
                onLeftHandedToggle: (v) {
                  setState(() => _leftHanded = v);
                  _saveDisplaySettings();
                },
                onOpenSettings: _showAyahSettings,
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

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
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11)),
      ],
    );
  }
}
