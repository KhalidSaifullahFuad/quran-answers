import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/core/text/normalize.dart';

/// Guards the actual premise of search: that a user typing bare, unpointed
/// Arabic finds the pointed Uthmani text that ships in the database.
///
/// The unit tests in normalize_test.dart check the rules in isolation; this
/// checks them against the real 6,236-ayah mushaf, which is where unexpected
/// marks and orthography actually live.
void main() {
  late Map<String, Map<String, dynamic>> byKey;
  late List<Map<String, dynamic>> ayahs;

  setUpAll(() {
    final file = File('content/quran.json');
    if (!file.existsSync()) {
      fail('content/quran.json missing - run: dart run tool/fetch_quran.dart');
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    ayahs = (json['ayahs'] as List).cast<Map<String, dynamic>>();
    byKey = {for (final a in ayahs) '${a['surah']}:${a['ayah']}': a};
  });

  /// Asserts that `query`, once normalized, is a substring of the normalized
  /// Uthmani text of `key` - the exact operation FTS5 will be doing.
  void expectFindable(String key, String query, String label) {
    final ayah = byKey[key];
    expect(ayah, isNotNull, reason: '$key not in mushaf');
    final haystack = normalizeForSearch(ayah!['textUthmani'] as String);
    final needle = normalizeForSearch(query);
    expect(
      haystack.contains(needle),
      isTrue,
      reason: '$label ("$needle") not found in normalized $key: $haystack',
    );
  }

  test('bare query finds pointed Uthmani text for the seed questions', () {
    // مدكر in 54:15 - the word the first question asks about, typed without
    // shadda or kasra.
    expectFindable('54:15', '\u0645\u062F\u0643\u0631', 'muddakkir');
    // النبا in 78:2 - hamza-on-alef folding matters here.
    expectFindable('78:2', '\u0627\u0644\u0646\u0628\u0627', 'an-naba');
    // تلاوته in 2:121.
    expectFindable(
      '2:121',
      '\u062A\u0644\u0627\u0648\u062A\u0647',
      'tilawatihi',
    );
    // امن الرسول in 2:285 - أ folded to ا, and the two words stay adjacent.
    expectFindable(
      '2:285',
      '\u0627\u0645\u0646 \u0627\u0644\u0631\u0633\u0648\u0644',
      'amana',
    );
    // هدنا اليك in 7:156.
    expectFindable(
      '7:156',
      '\u0647\u062F\u0646\u0627 \u0627\u0644\u064A\u0643',
      'hudna ilayk',
    );
  });

  test('a hamza-on-alef query reaches a hamza-on-waw spelling', () {
    // The second seed question asks where the Qur'an is called a "great
    // tiding": 78:2 spells it with the definite article, 38:67 with the hamza
    // riding a waw. A user types the hamza on an alef in both cases, so both
    // spellings have to be reachable from that one keyboard form. This is the
    // regression the hamza-seat rule exists for.
    const indefinite = 'نبأ عظيم'; // نبأ عظيم
    expectFindable('38:67', indefinite, 'naba azeem, hamza typed on alef');

    const definite = 'النبأ العظيم';
    expectFindable('78:2', definite, 'an-naba al-azeem');
  });

  test('the definite article is NOT stripped, so search must handle it', () {
    // Documents a known limitation rather than a bug: النبا and نبا remain
    // distinct tokens, so a bare query will not reach an ayah that carries the
    // article. The search layer deals with this; normalization does not, since
    // stripping a leading ال would corrupt words that legitimately begin with
    // those letters.
    final withArticle = normalizeForSearch(
      byKey['78:2']!['textUthmani'] as String,
    );
    expect(
      withArticle.contains('نبا عظيم'),
      isFalse,
      reason: 'if this ever passes, normalization started stripping ال',
    );
  });

  test('no ayah normalizes to an empty string', () {
    final blankArabic = <String>[];
    final blankBengali = <String>[];
    for (final a in ayahs) {
      final key = '${a['surah']}:${a['ayah']}';
      if (normalizeForSearch(a['textUthmani'] as String).isEmpty) {
        blankArabic.add(key);
      }
      if (normalizeForSearch(a['translationBn'] as String).isEmpty) {
        blankBengali.add(key);
      }
    }
    expect(blankArabic, isEmpty, reason: 'unsearchable Arabic');
    expect(blankBengali, isEmpty, reason: 'unsearchable Bengali');
  });

  test('normalization leaves no tashkeel behind anywhere in the mushaf', () {
    // If any combining mark survives, queries against that ayah silently fail.
    final marks = RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]');
    final offenders = <String>[];
    for (final a in ayahs) {
      if (marks.hasMatch(normalizeForSearch(a['textUthmani'] as String))) {
        offenders.add('${a['surah']}:${a['ayah']}');
      }
    }
    expect(offenders, isEmpty, reason: 'residual marks in ${offenders.length}');
  });

  test('mushaf is complete', () {
    expect(ayahs.length, 6236);
  });
}
