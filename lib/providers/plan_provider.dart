import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/firestore_service.dart';
import '../services/friend_service.dart';

const List<int> ayahCounts = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
  123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
  112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
  34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
  54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
  60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
  14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
  28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
  29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
  15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
  11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
  5, 4, 5, 6,
];

const List<String> surahNames = [
  'әл-Фатиха сүресі',
  'әл-Бақара сүресі',
  'Әли Имран сүресі',
  'ән-Ниса сүресі',
  'әл-Мәида сүресі',
  'әл-Әнғам сүресі',
  'әл-Ағраф сүресі',
  'әл-Әнфал сүресі',
  'әт-Тәубә сүресі',
  'Жүніс сүресі',
  'Һуд сүресі',
  'Юсуф сүресі',
  'әр-Рағд сүресі',
  'Ибраһим сүресі',
  'әл-Хижр сүресі',
  'ән-Нахл сүресі',
  'әл-Исра сүресі',
  'әл-Кәһф сүресі',
  'Мәриям сүресі',
  'Та-Һа сүресі',
  'әл-Әнбия сүресі',
  'әл-Хаж сүресі',
  'әл-Муминун сүресі',
  'ән-Нұр сүресі',
  'әл-Фурқан сүресі',
  'әш-Шуғара сүресі',
  'ән-Нәмл сүресі',
  'әл-Қасас сүресі',
  'әл-Анкабут сүресі',
  'әр-Рум сүресі',
  'Лұқман сүресі',
  'әс-Сәжде сүресі',
  'әл-Ахзаб сүресі',
  'Сәбә сүресі',
  'Фатыр сүресі',
  'Ясин сүресі',
  'әс-Саффат сүресі',
  'Сад сүресі',
  'әз-Зумар сүресі',
  'Ғафир сүресі',
  'Фуссилат сүресі',
  'әш-Шура сүресі',
  'әз-Зухруф сүресі',
  'әд-Духан сүресі',
  'әл-Жәсия сүресі',
  'әл-Ахқаф сүресі',
  'Мұхаммед сүресі',
  'әл-Фатх сүресі',
  'әл-Хужурат сүресі',
  'Қаф сүресі',
  'әз-Зәрият сүресі',
  'әт-Тур сүресі',
  'ән-Нәжм сүресі',
  'әл-Қамар сүресі',
  'әр-Рахман сүресі',
  'әл-Уақиға сүресі',
  'әл-Хадид сүресі',
  'әл-Мужадила сүресі',
  'әл-Хашр сүресі',
  'әл-Мумтахана сүресі',
  'әс-Сафф сүресі',
  'әл-Жұма сүресі',
  'әл-Мунафиқун сүресі',
  'әт-Тәғабун сүресі',
  'әт-Талақ сүресі',
  'әт-Тахрим сүресі',
  'әл-Мүлк сүресі',
  'әл-Қалам сүресі',
  'әл-Хаққа сүресі',
  'әл-Мағариж сүресі',
  'Нұх сүресі',
  'әл-Жин сүресі',
  'әл-Мүззәммил сүресі',
  'әл-Мүддәссир сүресі',
  'әл-Қияма сүресі',
  'әл-Инсан сүресі',
  'әл-Мурсалат сүресі',
  'ән-Нәбә сүресі',
  'ән-Назиғат сүресі',
  'Абаса сүресі',
  'әт-Такуир сүресі',
  'әл-Инфитар сүресі',
  'әл-Мутаффифин сүресі',
  'әл-Иншиқақ сүресі',
  'әл-Буруж сүресі',
  'әт-Тариқ сүресі',
  'әл-Ағла сүресі',
  'әл-Ғашия сүресі',
  'әл-Фәжр сүресі',
  'әл-Балад сүресі',
  'әш-Шәмс сүресі',
  'әл-Ләйл сүресі',
  'әд-Духа сүресі',
  'әш-Шарх сүресі',
  'әт-Тин сүресі',
  'әл-Алақ сүресі',
  'әл-Қадр сүресі',
  'әл-Бәййина сүресі',
  'әз-Залзала сүресі',
  'әл-Адият сүресі',
  'әл-Қариға сүресі',
  'әт-Такәсур сүресі',
  'әл-Асыр сүресі',
  'әл-Һумаза сүресі',
  'әл-Фил сүресі',
  'Құрайыш сүресі',
  'әл-Мағун сүресі',
  'әл-Кәусар сүресі',
  'әл-Кафирун сүресі',
  'ән-Наср сүресі',
  'әл-Мәсәд сүресі',
  'әл-Ықылас сүресі',
  'әл-Фәлақ сүресі',
  'ән-Нас сүресі',
];

const List<String> surahNamesRu = [
  'аль-Фатиха',
  'аль-Бакара',
  'Аль Имран',
  'ан-Ниса',
  'аль-Маида',
  'аль-Анам',
  'аль-Араф',
  'аль-Анфаль',
  'ат-Тауба',
  'Юнус',
  'Худ',
  'Юсуф',
  'ар-Рад',
  'Ибрахим',
  'аль-Хиджр',
  'ан-Нахль',
  'аль-Исра',
  'аль-Кахф',
  'Марьям',
  'Та-Ха',
  'аль-Анбия',
  'аль-Хадж',
  'аль-Муминун',
  'ан-Нур',
  'аль-Фуркан',
  'аш-Шуара',
  'ан-Намль',
  'аль-Касас',
  'аль-Анкабут',
  'ар-Рум',
  'Лукман',
  'ас-Саджда',
  'аль-Ахзаб',
  'Саба',
  'Фатир',
  'Ясин',
  'ас-Саффат',
  'Сад',
  'аз-Зумар',
  'Гафир',
  'Фуссилат',
  'аш-Шура',
  'аз-Зухруф',
  'ад-Духан',
  'аль-Джасия',
  'аль-Ахкаф',
  'Мухаммад',
  'аль-Фатх',
  'аль-Худжурат',
  'Каф',
  'аз-Зарият',
  'ат-Тур',
  'ан-Наджм',
  'аль-Камар',
  'ар-Рахман',
  'аль-Вакиа',
  'аль-Хадид',
  'аль-Муджадала',
  'аль-Хашр',
  'аль-Мумтахана',
  'ас-Сафф',
  'аль-Джумуа',
  'аль-Мунафикун',
  'ат-Тагабун',
  'ат-Талак',
  'ат-Тахрим',
  'аль-Мульк',
  'аль-Калам',
  'аль-Хакка',
  'аль-Мааридж',
  'Нух',
  'аль-Джинн',
  'аль-Муззаммиль',
  'аль-Муддассир',
  'аль-Кияма',
  'аль-Инсан',
  'аль-Мурсалат',
  'ан-Наба',
  'ан-Назиат',
  'Абаса',
  'ат-Таквир',
  'аль-Инфитар',
  'аль-Мутаффифин',
  'аль-Иншикак',
  'аль-Бурудж',
  'ат-Тарик',
  'аль-Аля',
  'аль-Гашия',
  'аль-Фаджр',
  'аль-Балад',
  'аш-Шамс',
  'аль-Ляйль',
  'ад-Духа',
  'аш-Шарх',
  'ат-Тин',
  'аль-Алак',
  'аль-Кадр',
  'аль-Баййина',
  'аз-Залзала',
  'аль-Адият',
  'аль-Кариа',
  'ат-Такасур',
  'аль-Аср',
  'аль-Хумаза',
  'аль-Филь',
  'Курайш',
  'аль-Маун',
  'аль-Каусар',
  'аль-Кафирун',
  'ан-Наср',
  'аль-Масад',
  'аль-Ихляс',
  'аль-Фалак',
  'ан-Нас',
];

Map<String, int> getChapterAndVerse(int globalAyah) {
  int remaining = globalAyah;
  for (int i = 0; i < ayahCounts.length; i++) {
    if (remaining <= ayahCounts[i]) {
      return {'chapter': i + 1, 'verse': remaining};
    }
    remaining -= ayahCounts[i];
  }
  return {'chapter': 1, 'verse': 1};
}

class LearnedEntry {
  final String date;
  int count;
  LearnedEntry({required this.date, required this.count});
  Map<String, dynamic> toJson() => {'date': date, 'count': count};
  factory LearnedEntry.fromJson(Map<String, dynamic> j) =>
      LearnedEntry(date: j['date'], count: j['count']);
}

class PlanProvider extends ChangeNotifier {
  Timer? _syncDebounce;

  VoidCallback? onWidgetUpdate;

  /// Debounced Firestore sync — batches rapid actions into a single write
  /// 2 seconds after the last change. Runs in the background (non-blocking).
  void _scheduleSyncToFirestore() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 2), () {
      _syncToFirestore();
      onWidgetUpdate?.call();
    });
  }

  int currentAyah = 1;
  int currentSurahIndex = 0;
  int currentVerseInSurah = 1;
  List<int> selectedSurahs = [];
  int streak = 0;
  String? lastStudyDate;
  List<LearnedEntry> learnedHistory = [];

  /// Unique "chapter:verse" keys for every ayah the user has marked as learned.
  /// Used to prevent double-counting and to skip already-learned ayahs.
  Set<String> learnedAyahKeys = {};

  // Тыңдау — selected reciter (shared across all modes)
  int selectedReciterIdx = 0;

  // Edition IDs for verse-by-verse audio on cdn.islamic.network
  static const List<String> reciterEditionIds = [
    'ar.alafasy',
    'ar.abdurrahmaansudais',
    'ar.mahermuaiqly',
    'ar.husary',
    'ar.minshawi',
    'ar.abdullahbasfar',
    'ar.shuraim',
  ];

  String get audioEditionId =>
      reciterEditionIds[selectedReciterIdx.clamp(0, reciterEditionIds.length - 1)];

  /// Number of ayahs from [surahIndex] (0-based) that the user has learned.
  int surahLearnedCount(int surahIndex) {
    final chapter = surahIndex + 1;
    return learnedAyahKeys.where((k) {
      final colon = k.indexOf(':');
      return colon > 0 && int.tryParse(k.substring(0, colon)) == chapter;
    }).length;
  }

  Future<void> setReciterIdx(int idx) async {
    selectedReciterIdx = idx;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedReciterIdx', idx);
    notifyListeners();
  }

  // Оқу режимі
  String studyMode = 'Жаттау';
  int readAyah = 1;
  List<LearnedEntry> readHistory = [];
  List<int> selectedReadSurahs = [];
  int readSurahIndex = 0;
  int readSurahVerse = 1;
  int readPageNumber = 1;
  int readJuzNumber = 1;

  /// "YYYY-MM-DD:page" entries — tracks which pages were read on which date.
  // ignore: prefer_final_fields
  Set<String> _readPageDateMarks = {};

  /// Number of unique pages read today.
  int get readPagesToday {
    final today = DateTime.now().toString().substring(0, 10);
    return _readPageDateMarks.where((m) => m.startsWith('$today:')).length;
  }

  /// Total distinct page numbers ever read (page 50 on 3 days = 1 unique page).
  int get readPagesUnique =>
      _readPageDateMarks.map((m) => m.split(':').last).toSet().length;

  /// Total page-read events (page 50 on 3 days = 3 reads).
  int get readPagesTotal => _readPageDateMarks.length;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _posKey(Map<String, int> pos) => '${pos['chapter']}:${pos['verse']}';

  /// Advance position by one step without saving (pure in-memory).
  void _advanceMemory() {
    if (selectedSurahs.isEmpty) {
      const total = 6236;
      currentAyah = currentAyah >= total ? 1 : currentAyah + 1;
    } else {
      final ayahsInSurah = ayahCounts[selectedSurahs[currentSurahIndex]];
      if (currentVerseInSurah < ayahsInSurah) {
        currentVerseInSurah++;
      } else {
        currentSurahIndex = (currentSurahIndex + 1) % selectedSurahs.length;
        currentVerseInSurah = 1;
      }
    }
  }

  /// Skip over any ayahs that are already in learnedAyahKeys.
  void _skipLearned() {
    final maxSteps = selectedSurahs.isEmpty
        ? 6236
        : selectedSurahs.fold(0, (s, i) => s + ayahCounts[i]);
    int steps = 0;
    while (learnedAyahKeys.contains(_posKey(currentPosition)) &&
        steps < maxSteps) {
      _advanceMemory();
      steps++;
    }
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load from local storage first (fast, works offline)
    currentAyah = prefs.getInt('currentAyah') ?? 1;
    streak = prefs.getInt('streak') ?? 0;
    lastStudyDate = prefs.getString('lastStudyDate');
    currentSurahIndex = prefs.getInt('currentSurahIndex') ?? 0;
    currentVerseInSurah = prefs.getInt('currentVerseInSurah') ?? 1;
    studyMode = prefs.getString('studyMode') ?? 'Жаттау';
    selectedReciterIdx = prefs.getInt('selectedReciterIdx') ?? 0;
    readAyah = prefs.getInt('readAyah') ?? 1;

    final surahsJson = prefs.getString('selectedSurahs');
    if (surahsJson != null) {
      selectedSurahs = List<int>.from(jsonDecode(surahsJson));
    }

    final historyJson = prefs.getString('learnedHistory');
    if (historyJson != null) {
      learnedHistory = (jsonDecode(historyJson) as List)
          .map((e) => LearnedEntry.fromJson(e))
          .toList();
    }

    final readJson = prefs.getString('readHistory');
    if (readJson != null) {
      readHistory = (jsonDecode(readJson) as List)
          .map((e) => LearnedEntry.fromJson(e))
          .toList();
    }

    final readSurahsJson = prefs.getString('selectedReadSurahs');
    if (readSurahsJson != null) {
      selectedReadSurahs = List<int>.from(jsonDecode(readSurahsJson));
    }
    readSurahIndex = prefs.getInt('readSurahIndex') ?? 0;
    readSurahVerse = prefs.getInt('readSurahVerse') ?? 1;
    readPageNumber = prefs.getInt('readPageNumber') ?? 1;
    readJuzNumber = prefs.getInt('readJuzNumber') ?? 1;

    final keysJson = prefs.getString('learnedAyahKeys');
    if (keysJson != null) {
      learnedAyahKeys = Set<String>.from(jsonDecode(keysJson));
    }

    final pageMarksJson = prefs.getString('readPageDateMarks');
    if (pageMarksJson != null) {
      _readPageDateMarks = Set<String>.from(jsonDecode(pageMarksJson));
    }

    // Clamp indices so they're always valid after loading
    if (selectedSurahs.isNotEmpty) {
      currentSurahIndex = currentSurahIndex.clamp(0, selectedSurahs.length - 1);
    } else {
      currentSurahIndex = 0;
    }
    if (selectedReadSurahs.isNotEmpty) {
      readSurahIndex = readSurahIndex.clamp(0, selectedReadSurahs.length - 1);
    } else {
      readSurahIndex = 0;
    }

    notifyListeners();

    // 2. If logged in, overwrite with Firestore data (source of truth for cloud sync)
    if (FirestoreService.isLoggedIn) {
      final remote = await FirestoreService.loadProgress();
      if (remote != null) {
        final n = FirestoreService.normalizeProgress(remote);
        currentAyah = n['currentAyah'];
        currentSurahIndex = n['currentSurahIndex'];
        currentVerseInSurah = n['currentVerseInSurah'];
        streak = n['streak'];
        lastStudyDate = n['lastStudyDate'] as String?;
        readAyah = n['readAyah'];
        studyMode = n['studyMode'];
        selectedSurahs = List<int>.from(n['selectedSurahs']);

        learnedHistory = (jsonDecode(n['learnedHistory']) as List)
            .map((e) => LearnedEntry.fromJson(e))
            .toList();
        readHistory = (jsonDecode(n['readHistory']) as List)
            .map((e) => LearnedEntry.fromJson(e))
            .toList();

        // Mirror Firestore state to local storage
        await prefs.setInt('currentAyah', currentAyah);
        await prefs.setInt('currentSurahIndex', currentSurahIndex);
        await prefs.setInt('currentVerseInSurah', currentVerseInSurah);
        await prefs.setInt('streak', streak);
        await prefs.setInt('readAyah', readAyah);
        await prefs.setString('studyMode', studyMode);
        if (lastStudyDate != null) {
          await prefs.setString('lastStudyDate', lastStudyDate!);
        }
        await prefs.setString(
            'selectedSurahs', jsonEncode(selectedSurahs));
        await prefs.setString('learnedHistory', n['learnedHistory']);
        await prefs.setString('readHistory', n['readHistory']);

        final remoteKeys = n['learnedAyahKeys'] as List<String>;
        learnedAyahKeys = remoteKeys.toSet();
        await prefs.setString('learnedAyahKeys', jsonEncode(remoteKeys));

        selectedReadSurahs = List<int>.from(n['selectedReadSurahs']);
        readSurahIndex = n['readSurahIndex'];
        readSurahVerse = n['readSurahVerse'];
        readPageNumber = n['readPageNumber'];
        readJuzNumber = n['readJuzNumber'] ?? readJuzNumber;
        await prefs.setString('selectedReadSurahs', jsonEncode(selectedReadSurahs));
        await prefs.setInt('readSurahIndex', readSurahIndex);
        await prefs.setInt('readSurahVerse', readSurahVerse);
        await prefs.setInt('readPageNumber', readPageNumber);
        await prefs.setInt('readJuzNumber', readJuzNumber);

        notifyListeners();
      }
    }
  }

  Future<void> _syncToFirestore() async {
    try {
      await FirestoreService.saveProgress(
        currentAyah: currentAyah,
        currentSurahIndex: currentSurahIndex,
        currentVerseInSurah: currentVerseInSurah,
        streak: streak,
        lastStudyDate: lastStudyDate,
        readAyah: readAyah,
        selectedSurahs: selectedSurahs,
        studyMode: studyMode,
        learnedHistory: learnedHistory.map((e) => e.toJson()).toList(),
        readHistory: readHistory.map((e) => e.toJson()).toList(),
        learnedAyahKeys: learnedAyahKeys.toList(),
        selectedReadSurahs: selectedReadSurahs,
        readSurahIndex: readSurahIndex,
        readSurahVerse: readSurahVerse,
        readPageNumber: readPageNumber,
        readJuzNumber: readJuzNumber,
      );
      FriendService.publishMyStats(
        streak: streak,
        learnedCount: learnedAyahKeys.length,
        lastStudyDate: lastStudyDate ?? '',
      );
    } catch (_) {}
  }

  Future<void> resetLearnedStats() async {
    learnedHistory = [];
    learnedAyahKeys = {};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learnedHistory', jsonEncode([]));
    await prefs.setString('learnedAyahKeys', jsonEncode([]));
    _scheduleSyncToFirestore();
  }

  Future<void> resetReadStats() async {
    readHistory = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('readHistory', jsonEncode([]));
    _scheduleSyncToFirestore();
  }

  Future<void> resetPageStats() async {
    _readPageDateMarks = {};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('readPageDateMarks', jsonEncode([]));
  }

  Future<void> setSelectedSurahs(List<int> surahs) async {
    selectedSurahs = surahs;
    currentSurahIndex = 0;
    currentVerseInSurah = 1;
    _skipLearned(); // jump past any already-learned ayahs in the new list
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSurahs', jsonEncode(surahs));
    await prefs.setInt('currentSurahIndex', currentSurahIndex);
    await prefs.setInt('currentVerseInSurah', currentVerseInSurah);
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  Future<void> setKnownSurahs(List<int> known) async {
    final all = List.generate(114, (i) => i);
    final toLearn = all.where((i) => !known.contains(i)).toList();
    await setSelectedSurahs(toLearn);
  }

  /// Removes a fully-learned surah from the selected list and repositions
  /// to the next unlearned ayah in the remaining surahs.
  Future<void> removeSurahFromSelected(int surahIdx) async {
    final removedPos = selectedSurahs.indexOf(surahIdx);
    selectedSurahs.remove(surahIdx);
    if (selectedSurahs.isNotEmpty) {
      // If the removed surah was before the current position, shift index left
      // so we still point to the same (next) surah after removal.
      if (removedPos >= 0 && removedPos < currentSurahIndex) {
        currentSurahIndex--;
      }
      currentSurahIndex = currentSurahIndex.clamp(0, selectedSurahs.length - 1);
      currentVerseInSurah = 1;
      _skipLearned();
    } else {
      currentSurahIndex = 0;
      currentVerseInSurah = 1;
      _skipLearned(); // advance past already-learned ayahs in global mode
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSurahs', jsonEncode(selectedSurahs));
    await prefs.setInt('currentSurahIndex', currentSurahIndex);
    await prefs.setInt('currentVerseInSurah', currentVerseInSurah);
    if (selectedSurahs.isEmpty) {
      await prefs.setInt('currentAyah', currentAyah);
    }
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  Future<void> nextAyah() async {
    _advanceMemory();
    _skipLearned(); // skip any consecutive already-learned ayahs
    final prefs = await SharedPreferences.getInstance();
    if (selectedSurahs.isEmpty) {
      await prefs.setInt('currentAyah', currentAyah);
    } else {
      await prefs.setInt('currentSurahIndex', currentSurahIndex);
      await prefs.setInt('currentVerseInSurah', currentVerseInSurah);
    }
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  Future<void> updateStreak() async {
    final today = DateTime.now().toString().substring(0, 10);
    if (lastStudyDate == today) return;

    final yesterday = DateTime.now().subtract(const Duration(days: 1))
        .toString().substring(0, 10);

    if (lastStudyDate == yesterday) {
      streak++;
    } else {
      streak = 1;
    }

    lastStudyDate = today;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak', streak);
    await prefs.setString('lastStudyDate', today);
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  Future<void> recordLearned() async {
    final key = _posKey(currentPosition);

    // Guard: this exact ayah was already counted — don't double-count.
    if (learnedAyahKeys.contains(key)) return;
    learnedAyahKeys.add(key);

    final today = DateTime.now().toString().substring(0, 10);

    final existingLearn = learnedHistory.where((h) => h.date == today).firstOrNull;
    if (existingLearn != null) {
      existingLearn.count++;
    } else {
      learnedHistory.add(LearnedEntry(date: today, count: 1));
    }

    // Memorizing an ayah also counts as reading it.
    final existingRead = readHistory.where((h) => h.date == today).firstOrNull;
    if (existingRead != null) {
      existingRead.count++;
    } else {
      readHistory.add(LearnedEntry(date: today, count: 1));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'learnedAyahKeys',
      jsonEncode(learnedAyahKeys.toList()),
    );
    await prefs.setString(
      'learnedHistory',
      jsonEncode(learnedHistory.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'readHistory',
      jsonEncode(readHistory.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  Map<String, int> get currentPosition {
    if (selectedSurahs.isNotEmpty) {
      return {
        'chapter': selectedSurahs[currentSurahIndex] + 1,
        'verse': currentVerseInSurah,
      };
    }
    return getChapterAndVerse(currentAyah);
  }

  Map<String, int> get currentReadPosition {
    if (selectedReadSurahs.isNotEmpty) {
      return {
        'chapter': selectedReadSurahs[readSurahIndex] + 1,
        'verse': readSurahVerse,
      };
    }
    return getChapterAndVerse(readAyah);
  }

  Future<void> setStudyMode(String mode) async {
    studyMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('studyMode', mode);
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  Future<void> setSelectedReadSurahs(List<int> surahs) async {
    selectedReadSurahs = surahs;
    readSurahIndex = 0;
    readSurahVerse = 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedReadSurahs', jsonEncode(surahs));
    await prefs.setInt('readSurahIndex', 0);
    await prefs.setInt('readSurahVerse', 1);
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  Future<void> _saveReadPos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('readSurahIndex', readSurahIndex);
    await prefs.setInt('readSurahVerse', readSurahVerse);
    await prefs.setInt('readAyah', readAyah);
    await prefs.setInt('readPageNumber', readPageNumber);
    await prefs.setInt('readJuzNumber', readJuzNumber);
  }

  Future<void> nextReadPage() async {
    if (readPageNumber < 604) readPageNumber++;
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> previousReadPage() async {
    if (readPageNumber > 1) readPageNumber--;
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> setReadPageNumber(int page) async {
    readPageNumber = page.clamp(1, 604);
    notifyListeners();
    await _saveReadPos();
  }

  Future<void> nextReadJuz() async {
    if (readJuzNumber < 30) readJuzNumber++;
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> previousReadJuz() async {
    if (readJuzNumber > 1) readJuzNumber--;
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> setReadJuzNumber(int juz) async {
    readJuzNumber = juz.clamp(1, 30);
    notifyListeners();
    await _saveReadPos();
  }

  Future<void> previousReadAyah() async {
    if (selectedReadSurahs.isNotEmpty) {
      if (readSurahVerse > 1) {
        readSurahVerse--;
      } else {
        readSurahIndex =
            (readSurahIndex - 1 + selectedReadSurahs.length) %
                selectedReadSurahs.length;
        readSurahVerse = ayahCounts[selectedReadSurahs[readSurahIndex]];
      }
    } else {
      readAyah = readAyah <= 1 ? 6236 : readAyah - 1;
    }
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> jumpToNextReadSurah() async {
    if (selectedReadSurahs.isNotEmpty) {
      readSurahIndex = (readSurahIndex + 1) % selectedReadSurahs.length;
      readSurahVerse = 1;
    } else {
      final ch = currentReadPosition['chapter']!;
      if (ch < 114) {
        int g = 1;
        for (int i = 0; i < ch; i++) { g += ayahCounts[i]; }
        readAyah = g;
      }
    }
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> jumpToPrevReadSurah() async {
    if (selectedReadSurahs.isNotEmpty) {
      readSurahIndex =
          (readSurahIndex - 1 + selectedReadSurahs.length) %
              selectedReadSurahs.length;
      readSurahVerse = 1;
    } else {
      final ch = currentReadPosition['chapter']!;
      if (ch > 1) {
        int g = 1;
        for (int i = 0; i < ch - 2; i++) { g += ayahCounts[i]; }
        readAyah = g;
      }
    }
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> advanceReadPage(int pageSize) async {
    if (selectedReadSurahs.isNotEmpty) {
      final total = ayahCounts[selectedReadSurahs[readSurahIndex]];
      final next = readSurahVerse + pageSize;
      if (next <= total) {
        readSurahVerse = next;
      } else {
        readSurahIndex = (readSurahIndex + 1) % selectedReadSurahs.length;
        readSurahVerse = 1;
      }
    } else {
      readAyah = (readAyah + pageSize).clamp(1, 6236);
    }
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> goBackReadPage(int pageSize) async {
    if (selectedReadSurahs.isNotEmpty) {
      final prev = readSurahVerse - pageSize;
      if (prev >= 1) {
        readSurahVerse = prev;
      } else {
        readSurahIndex =
            (readSurahIndex - 1 + selectedReadSurahs.length) %
                selectedReadSurahs.length;
        readSurahVerse = 1;
      }
    } else {
      readAyah = (readAyah - pageSize).clamp(1, 6236);
    }
    await _saveReadPos();
    notifyListeners();
  }

  Future<void> nextReadAyah() async {
    if (selectedReadSurahs.isNotEmpty) {
      final ayahsInSurah = ayahCounts[selectedReadSurahs[readSurahIndex]];
      if (readSurahVerse < ayahsInSurah) {
        readSurahVerse++;
      } else {
        readSurahIndex = (readSurahIndex + 1) % selectedReadSurahs.length;
        readSurahVerse = 1;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('readSurahIndex', readSurahIndex);
      await prefs.setInt('readSurahVerse', readSurahVerse);
    } else {
      const total = 6236;
      readAyah = readAyah >= total ? 1 : readAyah + 1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('readAyah', readAyah);
    }
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  /// Records that the user read [page] today (called when swiping "Оқыдым" in page mode).
  Future<void> markPageRead(int page) async {
    if (page < 1) return;
    final today = DateTime.now().toString().substring(0, 10);
    _readPageDateMarks.add('$today:$page');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'readPageDateMarks', jsonEncode(_readPageDateMarks.toList()));
    notifyListeners();
  }

  Future<void> recordRead({int count = 1}) async {
    final today = DateTime.now().toString().substring(0, 10);
    final existing = readHistory.where((h) => h.date == today).firstOrNull;
    if (existing != null) {
      existing.count += count;
    } else {
      readHistory.add(LearnedEntry(date: today, count: count));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'readHistory',
      jsonEncode(readHistory.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
    _scheduleSyncToFirestore();
  }
}