/// Words people type for the same thing, as groups of equals.
///
/// The translation uses the Arabic-derived term (সালাত, সিয়াম) while everyday
/// Bengali says নামাজ, রোজা; a query in one finds the other through here.
/// Spellings that only differ by the letters [looseFold] merges (যাকাত /
/// জাকাত, নূহ / নুহ) need no entry. Every word is a stem: it is matched as a
/// prefix, so সালাত also reaches সালাতের.
///
/// Bengali only. Arabic is never written into the code.
library;

import 'normalize.dart';

const List<List<String>> synonymGroups = [
  ['সালাত', 'নামাজ', 'নামায', 'সলাত'],
  ['সিয়াম', 'সাওম', 'সওম', 'রোজা', 'রোযা'],
  // Not the bare হজ: as a stem it would reach হজরত.
  ['হজ্জ', 'হাজ্জ'],
  ['কুরআন', 'কোরান'],
  ['দোয়া', 'দুআ'],
  ['জান্নাত', 'বেহেশত'],
  ['জাহান্নাম', 'দোযখ', 'নরক'],
  ['ফেরেশতা', 'ফিরিশতা', 'মালাইকা'],
  ['কিয়ামাত', 'কিয়ামত', 'কেয়ামত'],
  ['মুহাম্মাদ', 'মুহাম্মদ'],
  ['শয়তান', 'শাইতান'],
  ['তাওবা', 'তওবা'],
  ['রাসূল', 'রসূল'],
  ['আখিরাত', 'আখেরাত', 'পরকাল'],
  ['রমাদান', 'রমজান'],
  ['মারইয়াম', 'মারিয়াম', 'মরিয়ম'],
];

/// Shorter stems would trigger a group on almost any partial word.
const _minStem = 3;

/// Loose forms of every group, built once.
final List<List<String>> _looseGroups = [
  for (final g in synonymGroups)
    [for (final w in g) looseFold(normalizeForSearch(w))],
];

/// The other members of every group [word] belongs to, normalized.
///
/// [word] is a normalized query word. It belongs to a group when it extends a
/// member (সালাতের → সালাত) or is a partial of one being typed (নামা → নামাজ),
/// compared in loose form.
List<String> synonymsOf(String word) {
  final loose = looseFold(word);
  if (loose.runes.length < _minStem) return const [];
  final out = <String>[];
  for (final (i, group) in _looseGroups.indexed) {
    final hit = group.any((m) => loose.startsWith(m) || m.startsWith(loose));
    if (!hit) continue;
    for (final w in synonymGroups[i]) {
      final n = normalizeForSearch(w);
      if (n != word) out.add(n);
    }
  }
  return out;
}
