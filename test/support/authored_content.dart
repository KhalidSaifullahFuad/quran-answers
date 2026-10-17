import 'dart:convert';
import 'dart:io';

/// The authored source the shipped database is compiled from.
///
/// Tests compare the database against this file instead of hard-coding the
/// current content, so adding or reordering questions does not break them,
/// while a builder that drops, reorders or invents content still does.
class AuthoredContent {
  AuthoredContent._(this._json);

  factory AuthoredContent.load() => AuthoredContent._(
    jsonDecode(File('content/questions.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  final Map<String, dynamic> _json;

  int get contentVersion => _json['contentVersion'] as int;

  List<String> get categoryIds {
    final categories = (_json['categories'] as List)
        .cast<Map<String, dynamic>>()
        .toList();
    categories.sort(
      (a, b) => (a['sortOrder'] as int).compareTo(b['sortOrder'] as int),
    );
    return [for (final c in categories) c['id'] as String];
  }

  /// Slugs of the questions that ship, in author order.
  List<String> get publishedSlugs {
    final published = (_json['questions'] as List)
        .cast<Map<String, dynamic>>()
        .where((q) => q['status'] == 'published')
        .toList();
    published.sort(
      (a, b) => (a['sortOrder'] as int).compareTo(b['sortOrder'] as int),
    );
    return [for (final q in published) q['slug'] as String];
  }

  /// Slugs of shipped questions that cite at least one ayah. The rest are
  /// "not in the Qur'an" answers with nothing to cite.
  Set<String> get citingSlugs => {
    for (final q in (_json['questions'] as List).cast<Map<String, dynamic>>())
      if (q['status'] == 'published' && (q['refs'] as List).isNotEmpty)
        q['slug'] as String,
  };
}
