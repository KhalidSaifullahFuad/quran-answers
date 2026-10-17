// Reading and validating the authored content files.
//
// Shared by tool/validate_content.dart and tool/build_db.dart so that the
// builder can never accept input the validator would reject.

import 'dart:convert';
import 'dart:io';

class ContentError {
  ContentError(this.where, this.message);
  final String where;
  final String message;

  @override
  String toString() => '$where: $message';
}

class Mushaf {
  Mushaf(this.surahs, this.ayahs, this.translationName, this.translationAuthor);

  final List<Map<String, dynamic>> surahs;

  /// Keyed `"surah:ayah"`.
  final Map<String, Map<String, dynamic>> ayahs;
  final String translationName;
  final String translationAuthor;

  static Mushaf load([String path = 'content/quran.json']) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('$path missing - run: dart run tool/fetch_quran.dart');
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final ayahs = (json['ayahs'] as List).cast<Map<String, dynamic>>();
    return Mushaf(
      (json['surahs'] as List).cast<Map<String, dynamic>>(),
      {for (final a in ayahs) '${a['surah']}:${a['ayah']}': a},
      json['translationName'] as String,
      json['translationAuthor'] as String,
    );
  }

  int? ayahCountOf(int surah) {
    for (final s in surahs) {
      if (s['number'] == surah) return s['ayahCount'] as int;
    }
    return null;
  }
}

class Questions {
  Questions(this.contentVersion, this.categories, this.all);

  final int contentVersion;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> all;

  /// Only these are compiled into the shipped database. A draft is an entry
  /// whose claim has not been checked against the mushaf, or whose cited ayah
  /// does not support its answer.
  List<Map<String, dynamic>> get published =>
      all.where((q) => q['status'] == 'published').toList();

  static Questions load([String path = 'content/questions.json']) {
    final file = File(path);
    if (!file.existsSync()) throw StateError('$path missing');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return Questions(
      json['contentVersion'] as int,
      (json['categories'] as List).cast<Map<String, dynamic>>(),
      (json['questions'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

final _refPattern = RegExp(r'^(\d{1,3}):(\d{1,3})$');
final _slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// Parses `"54:15"`. Returns null if malformed.
({int surah, int ayah})? parseRef(String ref) {
  final m = _refPattern.firstMatch(ref);
  if (m == null) return null;
  return (surah: int.parse(m.group(1)!), ayah: int.parse(m.group(2)!));
}

/// Every check that must hold before content can be compiled.
///
/// Returns all problems rather than throwing on the first, so an author fixing
/// content sees the whole list in one run.
List<ContentError> validate(Questions questions, Mushaf mushaf) {
  final errors = <ContentError>[];
  final categoryIds = <String>{};

  for (final (i, c) in questions.categories.indexed) {
    final id = c['id'] as String?;
    final where = 'categories[$i]';
    if (id == null || !_slugPattern.hasMatch(id)) {
      errors.add(ContentError(where, 'id "$id" is not a lowercase slug'));
      continue;
    }
    if (!categoryIds.add(id)) {
      errors.add(ContentError(where, 'duplicate category id "$id"'));
    }
    for (final field in ['nameBn', 'nameEn']) {
      if ((c[field] as String?)?.trim().isEmpty ?? true) {
        errors.add(ContentError(where, '$field is empty'));
      }
    }
  }

  final slugs = <String>{};
  for (final (i, q) in questions.all.indexed) {
    final slug = q['slug'] as String?;
    final where = 'questions[$i] (${slug ?? "no slug"})';

    if (slug == null || !_slugPattern.hasMatch(slug)) {
      errors.add(ContentError(where, 'slug "$slug" is not a lowercase slug'));
    } else if (!slugs.add(slug)) {
      // A duplicate slug would collide in the database and, worse, make one
      // question's bookmarks point at another's.
      errors.add(ContentError(where, 'duplicate slug "$slug"'));
    }

    final status = q['status'];
    if (status != 'published' && status != 'draft') {
      errors.add(ContentError(where, 'status must be published or draft'));
    }

    final category = q['category'];
    if (!categoryIds.contains(category)) {
      errors.add(ContentError(where, 'unknown category "$category"'));
    }

    for (final field in ['questionBn', 'answerBn']) {
      if ((q[field] as String?)?.trim().isEmpty ?? true) {
        errors.add(ContentError(where, '$field is empty'));
      }
    }

    if (q['sortOrder'] is! int) {
      errors.add(ContentError(where, 'sortOrder must be an integer'));
    }

    final refs = (q['refs'] as List?)?.cast<String>() ?? const [];
    // Set per entry by the author: the answer ships without an ayah, e.g. one
    // saying the claim is not in the Qur'an.
    final noAyah = q['noAyah'] == true;
    if (refs.isEmpty && status != 'draft' && !noAyah) {
      // The whole premise of the app is that answers are grounded in ayat, so
      // a published answer with no reference is a content bug, not an edge
      // case. A draft may lack one while the author decides what it cites; it
      // never reaches the database.
      errors.add(ContentError(where, 'no ayah references'));
    }
    if (noAyah && refs.isNotEmpty) {
      errors.add(ContentError(where, 'noAyah is set but refs are given'));
    }
    final seen = <String>{};
    for (final ref in refs) {
      final parsed = parseRef(ref);
      if (parsed == null) {
        errors.add(ContentError(where, 'malformed ref "$ref", expected S:A'));
        continue;
      }
      if (!seen.add(ref)) {
        errors.add(ContentError(where, 'duplicate ref "$ref"'));
      }
      final count = mushaf.ayahCountOf(parsed.surah);
      if (count == null) {
        errors.add(ContentError(where, 'ref "$ref": no surah ${parsed.surah}'));
      } else if (parsed.ayah < 1 || parsed.ayah > count) {
        errors.add(
          ContentError(
            where,
            'ref "$ref": surah ${parsed.surah} has $count ayat',
          ),
        );
      } else if (!mushaf.ayahs.containsKey(ref)) {
        errors.add(ContentError(where, 'ref "$ref" not in quran.json'));
      }
    }
  }

  return errors;
}
