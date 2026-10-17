import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../core/db/content_db.dart';
import '../core/text/numerals.dart';
import 'widgets.dart';

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
///
/// Each glyph differs from the navigation and settings icons, so `book_1` (the
/// surahs tab) and `sun_1` (light theme) are not reused here.
///
/// Two-tone: the Linear outline over the Bold shape, drawn by [CategoryIcon].
DuoIconData categoryIcon(String categoryId) => switch (categoryId) {
  'words' => (line: IconsaxPlusLinear.quote_up, fill: IconsaxPlusBold.quote_up),
  'quran-itself' => (line: IconsaxPlusLinear.book, fill: IconsaxPlusBold.book),
  'iman' => (line: IconsaxPlusLinear.heart, fill: IconsaxPlusBold.heart),
  // Iconsax has no mosque; the crescent stands in.
  'worship' => (line: IconsaxPlusLinear.moon, fill: IconsaxPlusBold.moon),
  // A rasul is a messenger.
  'prophets' => (
    line: IconsaxPlusLinear.messages_2,
    fill: IconsaxPlusBold.messages_2,
  ),
  // Speech with a heart: words said to Allah and to each other.
  'dua' => (
    line: IconsaxPlusLinear.message_favorite,
    fill: IconsaxPlusBold.message_favorite,
  ),
  'family' => (
    line: IconsaxPlusLinear.profile_2user,
    fill: IconsaxPlusBold.profile_2user,
  ),
  'wealth' => (
    line: IconsaxPlusLinear.money_send,
    fill: IconsaxPlusBold.money_send,
  ),
  'ethics' => (line: IconsaxPlusLinear.people, fill: IconsaxPlusBold.people),
  'law' => (line: IconsaxPlusLinear.judge, fill: IconsaxPlusBold.judge),
  'akhirah' => (
    line: IconsaxPlusLinear.unlimited,
    fill: IconsaxPlusBold.unlimited,
  ),
  'signs' => (line: IconsaxPlusLinear.tree, fill: IconsaxPlusBold.tree),
  'calendar' => (
    line: IconsaxPlusLinear.calendar,
    fill: IconsaxPlusBold.calendar,
  ),
  // Not "forbidden": the claim is absent, not prohibited.
  'not-in-quran' => (
    line: IconsaxPlusLinear.minus_cirlce,
    fill: IconsaxPlusBold.minus_cirlce,
  ),
  _ => fallbackCategoryIcon,
};

/// For a category added in content before it gets its own icon.
const fallbackCategoryIcon = (
  line: IconsaxPlusLinear.tag,
  fill: IconsaxPlusBold.tag,
);

/// A category's two-tone icon, sized and coloured by the [IconTheme] unless
/// given.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.categoryId, {super.key, this.size, this.color});

  final String categoryId;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      DuoIcon(categoryIcon(categoryId), size: size, color: color);
}
