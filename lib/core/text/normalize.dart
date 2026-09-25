/// Text normalization shared by the build tooling (`tool/`) and the app.
///
/// The FTS5 index is built over normalized text at build time, and user queries
/// are normalized at runtime with the same code. If the two ever diverge,
/// search silently returns nothing — so this library must stay free of Flutter
/// imports and must never be forked.
library;

/// Codepoint ranges stripped from Arabic text before indexing.
///
/// Uthmani script carries tashkeel and Qur'anic annotation signs that a user
/// will not type. Removing them lets `مدكر` match `مُدَّكِر`.
const List<List<int>> _arabicMarkRanges = [
  [0x0610, 0x061A], // Arabic signs (sallallahou alayhe wasallam, etc.)
  [0x064B, 0x065F], // tashkeel: fathatan..wavy hamza below
  [0x0670, 0x0670], // superscript alef
  [0x06D6, 0x06ED], // small high/low annotation signs, end of ayah, sajdah
  [0x08D3, 0x08FF], // Arabic Extended-A marks
];

/// Letters folded to a single canonical form.
///
/// Hamza carriers and the various alef forms are inconsistently typed, so they
/// are collapsed. This loses orthographic detail, which is acceptable in a
/// search column but never in displayed text.
const Map<String, String> _arabicLetterFolds = {
  '\u0622': '\u0627', // آ -> ا
  '\u0623': '\u0627', // أ -> ا
  '\u0625': '\u0627', // إ -> ا
  '\u0671': '\u0627', // ٱ alef wasla -> ا
  '\u0672': '\u0627',
  '\u0673': '\u0627',
  '\u0649': '\u064A', // ى alef maksura -> ي
  '\u06CC': '\u064A', // Farsi ye -> ي
  '\u0626': '\u064A', // ئ -> ي
  '\u0624': '\u0648', // ؤ -> و
  '\u0629': '\u0647', // ة ta marbuta -> ه
  '\u06A9': '\u0643', // Persian kaf -> ك
  '\u0640': '', // tatweel: drop
  '\u0621': '', // standalone hamza: drop
};

/// Bengali sequences recomposed to their canonical single codepoint.
///
/// Dart has no built-in Unicode normalization, so the NFC compositions that
/// actually occur in Bengali text are applied by hand. Without this, `ড়` typed
/// as `ড` + nukta fails to match the composed form.
const Map<String, String> _bengaliCompositions = {
  '\u09A1\u09BC': '\u09DC', // ড + nukta -> ড়
  '\u09A2\u09BC': '\u09DD', // ঢ + nukta -> ঢ়
  '\u09AF\u09BC': '\u09DF', // য + nukta -> য়
  '\u09C7\u09BE': '\u09CB', // ে + া -> ো
  '\u09C7\u09D7': '\u09CC', // ে + ৗ -> ৌ
};

/// Zero-width and directional formatting characters, always dropped.
const List<List<int>> _invisibleRanges = [
  [0x200B, 0x200F], // ZWSP, ZWNJ, ZWJ, LRM, RLM
  [0x202A, 0x202E], // embedding/override
  [0x2066, 0x2069], // isolates
  [0xFEFF, 0xFEFF], // BOM
];

bool _inRanges(int cp, List<List<int>> ranges) {
  for (final r in ranges) {
    if (cp >= r[0] && cp <= r[1]) return true;
  }
  return false;
}

/// Folds Bengali (`০`-`৯`) and Arabic-Indic (`٠`-`٩`, `۰`-`۹`) digits to ASCII,
/// so a reference typed as `৫৪:১৫` and `54:15` normalize alike.
String foldDigits(String input) {
  final out = StringBuffer();
  for (final cp in input.runes) {
    if (cp >= 0x09E6 && cp <= 0x09EF) {
      out.writeCharCode(0x30 + (cp - 0x09E6)); // Bengali
    } else if (cp >= 0x0660 && cp <= 0x0669) {
      out.writeCharCode(0x30 + (cp - 0x0660)); // Arabic-Indic
    } else if (cp >= 0x06F0 && cp <= 0x06F9) {
      out.writeCharCode(0x30 + (cp - 0x06F0)); // Extended Arabic-Indic
    } else {
      out.writeCharCode(cp);
    }
  }
  return out.toString();
}

/// Strips tashkeel and annotation signs, then folds hamza and alef variants.
String normalizeArabic(String input) {
  final stripped = StringBuffer();
  for (final cp in input.runes) {
    if (_inRanges(cp, _arabicMarkRanges)) continue;
    stripped.writeCharCode(cp);
  }
  var result = stripped.toString();
  _arabicLetterFolds.forEach((from, to) {
    result = result.replaceAll(from, to);
  });
  return result;
}

/// Recomposes nukta and vowel-sign sequences and drops ZWNJ/ZWJ.
///
/// Hasanta (`\u09CD`) is preserved: it forms conjuncts and carries meaning.
String normalizeBengali(String input) {
  var result = input;
  _bengaliCompositions.forEach((from, to) {
    result = result.replaceAll(from, to);
  });
  return result;
}

/// The single entry point used to build every `search_*` column and to
/// normalize every runtime query.
///
/// Safe on mixed-script text: the Arabic and Bengali passes touch disjoint
/// codepoint ranges.
String normalizeForSearch(String input) {
  var result = normalizeBengali(normalizeArabic(input));

  final visible = StringBuffer();
  for (final cp in result.runes) {
    if (_inRanges(cp, _invisibleRanges)) continue;
    visible.writeCharCode(cp);
  }
  result = foldDigits(visible.toString());

  // Punctuation that varies between sources becomes a space so it never glues
  // two tokens together or splits one the user typed whole.
  result = result.replaceAll(
    RegExp(
      r'[\u0022\u201C\u201D\u2018\u2019'
      r'\u060C\u061B\u061F\u066A-\u066D\u06D4'
      r'(),\[\]{}!?;.\u2026\u2013\u2014\u2012-]',
    ),
    ' ',
  );

  return result.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
