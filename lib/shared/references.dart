import 'package:flutter/material.dart';

import '../core/db/content_db.dart';
import '../core/text/numerals.dart';

/// How a surah is named in a citation.
///
/// The design names surahs by Bengali transliteration (আল-কামার). The content
/// database only has the Bengali *meaning* (চাঁদ), which reads wrongly as a
/// citation, and the English transliteration. Until transliterations are
/// authored, citations use the English one; this is the single place to switch.
String surahLabel(Surah surah) => surah.nameEn;

/// `৫৪:১৫`.
String refShort(int ayahId) =>
    '${bnDigits(surahOfAyahId(ayahId))}:${bnDigits(ayahOfAyahId(ayahId))}';

/// `Al-Qamar · ৫৪:১৫`.
String refLong(Surah surah, int ayahId) =>
    '${surahLabel(surah)} · ${refShort(ayahId)}';

/// Row meta: at most three references, then a count of the rest.
String refsSummary(List<int> ayahIds) {
  const shown = 3;
  final head = ayahIds.take(shown).map(refShort).join(', ');
  final rest = ayahIds.length - shown;
  return rest > 0 ? '$head +${bnDigits(rest)}' : head;
}

/// Icon for a category chip or question row.
///
/// Keyed by category id with a neutral fallback, so a category added in content
/// without an entry here still renders.
IconData categoryIcon(String categoryId) => switch (categoryId) {
  'words' => Icons.translate_rounded,
  'quran-itself' => Icons.menu_book_rounded,
  'worship' => Icons.mosque_rounded,
  _ => Icons.label_rounded,
};
