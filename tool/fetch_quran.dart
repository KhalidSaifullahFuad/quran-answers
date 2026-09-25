// Fetches the full mushaf from api.quran.com into content/quran.json.
//
// This runs at BUILD time only. The shipped app never talks to a network, so
// the API is a development dependency, not a runtime one. Run it once; re-run
// only to change the translation.
//
//   dart run tool/fetch_quran.dart
//
// The Arabic text in this app must never be typed or copied by hand — the
// source document it came from has PDF-corrupted Arabic, and shipping
// corrupted scripture is the worst failure this app could have. Everything
// Arabic originates here.

import 'dart:convert';
import 'dart:io';

/// Sheikh Mujibur Rahman (Darussalaam Publication).
/// Chosen over 161/162/213 partly because its text carries no inline footnote
/// markers, which keeps the displayed translation clean.
const translationId = 163;
const translationName = 'Sheikh Mujibur Rahman';
const translationAuthor = 'Darussalaam Publication';

const apiBase = 'https://api.quran.com/api/v4';
const surahCount = 114;
const expectedAyahCount = 6236;

final _client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

Future<Map<String, dynamic>> _getJson(String path) async {
  const maxAttempts = 4;
  for (var attempt = 1; ; attempt++) {
    try {
      final request = await _client.getUrl(Uri.parse('$apiBase$path'));
      request.headers.set('accept', 'application/json');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode} for $path');
      }
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      if (attempt >= maxAttempts) {
        stderr.writeln('\nFailed after $maxAttempts attempts: $path\n$e');
        rethrow;
      }
      // Back off rather than hammering a free public API.
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    }
  }
}

/// Strips the HTML the translation endpoint embeds.
///
/// Footnote markers come through as `<sup foot_note=...>N</sup>`; the whole
/// element goes, marker text included, because a bare digit dropped into
/// Bengali prose reads as part of the sentence.
String _cleanTranslation(String raw) {
  var text = raw.replaceAll(RegExp(r'<sup\b[^>]*>.*?</sup>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
  text = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

Future<List<Map<String, dynamic>>> _fetchSurahs() async {
  final json = await _getJson('/chapters?language=bn');
  final chapters = (json['chapters'] as List).cast<Map<String, dynamic>>();
  return [
    for (final c in chapters)
      {
        'number': c['id'],
        'nameAr': c['name_arabic'],
        'nameBn': (c['translated_name'] as Map)['name'],
        'nameEn': c['name_simple'],
        'ayahCount': c['verses_count'],
        'revelationPlace': c['revelation_place'],
      },
  ];
}

Future<List<Map<String, dynamic>>> _fetchAyahs(int surah) async {
  final ayahs = <Map<String, dynamic>>[];
  var page = 1;
  while (true) {
    final json = await _getJson(
      '/verses/by_chapter/$surah'
      '?fields=text_uthmani,text_imlaei'
      '&translations=$translationId'
      '&words=false&per_page=50&page=$page',
    );
    final verses = (json['verses'] as List).cast<Map<String, dynamic>>();
    for (final v in verses) {
      final translations = (v['translations'] as List?) ?? const [];
      if (translations.isEmpty) {
        throw StateError('No translation for ${v['verse_key']}');
      }
      final uthmani = (v['text_uthmani'] as String?)?.trim();
      if (uthmani == null || uthmani.isEmpty) {
        throw StateError('No Uthmani text for ${v['verse_key']}');
      }
      ayahs.add({
        'surah': surah,
        'ayah': v['verse_number'],
        'textUthmani': uthmani,
        'textPlain': (v['text_imlaei'] as String?)?.trim() ?? uthmani,
        'translationBn': _cleanTranslation(
          (translations.first as Map)['text'] as String,
        ),
      });
    }
    final pagination = json['pagination'] as Map<String, dynamic>;
    final totalPages = pagination['total_pages'] as int? ?? 1;
    if (page >= totalPages) break;
    page++;
  }
  return ayahs;
}

Future<void> main() async {
  final surahs = await _fetchSurahs();
  if (surahs.length != surahCount) {
    throw StateError('Expected $surahCount surahs, got ${surahs.length}');
  }

  final ayahs = <Map<String, dynamic>>[];
  for (var n = 1; n <= surahCount; n++) {
    final fetched = await _fetchAyahs(n);
    final declared = surahs[n - 1]['ayahCount'] as int;
    if (fetched.length != declared) {
      throw StateError(
        'Surah $n: fetched ${fetched.length} ayat, chapter list says $declared',
      );
    }
    ayahs.addAll(fetched);
    stdout.write('\rSurah $n/$surahCount  ${ayahs.length} ayat');
  }
  stdout.writeln();

  // A wrong total here means a silently truncated mushaf, which would be
  // invisible in the UI until someone opened the missing verse.
  if (ayahs.length != expectedAyahCount) {
    throw StateError('Expected $expectedAyahCount ayat, got ${ayahs.length}');
  }

  final output = {
    'translationId': translationId,
    'translationName': translationName,
    'translationAuthor': translationAuthor,
    'source': 'api.quran.com/api/v4',
    'fetchedAt': DateTime.now().toUtc().toIso8601String(),
    'surahs': surahs,
    'ayahs': ayahs,
  };

  final file = File('content/quran.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(output),
    encoding: utf8,
  );
  final mb = (await file.length()) / 1024 / 1024;
  stdout.writeln(
    'Wrote ${file.path}: ${ayahs.length} ayat, '
    '${mb.toStringAsFixed(1)} MB, translation $translationId.',
  );
  _client.close();
}
