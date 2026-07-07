import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../services/quran_api.dart'
    show ruTranslationId, enTranslationId;
import 'plan_provider.dart'
    show surahNames, surahNamesRu, surahNamesEn;

class LanguageProvider extends ChangeNotifier {
  String _lang = 'kz';

  String get lang => _lang;
  bool get isRu => _lang == 'ru';
  bool get isEn => _lang == 'en';

  /// English translation editions on quran.com: (resource id, label).
  static const enTranslations = [
    (20, 'Saheeh International'),
    (131, 'Dr. Mustafa Khattab — The Clear Quran'),
    (85, 'M.A.S. Abdel Haleem'),
    (84, 'T. Usmani'),
    (19, 'M. Pickthall'),
    (22, 'A. Yusuf Ali'),
    (95, 'A. Maududi — Tafhim'),
    (203, 'Al-Hilali & Khan'),
  ];

  int _enTranslationId = enTranslationId;

  /// Currently selected English translation edition.
  int get enTranslationChoice => _enTranslationId;

  String get enTranslationLabel => enTranslations
      .firstWhere((t) => t.$1 == _enTranslationId,
          orElse: () => enTranslations.first)
      .$2;

  Future<void> setEnTranslation(int id) async {
    if (_enTranslationId == id) return;
    _enTranslationId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('enTranslationId', id);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('appLang') ?? 'kz';
    _enTranslationId = prefs.getInt('enTranslationId') ?? enTranslationId;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLang', lang);
  }

  /// Translate a key. Falls back to Kazakh, then the key itself.
  String tr(String key) =>
      appStrings[key]?[_lang] ?? appStrings[key]?['kz'] ?? key;

  /// Picks the variant for the current language.
  String pick(String kz, String ru, String en) {
    switch (_lang) {
      case 'ru': return ru;
      case 'en': return en;
      default:   return kz;
    }
  }

  /// Surah names in the current language.
  List<String> get surahNamesL10n {
    switch (_lang) {
      case 'ru': return surahNamesRu;
      case 'en': return surahNamesEn;
      default:   return surahNames;
    }
  }

  // ── Dynamic strings ───────────────────────────────────────────────────────

  String daysAgo(int n) =>
      pick('$n күн бұрын', '$n дн. назад', '$n d. ago');

  String weeksAgo(int n) =>
      pick('$n апта бұрын', '$n апт. назад', '$n wk. ago');

  String monthsAgo(int n) =>
      pick('$n ай бұрын', '$n мес. назад', '$n mo. ago');

  String juzProgress(int assigned) =>
      pick('$assigned/30 жүз', '$assigned/30 джузов', '$assigned/30 juz');

  String myJuzLabel(int juz) =>
      pick('$juz-жүз', '$juz-джуз', 'Juz $juz');

  String khatamCount(int n) =>
      pick('Хатым: $n', 'Хатм: $n', 'Khatam: $n');

  String assignedJuz(int assigned, int total) =>
      pick('$assigned/$total жүз', '$assigned/$total джузов', '$assigned/$total juz');

  String completedJuz(int n) =>
      pick('$n бітті ✓', '$n завершено ✓', '$n done ✓');

  String surahFullMemorized(String name, int total) => pick(
      '$name сүресін\n$total аятты толық жаттадыңыз! 🤲',
      '$name сурасы\n$total аят толық жаттадыңыз! 🤲',
      'You memorized Surah $name\ncompletely — all $total ayahs! 🤲');

  String streakDays(int n) =>
      pick('$n күн', '$n дней', '$n days');

  String learnedAyahs(int n) =>
      pick('$n аят', '$n аят', '$n ayahs');

  String memorizeProgress(double pct) => pick(
      'Жаттау прогресі: ${pct.toStringAsFixed(0)}%',
      'Прогресс запоминания: ${pct.toStringAsFixed(0)}%',
      'Memorization progress: ${pct.toStringAsFixed(0)}%');

  String deleteGroupConfirm(String name) => pick(
      '"$name" тобын толығымен жойасыз ба? Бұл әрекетті қайтару мүмкін емес.',
      '"$name" группасын толықтай жойасыз ба? Бұл әрекетті қайтару мүмкін емес.',
      'Delete the group "$name" permanently? This cannot be undone.');

  String leaveGroupConfirm(String name) => pick(
      '"$name" топтан шығарасыз ба?',
      '"$name" тобынан шығасыз ба?',
      'Leave the group "$name"?');

  String removeMemberConfirm(String name) => pick(
      '"$name" шығарасыз ба?',
      '"$name" мүшесін шығарасыз ба?',
      'Remove "$name" from the group?');

  String removeFriendConfirm(String name) => pick(
      '"$name" достар тізімінен шығарасыз ба?',
      '"$name" достар тізімінен шығарасыз ба?',
      'Remove "$name" from your friends?');

  String juzSelectedLabel(int juz) =>
      pick('$juz-жүз таңдалды', '$juz-джуз таңдалды', 'Juz $juz selected');

  String unmarkJuzConfirm(int juz) => pick(
      '$juz-жүз белгісін қайтарасыз ба?',
      '$juz-джуз белгісін қайтарасыз ба?',
      'Remove the mark from juz $juz?');

  String surahMemorizedSuffix(int total) => pick(
      '\n$total аятты толық жаттадыңыз! 🤲',
      '\n$total аятов полностью запомнили! 🤲',
      '\nYou memorized all $total ayahs! 🤲');

  String multiAyahHeader(String unit, int num, int count, String surahName) {
    switch (_lang) {
      case 'ru':
        switch (unit) {
          case 'page': return '$num-стр.  •  $count аят';
          case 'juz':  return '$num-джуз  •  $count аят';
          default:     return '$surahName  •  $count аят';
        }
      case 'en':
        switch (unit) {
          case 'page': return 'Page $num  •  $count ayahs';
          case 'juz':  return 'Juz $num  •  $count ayahs';
          default:     return '$surahName  •  $count ayahs';
        }
      default:
        switch (unit) {
          case 'page': return '$num-бет  •  $count аят';
          case 'juz':  return '$num-жүз  •  $count аят';
          default:     return '$surahName  •  $count аят';
        }
    }
  }

  String readUnitSwipeHint(String unit) {
    switch (unit) {
      case 'surah': return pick('Сүре', 'Сура', 'Surah');
      case 'juz':   return pick('Жүз', 'Джуз', 'Juz');
      default:      return pick('Бет', 'Стр.', 'Page');
    }
  }

  String sajdaInlineText() => pick(
      'سَجْدَةٌ  •  Тіләуат сәждесі — сәжде жасаңыз',
      'سَجْدَةٌ  •  Сажда тиляват — совершите сажда',
      'سَجْدَةٌ  •  Sajdah of recitation — perform sajdah');

  String selectedSurahsCount(int n) =>
      pick('Таңдалды: $n сүре', 'Выбрано: $n сур', 'Selected: $n surahs');

  String selectedCount(int n) =>
      pick('Таңдалды: $n', 'Выбрано: $n', 'Selected: $n');

  String streakLabel(int days) => pick(
      '🔥  $days күн қатарынан',
      '🔥  $days дней подряд',
      '🔥  $days days in a row');

  String genderAgeLine(String gender, String age) {
    final String gLabel;
    switch (_lang) {
      case 'ru': gLabel = gender == 'male' ? 'Мужчина' : 'Женщина'; break;
      case 'en': gLabel = gender == 'male' ? 'Male' : 'Female'; break;
      default:   gLabel = gender == 'male' ? 'Ер азамат' : 'Әйел';
    }
    final agePart = pick('$age жас', '$age лет', '$age y.o.');
    return '$gLabel  •  $agePart';
  }

  String totalReadFmt(int n) =>
      pick('Барлығы: $n рет', 'Всего: $n раз', 'Total: $n times');

  String remainingAyahs(int n) =>
      pick('Қалды: $n аят', 'Осталось: $n аят', 'Remaining: $n ayahs');

  String friendAddedMsg(String name) => pick(
      '$name достар тізіміне қосылды!',
      '$name добавлен в друзья!',
      '$name added as a friend!');

  String friendActivityLabel(String dateStr) {
    if (dateStr.isEmpty) return tr('inactive');
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return tr('inactive');
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return tr('activeToday');
    if (diff == 1) return tr('activeYesterday');
    if (diff < 7) return daysAgo(diff);
    if (diff < 30) return weeksAgo(diff ~/ 7);
    return monthsAgo(diff ~/ 30);
  }

  List<String> get weekdays {
    switch (_lang) {
      case 'ru': return ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      case 'en': return ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
      default:   return ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жк'];
    }
  }

  List<String> get months {
    switch (_lang) {
      case 'ru':
        return ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
                'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
      case 'en':
        return ['January', 'February', 'March', 'April', 'May', 'June',
                'July', 'August', 'September', 'October', 'November', 'December'];
      default:
        return ['Қаңтар', 'Ақпан', 'Наурыз', 'Сәуір', 'Мамыр', 'Маусым',
                'Шілде', 'Тамыз', 'Қыркүйек', 'Қазан', 'Қараша', 'Желтоқсан'];
    }
  }

  String khatamLabel2(int n) =>
      pick('Хатым: $n', 'Хатм: $n', 'Khatam: $n');

  String juzAssignedLabel(int assigned) =>
      pick('$assigned/30 жүз', '$assigned/30 джузов', '$assigned/30 juz');

  String memorizeProgressLabel(double pct) => pick(
      'Жаттау прогресі: ${pct.toStringAsFixed(0)}%',
      'Прогресс запоминания: ${pct.toStringAsFixed(0)}%',
      'Memorization progress: ${pct.toStringAsFixed(0)}%');

  String goalNotifTitle(bool isLearn) => pick(
      'Dudi — ${isLearn ? 'Жаттау' : 'Оқу'} мақсаты',
      'Dudi — ${isLearn ? 'Выучить' : 'Чтение'}',
      'Dudi — ${isLearn ? 'Memorization' : 'Reading'} goal');

  String goalNotifBody(bool isLearn, String deadlineLabel) => pick(
      '${isLearn ? 'Жаттау' : 'Оқу'} мақсатыңды ұмытпа! 📖 $deadlineLabel',
      '${isLearn ? 'Цель запоминания' : 'Цель чтения'}! 📖 $deadlineLabel',
      'Don\'t forget your ${isLearn ? 'memorization' : 'reading'} goal! 📖 $deadlineLabel');

  String pagesPerDayFmt(int n) =>
      pick('$n бет / күн', '$n стр. / день', '$n pages / day');

  String pagesFmt(int n) =>
      pick('$n бет', '$n стр.', '$n pages');

  String knownSurahsLabel(int n) =>
      pick('Білетін сүрелер: $n', 'Известных сур: $n', 'Surahs known: $n');

  String resetKhatamsConfirm(String groupName) => pick(
      '"$groupName" тобындағы хатымдар санын тастаймыз ба?',
      'Сбросить хатмы в группе "$groupName"?',
      'Reset khatams in the group "$groupName"?');

  String addedYouMsg(String name) => pick(
      '$name сізді достар тізіміне қосты! 🤝',
      '$name добавил вас в друзья! 🤝',
      '$name added you as a friend! 🤝');

  String khatamGroupMsg(int number) => pick(
      'Топ $number-ші рет Құранды толық хатым жасады!\n\nХатым дұғасын оқу — сүннет. Ол оқылған Құранның сауабын бекітеді.',
      'Группа прочитала Коран $number-й раз!\n\nДуа хатма — сунна. Это закрепляет саваб прочитанного Корана.',
      'The group completed the Quran for the $number time!\n\nReciting the khatam dua is a sunnah. It seals the reward of the completed Quran.');

  String khatamGroupSimple(int number) => pick(
      'Топ $number-ші рет Құранды хатым жасады!\nЖаңа жүздерді таңдауға болады.',
      'Группа прочитала Коран $number-й раз!\nМожно выбрать новые джузы.',
      'The group completed the Quran for the $number time!\nYou can pick new juz now.');

  String khatamHistoryTitle(int n) =>
      pick('Хатым тарихы ($n)', 'История хатмов ($n)', 'Khatam history ($n)');

  String khatamNumber(int n) =>
      pick('$n-хатым', '$n-й хатм', 'Khatam #$n');

  String membersTitle(int n) =>
      pick('Мүшелер ($n)', 'Участники ($n)', 'Members ($n)');

  // ── Ramadan хатм challenge ──────────────────────────────────────────────
  String get ramadanTitle =>
      pick('🌙 Рамазан хатым', '🌙 Рамадан хатм', '🌙 Ramadan Khatam');
  String get ramadanSubtitle => pick(
      'Рамазанда Құранды толық оқы — күніне 1 жүз',
      'Прочитай весь Коран за Рамадан — 1 джуз в день',
      'Read the whole Quran during Ramadan — 1 juz a day');
  String ramadanCountdown(int days) => pick(
      'Рамазанға дейін $days күн',
      'До Рамадана $days дн.',
      '$days days until Ramadan');
  String ramadanDayLabel(int day) =>
      pick('$day-күн / 30', 'День $day из 30', 'Day $day of 30');
  String ramadanJuzProgress(int done) =>
      pick('$done/30 жүз', '$done/30 джуз', '$done/30 juz');
  String ramadanBehind(int need) => pick(
      'Артта қалдыңыз: бүгін тағы $need жүз керек',
      'Отставание: нужно ещё $need джуз сегодня',
      'Behind schedule: $need more juz needed today');
  String get ramadanOnTrack =>
      pick('Кестедесің 👍', 'Ты в графике 👍', 'You\'re on track 👍');
  String get ramadanJoin => pick('Қатысу', 'Участвовать', 'Join');
  String get ramadanJoined =>
      pick('Қатысудасыз ✓', 'Вы участвуете ✓', 'You\'re in ✓');
  String get ramadanMarkBtn =>
      pick('Жүзді оқыдым ✓', 'Джуз прочитан ✓', 'Juz read ✓');
  String get ramadanMarkedToday =>
      pick('Бүгін белгіленді ✓', 'Сегодня отмечено ✓', 'Marked today ✓');
  String get ramadanDone => pick(
      'Хатым аяқталды! Барака Аллаһу фик',
      'Хатм завершён! Барака Аллаху фик',
      'Khatam complete! BarakAllahu fik');
  String get ramadanLeave => pick('Шығу', 'Покинуть', 'Leave');

  String juzDone(int juz) =>
      pick('$juz-жүз ✓', '$juz-джуз ✓', 'Juz $juz ✓');

  String juzInProgress(int juz) => pick(
      '$juz-жүз оқуда', '$juz-джуз читается', 'Juz $juz in progress');

  String codeCopied(String code) => pick(
      'Код көшірілді: $code', 'Код скопирован: $code', 'Code copied: $code');

  String inviteCodeLabel(String code) => pick(
      'Шақыру коды: $code', 'Код приглашения: $code', 'Invite code: $code');

  String myJuzBanner(int juz) => pick(
      'Сіздің жүзіңіз: $juz-жүз', 'Ваш джуз: $juz-джуз', 'Your juz: $juz');

  String get duaTranslation {
    switch (_lang) {
      case 'ru':
        return 'О, Аллах!\n'
            'Смилуйся над нами через Коран,\n'
            'сделай его для нас имамом, светом, руководством и милостью.\n\n'
            'О, Аллах!\n'
            'Напомни нам то, что мы забыли из него,\n'
            'научи нас тому, что мы не знаем.\n'
            'Дай нам читать его в ночное время и в часы дня.\n'
            'Сделай его нашим доводом, о Господь миров!\n\n'
            'О, Аллах!\n'
            'Исправь нашу религию, которая является защитой нашего дела.\n'
            'Исправь нашу мирскую жизнь, в которой наше существование.\n'
            'Исправь нашу будущую жизнь, к которой мы возвращаемся.\n\n'
            'О, Аллах!\n'
            'Сделай Коран весной наших сердец,\n'
            'светом наших грудей,\n'
            'рассеивателем наших печалей,\n'
            'уходом наших забот и горестей.\n\n'
            'Да благословит Аллах нашего Пророка Мухаммада (ﷺ),\n'
            'его семью и всех его сподвижников.\n'
            'Амин.';
      case 'en':
        return 'O Allah!\n'
            'Have mercy on us through the Quran,\n'
            'make it for us an imam, a light, a guidance and a mercy.\n\n'
            'O Allah!\n'
            'Remind us of what we have forgotten of it,\n'
            'teach us of it that which we do not know.\n'
            'Grant us its recitation in the hours of the night and the day.\n'
            'Make it a proof for us, O Lord of the worlds!\n\n'
            'O Allah!\n'
            'Set right our religion, which is the safeguard of our affairs.\n'
            'Set right our worldly life, in which is our livelihood.\n'
            'Set right our Hereafter, to which we shall return.\n\n'
            'O Allah!\n'
            'Make the Quran the spring of our hearts,\n'
            'the light of our chests,\n'
            'the remover of our sorrows,\n'
            'and the reliever of our worries and grief.\n\n'
            'May Allah bless our Prophet Muhammad (ﷺ),\n'
            'his family and all his companions.\n'
            'Ameen.';
      default:
        return 'Уа, Алла!\n'
            'Бізге Құран арқылы рақым ет.\n'
            'Оны бізге жол көрсетуші, нұр, туралық және мейірім ет.\n\n'
            'Уа, Алла!\n'
            'Ұмытқанымызды Құран арқылы есімізге сал,\n'
            'білмегенімізді үйрет.\n'
            'Күндіз-түні Құран оқуды нәсіп ет.\n'
            'Қиямет күні оны бізге айғақ ет, ей әлемдердің Раббысы!\n\n'
            'Уа, Алла!\n'
            'Дінімізді түзет, өйткені ол біздің қорғанымыз.\n'
            'Дүниемізді түзет, өйткені онда біздің тіршілігіміз бар.\n'
            'Ақыретімізді түзет, өйткені оған қайтамыз.\n\n'
            'Уа, Алла!\n'
            'Құранды жүректеріміздің көктемі,\n'
            'көкіректеріміздің нұры,\n'
            'қайғымыздың кетуі,\n'
            'уайымдарымыздың сейілуі ет.\n\n'
            'Алланың салауаты мен сәлемі\n'
            'Пайғамбарымыз Мұхаммедке (с.а.у.),\n'
            'оның отбасы мен сахабаларына болсын.\n'
            'Әмин.';
    }
  }

  String sleepRemainingLabel(String timeStr) =>
      pick('Қалды: $timeStr', 'Осталось: $timeStr', 'Remaining: $timeStr');

  String surahWarnTitle(bool isLearned) => pick(
      isLearned ? 'Бұл сүрені жаттадыңыз' : 'Бұл сүрені білесіз',
      isLearned ? 'Вы выучили эту суру' : 'Вы знаете эту суру',
      isLearned ? 'You memorized this surah' : 'You know this surah');

  String surahWarnBody(String name, bool isLearned) {
    switch (_lang) {
      case 'ru':
        final verb = isLearned ? 'выучили' : 'знаете';
        return 'Вы $verb суру «$name».\nВсё равно добавить в список для изучения?';
      case 'en':
        final verb = isLearned ? 'memorized' : 'know';
        return 'You already $verb Surah "$name".\nAdd it to the study list anyway?';
      default:
        final verb = isLearned ? 'жаттадыңыз' : 'білесіз';
        return '«$name» сүресін $verb.\nДегенмен жаттау тізіміне қосасыз ба?';
    }
  }

  String selectedFraction(int n, int total) => pick(
      'Таңдалды: $n / $total', 'Выбрано: $n / $total', 'Selected: $n / $total');

  String surahsFmt(int n) =>
      pick('$n сүре', '$n сур', '$n surahs');

  String saveSurahsBtn(int n) => pick(
      'Сақтау  ($n сүре)', 'Сохранить ($n сур)', 'Save ($n surahs)');

  String shareCodeMsg(String code) => pick(
      'Qari — менің дос кодым: $code\n'
          'Qari қосымшасын жүктеп, Достар бөліміне кіріп, кодты енгізіңіз! 📖',
      'Qari — мой код друга: $code\n'
          'Скачай Qari, зайди в «Друзья» и введи код! 📖',
      'Qari — my friend code: $code\n'
          'Download Qari, open "Friends" and enter the code! 📖');

  String greetingMsg(String name) {
    final String hi;
    switch (_lang) {
      case 'ru':
        hi = name.isEmpty ? 'Ассаляму алейкум!' : 'Ассаляму алейкум, $name!';
        break;
      case 'en':
        hi = name.isEmpty ? 'Assalamu alaikum!' : 'Assalamu alaikum, $name!';
        break;
      default:
        hi = name.isEmpty ? 'Ассаламу алейкум!' : 'Ассаламу алейкум, $name!';
    }
    final body = pick(
        'Мен Dudi — сіздің Құран жолдасыңыз. Сұрақ қойыңыз, мотивация сұраңыз немесе квизді бастаңыз!',
        'Я Dudi — ваш Коранный помощник. Задайте вопрос, попросите мотивацию или начните квиз!',
        'I\'m Dudi — your Quran companion. Ask a question, get motivation or start a quiz!');
    return '$hi $body';
  }

  String noLearnedAyahs() => pick(
      'Алдымен аяттарды жатта! Жаттау режимінде "Жаттадым!" басыңыз.',
      'Сначала выучи аяты! В режиме запоминания нажмите "Запомнил!".',
      'Memorize some ayahs first! Tap "Memorized!" in memorization mode.');

  String kqSubtitle(int n) => pick(
      '$n сұрақ · Дұрыс жауапты таңда',
      '$n вопросов · Выберите правильный ответ',
      '$n questions · Pick the right answer');

  String streakTitle(int n) =>
      pick('$n күн қатарынан', '$n дней подряд', '$n days in a row');

  String learnedAyahsDesc(int n) => pick(
      'Жатталған $n аяттан кездейсоқ бір аят шығады',
      'Из $n выученных аятов — случайный аят',
      'A random ayah from the $n you memorized');

  String verseFrom(String surah, dynamic verse) => pick(
      '$surah сүресінің $verse-аяты',
      'Аят $verse суры $surah',
      'Ayah $verse of Surah $surah');

  int get translationId {
    switch (_lang) {
      case 'ru': return ruTranslationId;
      case 'en': return _enTranslationId;
      default:   return 113;
    }
  }

  String placeRu(String placeKz) {
    if (isEn) return placeKz == 'Мекке' ? 'Mecca' : 'Medina';
    return placeKz == 'Мекке' ? 'Мекка' : 'Медина';
  }

  /// Revelation place label in the current language ('Мекке' stays in Kazakh).
  String placeL10n(String placeKz) {
    switch (_lang) {
      case 'ru': return placeKz == 'Мекке' ? 'Мекка' : 'Медина';
      case 'en': return placeKz == 'Мекке' ? 'Mecca' : 'Medina';
      default:   return placeKz;
    }
  }

  String tajweedName(String key) {
    switch (_lang) {
      case 'ru': return _tajweedNamesRu[key] ?? key;
      case 'en': return _tajweedNamesEn[key] ?? key;
      default:   return _tajweedNamesKz[key] ?? key;
    }
  }

  String tajweedDescription(String key) {
    switch (_lang) {
      case 'ru': return _tajweedDescriptionsRu[key] ?? '';
      case 'en': return _tajweedDescriptionsEn[key] ?? '';
      default:   return _tajweedDescriptionsKz[key] ?? '';
    }
  }

  static const _tajweedNamesRu = {
    'ham_wasl': 'Хамзатуль-Васль', 'laam_shamsiyah': 'Лям Шамсийя',
    'slnt': 'Безмолвное чтение', 'madda_necessary': 'Мадд Лязим',
    'madda_permissible': 'Мадд Джаиз', 'madda_normal': 'Мадд Табиий',
    'ghunnah': 'Гунна', 'ikhafa': 'Ихфа', 'ikhafa_shafawi': 'Ихфа Шафавий',
    'idgham': 'Идгам', 'idgham_shafawi': 'Идгам Шафавий',
    'idgham_ghunnah': 'Идгам с Гунной', 'idgham_wo_ghunnah': 'Идгам без Гунны',
    'qalaqah': 'Калькаля', 'iqlab': 'Икляб',
  };

  static const _tajweedNamesKz = {
    'ham_wasl': 'Хамзатул-Уасл', 'laam_shamsiyah': 'Ләм Шәмсия',
    'slnt': 'Үнсіз оқу', 'madda_necessary': 'Мәдд Ләзім',
    'madda_permissible': 'Мәдд Жаиз', 'madda_normal': 'Мәдд Табиғи',
    'ghunnah': 'Ғунна', 'ikhafa': 'Ихфа', 'ikhafa_shafawi': 'Ихфа Шәфәуи',
    'idgham': 'Идғам', 'idgham_shafawi': 'Идғам Шәфәуи',
    'idgham_ghunnah': 'Идғам Ғуннамен', 'idgham_wo_ghunnah': 'Идғам Ғуннасыз',
    'qalaqah': 'Қалқала', 'iqlab': 'Иқлаб',
  };

  static const _tajweedNamesEn = {
    'ham_wasl': 'Hamzat al-Wasl', 'laam_shamsiyah': 'Laam Shamsiyyah',
    'slnt': 'Silent', 'madda_necessary': 'Madd Lazim',
    'madda_permissible': 'Madd Ja\'iz', 'madda_normal': 'Madd Tabee\'i',
    'ghunnah': 'Ghunnah', 'ikhafa': 'Ikhfa', 'ikhafa_shafawi': 'Ikhfa Shafawi',
    'idgham': 'Idgham', 'idgham_shafawi': 'Idgham Shafawi',
    'idgham_ghunnah': 'Idgham with Ghunnah', 'idgham_wo_ghunnah': 'Idgham without Ghunnah',
    'qalaqah': 'Qalqalah', 'iqlab': 'Iqlab',
  };

  static const _tajweedDescriptionsRu = {
    'ham_wasl': 'Хамзатуль-васл — хамза, которая читается только в начале речи и пропадает при соединении слов.',
    'laam_shamsiyah': 'Лям шамсия — буква "лям" в артикле "ال" не читается перед солнечными буквами и сливается со следующей буквой.',
    'slnt': 'Беззвучное чтение — буква или слово пишется, но не произносится при чтении.',
    'madda_necessary': 'Мадд лязим — обязательное длительное растяжение. Обычно читается на 6 харакатов.',
    'madda_permissible': 'Мадд джаиз — допустимое растяжение, которое можно читать с разной длиной (обычно 2–5 харакатов).',
    'madda_normal': 'Мадд табии — естественное растяжение длиной в 2 харакат.',
    'ghunnah': 'Гунна — носовой звук, возникающий при чтении букв нун и мим.',
    'ikhafa': 'Ихфа — скрытое чтение нуна сакина или танвина перед определёнными буквами.',
    'ikhafa_shafawi': 'Ихфа шафави — скрытое чтение буквы мим перед буквой "ба".',
    'idgham': 'Идгам — слияние одной буквы с другой при чтении.',
    'idgham_shafawi': 'Идгам шафави — слияние двух букв мим при встрече друг с другом.',
    'idgham_ghunnah': 'Идгам с гунной — слияние букв с носовым звучанием.',
    'idgham_wo_ghunnah': 'Идгам без гунны — слияние букв без носового звучания.',
    'qalaqah': 'Калькаля — лёгкое дрожание звука при чтении некоторых букв с сукуном.',
    'iqlab': 'Икляб — превращение нуна сакина или танвина в звук "мим" перед буквой "ба".',
  };

  static const _tajweedDescriptionsKz = {
    'ham_wasl': 'Хамзатул-Уасл — сөздің басында ғана оқылатын, жалғағанда түсіп қалатын хамза.',
    'laam_shamsiyah': 'Ләм Шәмсия — "ال" артикліндегі ләм әрпі күн әріптерінің алдында оқылмай, келесі әріпке қосылып кетеді.',
    'slnt': 'Үнсіз оқу — кейбір әріп немесе сөз жазылғанымен, дыбысталмай оқылады.',
    'madda_necessary': 'Мәдд Ләзім — міндетті түрде ұзақ созылатын мадд. Әдетте 6 харакатқа созылады.',
    'madda_permissible': 'Мәдд Жаиз — созуға да, қысқартуға да болатын мадд. Көбіне 2–5 харакат.',
    'madda_normal': 'Мәдд Табиғи — табиғи созылу. 2 харакат мөлшерінде созылады.',
    'ghunnah': 'Ғунна — мұрын арқылы шығатын дыбыс. Нун мен мим әріптерінде байқалады.',
    'ikhafa': 'Ихфа — сукунды нун мен тәнуиннен кейін кейбір әріптер келсе, дыбыс жасырынып оқылады.',
    'ikhafa_shafawi': 'Ихфа Шәфәуи — мим әрпінен кейін "бә" келсе, ерін арқылы жасырын дыбыспен оқу.',
    'idgham': 'Идғам — бір әріпті келесі әріпке қосып, бірге оқу ережесі.',
    'idgham_shafawi': 'Идғам Шәфәуи — мимнен кейін мим келсе, екеуін қосып оқу.',
    'idgham_ghunnah': 'Идғам Ғуннамен — әріптерді мұрын дыбысымен қосып оқу.',
    'idgham_wo_ghunnah': 'Идғам Ғуннасыз — әріптерді мұрын дыбысынсыз қосып оқу.',
    'qalaqah': 'Қалқала — белгілі әріптер сукун жағдайда қысқа дірілмен оқылады.',
    'iqlab': 'Иқлаб — сукунды нун мен тәнуиннен кейін "бә" келсе, мим дыбысына ауысып оқылады.',
  };

  static const _tajweedDescriptionsEn = {
    'ham_wasl': 'Hamzat al-Wasl — a hamza read only at the start of speech; it is dropped when words are joined.',
    'laam_shamsiyah': 'Laam Shamsiyyah — the laam of "ال" is not pronounced before the sun letters and merges with the following letter.',
    'slnt': 'Silent — a letter or word is written but not pronounced during recitation.',
    'madda_necessary': 'Madd Lazim — an obligatory prolonged stretch, normally recited for 6 counts.',
    'madda_permissible': 'Madd Ja\'iz — a permissible stretch of variable length (usually 2–5 counts).',
    'madda_normal': 'Madd Tabee\'i — the natural stretch of 2 counts.',
    'ghunnah': 'Ghunnah — the nasal sound produced with the letters noon and meem.',
    'ikhafa': 'Ikhfa — concealed pronunciation of noon sakinah or tanween before certain letters.',
    'ikhafa_shafawi': 'Ikhfa Shafawi — concealed pronunciation of meem before the letter "ba".',
    'idgham': 'Idgham — merging one letter into the next during recitation.',
    'idgham_shafawi': 'Idgham Shafawi — merging two meems that meet each other.',
    'idgham_ghunnah': 'Idgham with Ghunnah — merging letters with a nasal sound.',
    'idgham_wo_ghunnah': 'Idgham without Ghunnah — merging letters without a nasal sound.',
    'qalaqah': 'Qalqalah — a slight echoing bounce on certain letters bearing sukoon.',
    'iqlab': 'Iqlab — converting noon sakinah or tanween into a "meem" sound before the letter "ba".',
  };
}

/// Convenience extension so widgets can call `context.tr('key')`.
extension LangContext on BuildContext {
  /// Reactive — rebuilds when language changes.
  LanguageProvider get lp => Provider.of<LanguageProvider>(this);

  /// Non-reactive — safe to call inside callbacks.
  String tr(String key) =>
      Provider.of<LanguageProvider>(this, listen: false).tr(key);
}
