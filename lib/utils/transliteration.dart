/// Converts quran.com Latin transliteration to Kazakh Cyrillic phonetics.
/// Handles ALA-LC Arabic romanization characters (macrons, dots, ʿ/ʾ, digraphs).
String latinToCyrillic(String input) {
  if (input.isEmpty) return input;

  final sb = StringBuffer();
  final src = input;
  final lower = input.toLowerCase();
  int i = 0;

  while (i < src.length) {
    // ── 2-character digraphs (check before single chars) ────────────────
    if (i + 1 < src.length) {
      final two = lower.substring(i, i + 2);
      final cy = _two[two];
      if (cy != null) {
        sb.write(_matchCase(cy, src[i]));
        i += 2;
        continue;
      }
    }

    // ── Single character ────────────────────────────────────────────────
    final c = lower[i];
    final cy = _single[c];
    if (cy != null) {
      sb.write(cy.isEmpty ? '' : _matchCase(cy, src[i]));
    } else {
      sb.write(src[i]); // spaces, hyphens, digits — keep as-is
    }
    i++;
  }

  return sb.toString();
}

/// Preserves capitalisation: if the Latin source char is uppercase,
/// capitalise the first Cyrillic letter of the replacement.
String _matchCase(String cyrillic, String latinChar) {
  if (cyrillic.isEmpty) return '';
  final isUpper = latinChar != latinChar.toLowerCase() &&
      latinChar == latinChar.toUpperCase();
  if (!isUpper) return cyrillic;
  return cyrillic[0].toUpperCase() + cyrillic.substring(1);
}

// ── Digraphs (must be checked before individual letters) ─────────────────────
const _two = <String, String>{
  'sh': 'ш', // ш
  'kh': 'һ', // һ
  'gh': 'ғ', // ғ
  'dh': 'дх', // дх
  'th': 'с', // с
};

// ── Single-character mapping ─────────────────────────────────────────────────
const _single = <String, String>{
  // Long vowels (macron)
  'ā': 'а', // ā → а
  'ī': 'и', // ī → и
  'ū': 'у', // ū → у

  // Emphatic / pharyngeal consonants (dot below)
  'ḥ': 'х', // ḥ → х  (ح)
  'ḍ': 'д', // ḍ → д
  'ṣ': 'с', // ṣ → с
  'ṭ': 'т', // ṭ → т
  'ẓ': 'з', // ẓ → з

  // Other special romanisation chars
  'ṯ': 'с', // ṯ → с  (ث)
  'ḏ': 'з', // ḏ → з  (ذ)
  'ġ': 'ғ', // ġ → ғ  (غ)
  'ḫ': 'х', // ḫ → х  (خ alternate)

  // ه ha — soft, rendered as Kazakh һ (U+04BB)
  'ه': 'һ', // ه Arabic letter ha → Kazakh һ

  // ع ayn — pharyngeal, rendered as ъ (U+044A)
  'ʿ': '', // ʿ ALA-LC romanisation of ع → ъ
  'ع': 'ъ', // ع Arabic letter ayn → ъ

  // Hamza / glottal stop — silent in Kazakh phonetics
  'ʾ': '',       // ʾ hamza
  '’': '',       // ' right single quotation mark (used for ʾ)
  "'": 'ъ',            // ASCII apostrophe

  // Standard Latin → Cyrillic
  'a': 'а', // а
  'b': 'б', // б
  't': 'т', // т
  'j': 'ж', // ж
  'd': 'д', // д
  'r': 'р', // р
  'z': 'з', // з
  's': 'с', // с
  'f': 'ф', // ф
  'q': 'қ', // қ
  'k': 'к', // к
  'l': 'л', // л
  'm': 'м', // м
  'n': 'н', // н
  'h': 'х',
  'w': 'у', // у
  'y': 'й', // й
  'i': 'и', // и
  'u': 'у', // у
  'e': 'и', // и
  'o': 'у', // у
  'v': 'в', // в
  'p': 'п', // п
  'g': 'г', // г
  'c': 'с', // с
  'x': 'кс', // кс
};
