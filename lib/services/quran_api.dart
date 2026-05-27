import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/transliteration.dart';

// ── In-memory caches ──────────────────────────────────────────────────────────
final Map<int, String> _surahCache = {};
// Keys are '$translationId:$chapter|page|juz' to support multiple languages
final Map<String, List<Map<String, dynamic>>> _surahAyahsCache = {};
final Map<String, List<Map<String, dynamic>>> _pageAyahsCache = {};
final Map<String, List<Map<String, dynamic>>> _juzAyahsCache = {};

const _kzTranslationId = 113; // Kazakh offline translation ID
const ruTranslationId  = 45;  // Russian translation ID (quran.com)

// ── Offline asset data ────────────────────────────────────────────────────────
Map<String, Map<String, dynamic>>? _offlineAyahs;
Map<String, String>? _offlineSurahs;

Future<void> initQuranOfflineData() async {
  if (_offlineAyahs != null) return;
  try {
    final raw = await rootBundle.loadString('assets/quran_data.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _offlineSurahs = (data['surahs'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));
    _offlineAyahs = (data['ayahs'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v as Map<String, dynamic>));
    for (final e in _offlineSurahs!.entries) {
      final n = int.tryParse(e.key);
      if (n != null) _surahCache[n] = e.value;
    }
  } catch (_) {
    _offlineAyahs = {};
    _offlineSurahs = {};
  }
}

String _defaultAudioUrl(int chapter, int verse) =>
    'https://audio.qurancdn.com/AbdurRahmanAsSubayyal/mp3/'
    '${chapter.toString().padLeft(3, '0')}'
    '${verse.toString().padLeft(3, '0')}.mp3';

String? getAyahArabic(int chapter, int verse) =>
    _offlineAyahs?['$chapter:$verse']?['arabic'] as String?;

void clearAyahCache() {
  _surahAyahsCache.clear();
  _pageAyahsCache.clear();
  _juzAyahsCache.clear();
}


const tajweedNamesRu = {
  'ham_wasl':          'Хамзатуль-Васль',
  'laam_shamsiyah':    'Лям Шамсийя',
  'slnt':              'Безмолвное чтение',
  'madda_necessary':   'Мадд Лязим',
  'madda_permissible': 'Мадд Джаиз',
  'madda_normal':      'Мадд Табиий',
  'ghunnah':           'Гунна',
  'ikhafa':            'Ихфа',
  'ikhafa_shafawi':    'Ихфа Шафавий',
  'idgham':            'Идгам',
  'idgham_shafawi':    'Идгам Шафавий',
  'idgham_ghunnah':    'Идгам с Гунной',
  'idgham_wo_ghunnah': 'Идгам без Гунны',
  'qalaqah':           'Калькаля',
  'iqlab':             'Икляб',
};

const tajweedDescriptionsRu = {
  'ham_wasl':
      'Хамзатуль-васл — хамза, которая читается только в начале речи и пропадает при соединении слов.',
  'laam_shamsiyah':
      'Лям шамсия — буква "лям" в артикле "ال" не читается перед солнечными буквами и сливается со следующей буквой.',
  'slnt':
      'Беззвучное чтение — буква или слово пишется, но не произносится при чтении.',
  'madda_necessary':
      'Мадд лязим — обязательное длительное растяжение. Обычно читается на 6 харакатов.',
  'madda_permissible':
      'Мадд джаиз — допустимое растяжение, которое можно читать с разной длиной (обычно 2–5 харакатов).',
  'madda_normal':
      'Мадд табии — естественное растяжение длиной в 2 харакат.',
  'ghunnah':
      'Гунна — носовой звук, возникающий при чтении букв нун и мим.',
  'ikhafa':
      'Ихфа — скрытое чтение нуна сакина или танвина перед определёнными буквами.',
  'ikhafa_shafawi':
      'Ихфа шафави — скрытое чтение буквы мим перед буквой "ба".',
  'idgham':
      'Идгам — слияние одной буквы с другой при чтении.',
  'idgham_shafawi':
      'Идгам шафави — слияние двух букв мим при встрече друг с другом.',
  'idgham_ghunnah':
      'Идгам с гунной — слияние букв с носовым звучанием.',
  'idgham_wo_ghunnah':
      'Идгам без гунны — слияние букв без носового звучания.',
  'qalaqah':
      'Калькаля — лёгкое дрожание звука при чтении некоторых букв с сукуном.',
  'iqlab':
      'Икляб — превращение нуна сакина или танвина в звук "мим" перед буквой "ба".',
};

const tajweedNamesKz = {
  'ham_wasl':          'Хамзатул-Уасл',
  'laam_shamsiyah':    'Ләм Шәмсия',
  'slnt':              'Үнсіз оқу',
  'madda_necessary':   'Мәдд Ләзім',
  'madda_permissible': 'Мәдд Жаиз',
  'madda_normal':      'Мәдд Табиғи',
  'ghunnah':           'Ғунна',
  'ikhafa':            'Ихфа',
  'ikhafa_shafawi':    'Ихфа Шәфәуи',
  'idgham':            'Идғам',
  'idgham_shafawi':    'Идғам Шәфәуи',
  'idgham_ghunnah':    'Идғам Ғуннамен',
  'idgham_wo_ghunnah': 'Идғам Ғуннасыз',
  'qalaqah':           'Қалқала',
  'iqlab':             'Иқлаб',
};

const tajweedDescriptionsKz = {
  'ham_wasl':
      'Хамзатул-Уасл — сөздің басында ғана оқылатын, жалғағанда түсіп қалатын хамза.',
  'laam_shamsiyah':
      'Ләм Шәмсия — "ال" артикліндегі ләм әрпі күн әріптерінің алдында оқылмай, келесі әріпке қосылып кетеді.',
  'slnt':
      'Үнсіз оқу — кейбір әріп немесе сөз жазылғанымен, дыбысталмай оқылады.',
  'madda_necessary':
      'Мәдд Ләзім — міндетті түрде ұзақ созылатын мадд. Әдетте 6 харакатқа созылады.',
  'madda_permissible':
      'Мәдд Жаиз — созуға да, қысқартуға да болатын мадд. Көбіне 2–5 харакат.',
  'madda_normal':
      'Мәдд Табиғи — табиғи созылу. 2 харакат мөлшерінде созылады.',
  'ghunnah':
      'Ғунна — мұрын арқылы шығатын дыбыс. Нун мен мим әріптерінде байқалады.',
  'ikhafa':
      'Ихфа — сукунды нун мен тәнуиннен кейін кейбір әріптер келсе, дыбыс жасырынып оқылады.',
  'ikhafa_shafawi':
      'Ихфа Шәфәуи — мим әрпінен кейін "бә" келсе, ерін арқылы жасырын дыбыспен оқу.',
  'idgham':
      'Идғам — бір әріпті келесі әріпке қосып, бірге оқу ережесі.',
  'idgham_shafawi':
      'Идғам Шәфәуи — мимнен кейін мим келсе, екеуін қосып оқу.',
  'idgham_ghunnah':
      'Идғам Ғуннамен — әріптерді мұрын дыбысымен қосып оқу.',
  'idgham_wo_ghunnah':
      'Идғам Ғуннасыз — әріптерді мұрын дыбысынсыз қосып оқу.',
  'qalaqah':
      'Қалқала — белгілі әріптер сукун жағдайда қысқа дірілмен оқылады.',
  'iqlab':
      'Иқлаб — сукунды нун мен тәнуиннен кейін "бә" келсе, мим дыбысына ауысып оқылады.',
};

List<Map<String, String>> parseTajweedParts(String html) {
  const colors = {
    'ham_wasl':          '#AAAAAA',
    'laam_shamsiyah':    '#AAAAAA',
    'slnt':              '#AAAAAA',
    'madda_necessary':   '#CC4817',
    'madda_permissible': '#CA8831',
    'madda_normal':      '#537FCA',
    'ghunnah':           '#42A44B',
    'ikhafa':            '#9B59B6',
    'ikhafa_shafawi':    '#9B59B6',
    'idgham':            '#27AE60',
    'idgham_shafawi':    '#27AE60',
    'idgham_ghunnah':    '#27AE60',
    'idgham_wo_ghunnah': '#209d6e',
    'qalaqah':           '#D4AC0D',
    'iqlab':             '#E74C3C',
  };

  final result = <Map<String, String>>[];
  final cleaned = html.replaceAll(RegExp(r'<span[^>]*>.*?</span>'), '');
  final regex = RegExp(r'<tajweed class=([a-z_]+)>([\s\S]*?)<\/tajweed>|([^<]+)');

  for (final match in regex.allMatches(cleaned)) {
    if (match.group(1) != null && match.group(2) != null) {
      result.add({
        'text': match.group(2)!,
        'color': colors[match.group(1)] ?? '#000000',
      });
    } else if (match.group(3) != null && match.group(3)!.isNotEmpty) {
      result.add({'text': match.group(3)!, 'color': '#000000'});
    }
  }
  return result;
}

Future<Map<String, dynamic>?> fetchAyah(
    int chapter, int verse, int translationId,
    {bool fetchTajweed = true}) async {
  // ── Offline path (Kazakh only) ────────────────────────────────────────────
  final offline = translationId == _kzTranslationId
      ? (_offlineAyahs?['$chapter:$verse'])
      : null;
  if (offline != null) {
    final tajweed = fetchTajweed
        ? offline['tajweed']?.toString() ?? ''
        : '';
    final surahName = _surahCache[chapter] ?? 'Сура $chapter';
    return {
      'arabic':          offline['arabic']?.toString() ?? '',
      'tajweed':         tajweed,
      'translation':     offline['translation']?.toString() ?? '',
      'transliteration': latinToCyrillic(offline['transliteration']?.toString() ?? ''),
      'audio':           _defaultAudioUrl(chapter, verse),
      'surah':           surahName,
      'chapter':         chapter,
      'verse':           verse,
    };
  }

  // ── Network fallback ──────────────────────────────────────────────────────
  try {
    final quranComUrl = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_key/$chapter:$verse'
      '?translations=$translationId'
      '&fields=text_uthmani,text_uthmani_tajweed,chapter_id'
      '&audio=1',
    );
    final translitUrl = Uri.parse(
      'https://api.alquran.cloud/v1/ayah/$chapter:$verse/en.transliteration',
    );

    final responses = await Future.wait([
      http.get(quranComUrl),
      http.get(translitUrl),
    ]);
    final response = responses[0];
    final translitResponse = responses[1];

    String translitText = '';
    if (translitResponse.statusCode == 200) {
      final td = jsonDecode(translitResponse.body);
      translitText = td['data']?['text']?.toString() ?? '';
    }

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final verseData = data['verse'];
    if (verseData == null) return null;

    final translationsList = verseData['translations'] as List?;
    dynamic translationObj;
    if (translationsList != null && translationsList.isNotEmpty) {
      translationObj = translationsList.firstWhere(
        (t) => t['resource_id'] == translationId || t['id'] == translationId,
        orElse: () => translationsList.first,
      );
    }

    String surahName = _surahCache[chapter] ?? '';
    if (surahName.isEmpty) {
      final surahRes = await http.get(
        Uri.parse('https://api.quran.com/api/v4/chapters/$chapter'),
      );
      if (surahRes.statusCode == 200) {
        final surahData = jsonDecode(surahRes.body);
        surahName = surahData['chapter']?['name_simple'] ?? 'Сура $chapter';
        _surahCache[chapter] = surahName;
      } else {
        surahName = 'Сура $chapter';
      }
    }

    final audioField = verseData['audio'];
    String audioPrimary = '';
    if (audioField is Map) {
      audioPrimary = audioField['url']?.toString() ??
          audioField['primary']?.toString() ??
          '';
    } else if (audioField is String) {
      audioPrimary = audioField;
    }
    final audioUrl = audioPrimary.isEmpty
        ? _defaultAudioUrl(chapter, verse)
        : audioPrimary.startsWith('http')
            ? audioPrimary
            : 'https://audio.qurancdn.com/$audioPrimary';

    return {
      'arabic':          verseData['text_uthmani']?.toString() ?? '',
      'tajweed':         verseData['text_uthmani_tajweed']?.toString() ?? '',
      'translation':     translationObj?['text']?.toString() ?? '',
      'transliteration': latinToCyrillic(translitText),
      'audio':           audioUrl,
      'surah':           surahName,
      'chapter':         chapter,
      'verse':           verse,
    };
  } catch (e) {
    print('Ошибка fetchAyah: $e'); // ignore: avoid_print
    return null;
  }
}

Future<List<Map<String, dynamic>>?> fetchSurahAyahsFull(
    int chapter, int translationId) async {
  final cacheKey = '$translationId:$chapter';
  if (_surahAyahsCache.containsKey(cacheKey)) {
    return _surahAyahsCache[cacheKey];
  }

  // ── Offline path (Kazakh only) ────────────────────────────────────────────
  final offlineAll = _offlineAyahs;
  if (translationId == _kzTranslationId &&
      offlineAll != null &&
      offlineAll.isNotEmpty) {
    final surahName = _surahCache[chapter] ?? 'Сура $chapter';
    final entries = offlineAll.entries
        .where((e) => e.key.startsWith('$chapter:'))
        .toList()
      ..sort((a, b) {
        final av = int.tryParse(a.key.split(':')[1]) ?? 0;
        final bv = int.tryParse(b.key.split(':')[1]) ?? 0;
        return av.compareTo(bv);
      });

    if (entries.isNotEmpty) {
      final result = entries.map<Map<String, dynamic>>((e) {
        final v = int.tryParse(e.key.split(':')[1]) ?? 0;
        final off = e.value;
        return {
          'arabic':          off['arabic']?.toString() ?? '',
          'tajweed':         off['tajweed']?.toString() ?? '',
          'translation':     off['translation']?.toString() ?? '',
          'transliteration': latinToCyrillic(off['transliteration']?.toString() ?? ''),
          'audio':           '',
          'surah':           surahName,
          'chapter':         chapter,
          'verse':           v,
        };
      }).toList();
      _surahAyahsCache[cacheKey] = result;
      return result;
    }
  }

  // ── Network fallback ──────────────────────────────────────────────────────
  try {
    String surahName = _surahCache[chapter] ?? '';
    if (surahName.isEmpty) {
      final r = await http.get(
          Uri.parse('https://api.quran.com/api/v4/chapters/$chapter'));
      if (r.statusCode == 200) {
        surahName = jsonDecode(r.body)['chapter']?['name_simple'] ??
            'Сура $chapter';
        _surahCache[chapter] = surahName;
      }
    }

    final quranComUrl = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_chapter/$chapter'
      '?translations=$translationId'
      '&fields=text_uthmani,text_uthmani_tajweed'
      '&per_page=300&page=1',
    );
    final translitUrl = Uri.parse(
      'https://api.alquran.cloud/v1/surah/$chapter/en.transliteration',
    );
    final responses = await Future.wait([
      http.get(quranComUrl),
      http.get(translitUrl),
    ]);
    final response = responses[0];
    if (response.statusCode != 200) return null;

    final Map<int, String> translitMap = {};
    if (responses[1].statusCode == 200) {
      final td = jsonDecode(responses[1].body);
      final ayahs = td['data']?['ayahs'] as List?;
      for (final a in ayahs ?? []) {
        final n = (a['numberInSurah'] as num?)?.toInt();
        if (n != null) translitMap[n] = a['text']?.toString() ?? '';
      }
    }

    final data = jsonDecode(response.body);
    final verses = data['verses'] as List?;
    if (verses == null) return null;

    final result = verses.map<Map<String, dynamic>>((v) {
      final vNum = (v['verse_number'] as num?)?.toInt() ?? 0;
      final translations = v['translations'] as List?;
      final tr =
          translations?.isNotEmpty == true ? translations!.first : null;
      return {
        'arabic': v['text_uthmani']?.toString() ?? '',
        'tajweed': v['text_uthmani_tajweed']?.toString() ?? '',
        'translation': tr?['text']?.toString() ?? '',
        'transliteration': latinToCyrillic(translitMap[vNum] ?? ''),
        'audio': '',
        'surah': surahName,
        'chapter': chapter,
        'verse': (v['verse_number'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    _surahAyahsCache[cacheKey] = result;
    return result;
  } catch (e) {
    print('Ошибка fetchSurahAyahsFull: $e'); // ignore: avoid_print
    return null;
  }
}

/// Returns the Medina mushaf page number (1–604) for a given chapter:verse.
Future<int?> fetchVersePageNumber(int chapter, int verse) async {
  // ── Offline path ──────────────────────────────────────────────────────────
  final offline = _offlineAyahs?['$chapter:$verse'];
  if (offline != null) {
    return (offline['page'] as num?)?.toInt();
  }

  // ── Network fallback ──────────────────────────────────────────────────────
  try {
    final url = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_key/$chapter:$verse'
      '?fields=page_number',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return (data['verse']?['page_number'] as num?)?.toInt();
  } catch (_) {
    return null;
  }
}

/// Fetches all verses in a Juz / Para (1–30).
Future<List<Map<String, dynamic>>?> fetchVersesByJuz(
    int juzNumber, int translationId) async {
  final cacheKey = '$translationId:$juzNumber';
  if (_juzAyahsCache.containsKey(cacheKey)) {
    return _juzAyahsCache[cacheKey];
  }

  // ── Offline path (Kazakh only) ────────────────────────────────────────────
  final offlineAll = _offlineAyahs;
  if (translationId == _kzTranslationId &&
      offlineAll != null &&
      offlineAll.isNotEmpty) {
    final entries = offlineAll.entries
        .where((e) => (e.value['juz'] as num?)?.toInt() == juzNumber)
        .toList()
      ..sort((a, b) {
        final aParts = a.key.split(':');
        final bParts = b.key.split(':');
        final aCh = int.tryParse(aParts[0]) ?? 0;
        final bCh = int.tryParse(bParts[0]) ?? 0;
        if (aCh != bCh) return aCh.compareTo(bCh);
        final aV = int.tryParse(aParts[1]) ?? 0;
        final bV = int.tryParse(bParts[1]) ?? 0;
        return aV.compareTo(bV);
      });

    if (entries.isNotEmpty) {
      final result = entries.map<Map<String, dynamic>>((e) {
        final parts = e.key.split(':');
        final ch = int.tryParse(parts[0]) ?? 1;
        final v = int.tryParse(parts[1]) ?? 1;
        final off = e.value;
        return {
          'arabic':          off['arabic']?.toString() ?? '',
          'tajweed':         off['tajweed']?.toString() ?? '',
          'translation':     off['translation']?.toString() ?? '',
          'transliteration': latinToCyrillic(off['transliteration']?.toString() ?? ''),
          'audio':           '',
          'surah':           _surahCache[ch] ?? '',
          'chapter':         ch,
          'verse':           v,
        };
      }).toList();
      _juzAyahsCache[cacheKey] = result;
      return result;
    }
  }

  // ── Network fallback ──────────────────────────────────────────────────────
  try {
    final quranComUrl = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_juz/$juzNumber'
      '?translations=$translationId'
      '&fields=text_uthmani,text_uthmani_tajweed'
      '&per_page=300&page=1',
    );
    final translitUrl = Uri.parse(
      'https://api.alquran.cloud/v1/juz/$juzNumber/en.transliteration',
    );
    final responses = await Future.wait([
      http.get(quranComUrl),
      http.get(translitUrl),
    ]);
    final response = responses[0];
    if (response.statusCode != 200) return null;

    final Map<String, String> translitMap = {};
    if (responses[1].statusCode == 200) {
      final td = jsonDecode(responses[1].body);
      final ayahs = td['data']?['ayahs'] as List?;
      for (final a in ayahs ?? []) {
        final ch = (a['surah']?['number'] as num?)?.toInt();
        final vn = (a['numberInSurah'] as num?)?.toInt();
        if (ch != null && vn != null) {
          translitMap['$ch:$vn'] = a['text']?.toString() ?? '';
        }
      }
    }

    final data = jsonDecode(response.body);
    final verses = data['verses'] as List?;
    if (verses == null) return null;

    final result = verses.map<Map<String, dynamic>>((v) {
      final key = v['verse_key']?.toString() ?? '1:1';
      final parts = key.split(':');
      final chNum = int.tryParse(parts[0]) ?? 1;
      final vNum = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;

      final translations = v['translations'] as List?;
      final tr = translations?.isNotEmpty == true ? translations!.first : null;

      return {
        'arabic': v['text_uthmani']?.toString() ?? '',
        'tajweed': v['text_uthmani_tajweed']?.toString() ?? '',
        'translation': tr?['text']?.toString() ?? '',
        'transliteration': latinToCyrillic(translitMap['$chNum:$vNum'] ?? ''),
        'audio': '',
        'surah': '',
        'chapter': chNum,
        'verse': vNum,
      };
    }).toList();

    _juzAyahsCache[cacheKey] = result;
    return result;
  } catch (e) {
    print('Ошибка fetchVersesByJuz: $e'); // ignore: avoid_print
    return null;
  }
}

/// Fetches all verses on a Medina mushaf page (1–604).
Future<List<Map<String, dynamic>>?> fetchVersesByPage(
    int pageNumber, int translationId) async {
  final cacheKey = '$translationId:$pageNumber';
  if (_pageAyahsCache.containsKey(cacheKey)) {
    return _pageAyahsCache[cacheKey];
  }

  // ── Offline path (Kazakh only) ────────────────────────────────────────────
  final offlineAll = _offlineAyahs;
  if (translationId == _kzTranslationId &&
      offlineAll != null &&
      offlineAll.isNotEmpty) {
    final entries = offlineAll.entries
        .where((e) => (e.value['page'] as num?)?.toInt() == pageNumber)
        .toList()
      ..sort((a, b) {
        final aParts = a.key.split(':');
        final bParts = b.key.split(':');
        final aCh = int.tryParse(aParts[0]) ?? 0;
        final bCh = int.tryParse(bParts[0]) ?? 0;
        if (aCh != bCh) return aCh.compareTo(bCh);
        final aV = int.tryParse(aParts[1]) ?? 0;
        final bV = int.tryParse(bParts[1]) ?? 0;
        return aV.compareTo(bV);
      });

    if (entries.isNotEmpty) {
      final result = entries.map<Map<String, dynamic>>((e) {
        final parts = e.key.split(':');
        final ch = int.tryParse(parts[0]) ?? 1;
        final v = int.tryParse(parts[1]) ?? 1;
        final off = e.value;
        return {
          'arabic':          off['arabic']?.toString() ?? '',
          'tajweed':         off['tajweed']?.toString() ?? '',
          'translation':     off['translation']?.toString() ?? '',
          'transliteration': latinToCyrillic(off['transliteration']?.toString() ?? ''),
          'audio':           '',
          'surah':           _surahCache[ch] ?? '',
          'chapter':         ch,
          'verse':           v,
        };
      }).toList();
      _pageAyahsCache[cacheKey] = result;
      return result;
    }
  }

  // ── Network fallback ──────────────────────────────────────────────────────
  try {
    final quranComUrl = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_page/$pageNumber'
      '?translations=$translationId'
      '&fields=text_uthmani,text_uthmani_tajweed'
      '&per_page=50',
    );
    final translitUrl = Uri.parse(
      'https://api.alquran.cloud/v1/page/$pageNumber/en.transliteration',
    );
    final responses = await Future.wait([
      http.get(quranComUrl),
      http.get(translitUrl),
    ]);
    final response = responses[0];
    if (response.statusCode != 200) return null;

    final Map<String, String> translitMap = {};
    if (responses[1].statusCode == 200) {
      final td = jsonDecode(responses[1].body);
      final ayahs = td['data']?['ayahs'] as List?;
      for (final a in ayahs ?? []) {
        final ch = (a['surah']?['number'] as num?)?.toInt();
        final vn = (a['numberInSurah'] as num?)?.toInt();
        if (ch != null && vn != null) {
          translitMap['$ch:$vn'] = a['text']?.toString() ?? '';
        }
      }
    }

    final data = jsonDecode(response.body);
    final verses = data['verses'] as List?;
    if (verses == null) return null;

    final result = verses.map<Map<String, dynamic>>((v) {
      final key = v['verse_key']?.toString() ?? '1:1';
      final parts = key.split(':');
      final chNum = int.tryParse(parts[0]) ?? 1;
      final vNum = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;

      final translations = v['translations'] as List?;
      final tr = translations?.isNotEmpty == true ? translations!.first : null;

      return {
        'arabic': v['text_uthmani']?.toString() ?? '',
        'tajweed': v['text_uthmani_tajweed']?.toString() ?? '',
        'translation': tr?['text']?.toString() ?? '',
        'transliteration': latinToCyrillic(translitMap['$chNum:$vNum'] ?? ''),
        'audio': '',
        'surah': '',
        'chapter': chNum,
        'verse': vNum,
      };
    }).toList();

    _pageAyahsCache[cacheKey] = result;
    return result;
  } catch (e) {
    print('Ошибка fetchVersesByPage: $e'); // ignore: avoid_print
    return null;
  }
}
