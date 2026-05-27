import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../services/quran_api.dart' show ruTranslationId;

class LanguageProvider extends ChangeNotifier {
  String _lang = 'kz';

  String get lang => _lang;
  bool get isRu => _lang == 'ru';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('appLang') ?? 'kz';
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

  // ── Dynamic strings ───────────────────────────────────────────────────────

  String daysAgo(int n) =>
      isRu ? '$n дн. назад' : '$n күн бұрын';

  String weeksAgo(int n) =>
      isRu ? '$n апт. назад' : '$n апта бұрын';

  String monthsAgo(int n) =>
      isRu ? '$n ай бұрын' : '$n ай бұрын';

  String juzProgress(int assigned) =>
      isRu ? '$assigned/30 джузов' : '$assigned/30 жүз';

  String myJuzLabel(int juz) =>
      isRu ? '$juz-джуз' : '$juz-жүз';

  String khatamCount(int n) =>
      isRu ? 'Хатм: $n' : 'Хатым: $n';

  String assignedJuz(int assigned, int total) =>
      isRu ? '$assigned/$total джузов' : '$assigned/$total жүз';

  String completedJuz(int n) =>
      isRu ? '$n завершено ✓' : '$n бітті ✓';

  String surahFullMemorized(String name, int total) => isRu
      ? '$name сурасы\n$total аят толық жаттадыңыз! 🤲'
      : '$name сүресін\n$total аятты толық жаттадыңыз! 🤲';

  String streakDays(int n) =>
      isRu ? '$n дней' : '$n күн';

  String learnedAyahs(int n) =>
      isRu ? '$n аят' : '$n аят';

  String memorizeProgress(double pct) => isRu
      ? 'Прогресс запоминания: ${pct.toStringAsFixed(0)}%'
      : 'Жаттау прогресі: ${pct.toStringAsFixed(0)}%';

  String deleteGroupConfirm(String name) => isRu
      ? '"$name" группасын толықтай жойасыз ба? Бұл әрекетті қайтару мүмкін емес.'
      : '"$name" тобын толығымен жойасыз ба? Бұл әрекетті қайтару мүмкін емес.';

  String leaveGroupConfirm(String name) =>
      isRu ? '"$name" тобынан шығасыз ба?' : '"$name" топтан шығарасыз ба?';

  String removeMemberConfirm(String name) =>
      isRu ? '"$name" мүшесін шығарасыз ба?' : '"$name" шығарасыз ба?';

  String removeFriendConfirm(String name) =>
      isRu ? '"$name" достар тізімінен шығарасыз ба?'
           : '"$name" достар тізімінен шығарасыз ба?';

  String juzSelectedLabel(int juz) =>
      isRu ? '$juz-джуз таңдалды' : '$juz-жүз таңдалды';

  String unmarkJuzConfirm(int juz) =>
      isRu ? '$juz-джуз белгісін қайтарасыз ба?' : '$juz-жүз белгісін қайтарасыз ба?';

  String surahMemorizedSuffix(int total) =>
      isRu ? '\n$total аятов полностью запомнили! 🤲'
           : '\n$total аятты толық жаттадыңыз! 🤲';

  String multiAyahHeader(String unit, int num, int count, String surahName) {
    if (isRu) {
      switch (unit) {
        case 'page': return '$num-стр.  •  $count аят';
        case 'juz':  return '$num-джуз  •  $count аят';
        default:     return '$surahName  •  $count аят';
      }
    }
    switch (unit) {
      case 'page': return '$num-бет  •  $count аят';
      case 'juz':  return '$num-жүз  •  $count аят';
      default:     return '$surahName  •  $count аят';
    }
  }

  String readUnitSwipeHint(String unit) {
    if (isRu) {
      switch (unit) {
        case 'surah': return 'Сура';
        case 'juz':   return 'Джуз';
        default:      return 'Стр.';
      }
    }
    switch (unit) {
      case 'surah': return 'Сүре';
      case 'juz':   return 'Жүз';
      default:      return 'Бет';
    }
  }

  String sajdaInlineText() =>
      isRu ? 'سَجْدَةٌ  •  Сажда тиляват — совершите сажда'
           : 'سَجْدَةٌ  •  Тіләуат сәждесі — сәжде жасаңыз';

  String selectedSurahsCount(int n) =>
      isRu ? 'Выбрано: $n сур' : 'Таңдалды: $n сүре';

  String selectedCount(int n) =>
      isRu ? 'Выбрано: $n' : 'Таңдалды: $n';

  String streakLabel(int days) =>
      isRu ? '🔥  $days дней подряд' : '🔥  $days күн қатарынан';

  String genderAgeLine(String gender, String age) {
    final gLabel = isRu
        ? (gender == 'male' ? 'Мужчина' : 'Женщина')
        : (gender == 'male' ? 'Ер азамат' : 'Әйел');
    final agePart = isRu ? '$age лет' : '$age жас';
    return '$gLabel  •  $agePart';
  }

  String totalReadFmt(int n) =>
      isRu ? 'Всего: $n раз' : 'Барлығы: $n рет';

  String remainingAyahs(int n) =>
      isRu ? 'Осталось: $n аят' : 'Қалды: $n аят';

  String friendAddedMsg(String name) =>
      isRu ? '$name добавлен в друзья!' : '$name достар тізіміне қосылды!';

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

  List<String> get weekdays => isRu
      ? ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
      : ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жк'];

  List<String> get months => isRu
      ? ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
         'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь']
      : ['Қаңтар', 'Ақпан', 'Наурыз', 'Сәуір', 'Мамыр', 'Маусым',
         'Шілде', 'Тамыз', 'Қыркүйек', 'Қазан', 'Қараша', 'Желтоқсан'];

  String khatamLabel2(int n) =>
      isRu ? 'Хатм: $n' : 'Хатым: $n';

  String juzAssignedLabel(int assigned) =>
      isRu ? '$assigned/30 джузов' : '$assigned/30 жүз';

  String memorizeProgressLabel(double pct) =>
      isRu ? 'Прогресс запоминания: ${pct.toStringAsFixed(0)}%'
           : 'Жаттау прогресі: ${pct.toStringAsFixed(0)}%';

  String goalNotifTitle(bool isLearn) => isRu
      ? 'Dudi — ${isLearn ? 'Выучить' : 'Чтение'}'
      : 'Dudi — ${isLearn ? 'Жаттау' : 'Оқу'} мақсаты';

  String goalNotifBody(bool isLearn, String deadlineLabel) => isRu
      ? '${isLearn ? 'Цель запоминания' : 'Цель чтения'}! 📖 $deadlineLabel'
      : '${isLearn ? 'Жаттау' : 'Оқу'} мақсатыңды ұмытпа! 📖 $deadlineLabel';

  String pagesPerDayFmt(int n) =>
      isRu ? '$n стр. / день' : '$n бет / күн';

  String pagesFmt(int n) =>
      isRu ? '$n стр.' : '$n бет';

  String knownSurahsLabel(int n) =>
      isRu ? 'Известных сур: $n' : 'Білетін сүрелер: $n';

  String resetKhatamsConfirm(String groupName) => isRu
      ? 'Сбросить хатмы в группе "$groupName"?'
      : '"$groupName" тобындағы хатымдар санын тастаймыз ба?';

  String addedYouMsg(String name) =>
      isRu ? '$name добавил вас в друзья! 🤝' : '$name сізді достар тізіміне қосты! 🤝';

  String khatamGroupMsg(int number) => isRu
      ? 'Группа прочитала Коран $number-й раз!\n\nДуа хатма — сунна. Это закрепляет саваб прочитанного Корана.'
      : 'Топ $number-ші рет Құранды толық хатым жасады!\n\nХатым дұғасын оқу — сүннет. Ол оқылған Құранның сауабын бекітеді.';

  String khatamGroupSimple(int number) => isRu
      ? 'Группа прочитала Коран $number-й раз!\nМожно выбрать новые джузы.'
      : 'Топ $number-ші рет Құранды хатым жасады!\nЖаңа жүздерді таңдауға болады.';

  String khatamHistoryTitle(int n) =>
      isRu ? 'История хатмов ($n)' : 'Хатым тарихы ($n)';

  String khatamNumber(int n) => isRu ? '$n-й хатм' : '$n-хатым';

  String membersTitle(int n) =>
      isRu ? 'Участники ($n)' : 'Мүшелер ($n)';

  String juzDone(int juz) => isRu ? '$juz-джуз ✓' : '$juz-жүз ✓';

  String juzInProgress(int juz) =>
      isRu ? '$juz-джуз читается' : '$juz-жүз оқуда';

  String codeCopied(String code) =>
      isRu ? 'Код скопирован: $code' : 'Код көшірілді: $code';

  String inviteCodeLabel(String code) =>
      isRu ? 'Код приглашения: $code' : 'Шақыру коды: $code';

  String myJuzBanner(int juz) =>
      isRu ? 'Ваш джуз: $juz-джуз' : 'Сіздің жүзіңіз: $juz-жүз';

  String get duaTranslation => isRu
      ? 'О, Аллах!\n'
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
        'Амин.'
      : 'Уа, Алла!\n'
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

  String sleepRemainingLabel(String timeStr) =>
      isRu ? 'Осталось: $timeStr' : 'Қалды: $timeStr';

  String surahWarnTitle(bool isLearned) => isRu
      ? (isLearned ? 'Вы выучили эту суру' : 'Вы знаете эту суру')
      : (isLearned ? 'Бұл сүрені жаттадыңыз' : 'Бұл сүрені білесіз');

  String surahWarnBody(String name, bool isLearned) {
    final verb = isLearned
        ? (isRu ? 'выучили' : 'жаттадыңыз')
        : (isRu ? 'знаете' : 'білесіз');
    return isRu
        ? 'Вы $verb суру «$name».\nВсё равно добавить в список для изучения?'
        : '«$name» сүресін $verb.\nДегенмен жаттау тізіміне қосасыз ба?';
  }

  String selectedFraction(int n, int total) =>
      isRu ? 'Выбрано: $n / $total' : 'Таңдалды: $n / $total';

  String surahsFmt(int n) => isRu ? '$n сур' : '$n сүре';

  String saveSurahsBtn(int n) =>
      isRu ? 'Сохранить ($n сур)' : 'Сақтау  ($n сүре)';

  String shareCodeMsg(String code) => isRu
      ? 'Qari — мой код друга: $code\n'
        'Скачай Qari, зайди в «Друзья» и введи код! 📖'
      : 'Qari — менің дос кодым: $code\n'
        'Qari қосымшасын жүктеп, Достар бөліміне кіріп, кодты енгізіңіз! 📖';

  String greetingMsg(String name) {
    final hi = name.isEmpty
        ? (isRu ? 'Ассаляму алейкум!' : 'Ассаламу алейкум!')
        : (isRu ? 'Ассаляму алейкум, $name!' : 'Ассаламу алейкум, $name!');
    final body = isRu
        ? 'Я Dudi — ваш Коранный помощник. Задайте вопрос, попросите мотивацию или начните квиз!'
        : 'Мен Dudi — сіздің Құран жолдасыңыз. Сұрақ қойыңыз, мотивация сұраңыз немесе квизді бастаңыз!';
    return '$hi $body';
  }

  String noLearnedAyahs() => isRu
      ? 'Сначала выучи аяты! В режиме запоминания нажмите "Запомнил!".'
      : 'Алдымен аяттарды жатта! Жаттау режимінде "Жаттадым!" басыңыз.';

  String kqSubtitle(int n) => isRu
      ? '$n вопросов · Выберите правильный ответ'
      : '$n сұрақ · Дұрыс жауапты таңда';

  String streakTitle(int n) =>
      isRu ? '$n дней подряд' : '$n күн қатарынан';

  String learnedAyahsDesc(int n) => isRu
      ? 'Из $n выученных аятов — случайный аят'
      : 'Жатталған $n аяттан кездейсоқ бір аят шығады';

  String verseFrom(String surah, dynamic verse) => isRu
      ? 'Аят $verse суры $surah'
      : '$surah сүресінің $verse-аяты';

  int get translationId => isRu ? ruTranslationId : 113;

  String placeRu(String placeKz) =>
      placeKz == 'Мекке' ? 'Мекка' : 'Медина';

  String tajweedName(String key) {
    if (isRu) return _tajweedNamesRu[key] ?? key;
    return _tajweedNamesKz[key] ?? key;
  }

  String tajweedDescription(String key) {
    if (isRu) return _tajweedDescriptionsRu[key] ?? '';
    return _tajweedDescriptionsKz[key] ?? '';
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
}

/// Convenience extension so widgets can call `context.tr('key')`.
extension LangContext on BuildContext {
  /// Reactive — rebuilds when language changes.
  LanguageProvider get lp => Provider.of<LanguageProvider>(this);

  /// Non-reactive — safe to call inside callbacks.
  String tr(String key) =>
      Provider.of<LanguageProvider>(this, listen: false).tr(key);
}
