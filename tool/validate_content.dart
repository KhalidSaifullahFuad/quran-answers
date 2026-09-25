// Checks content/questions.json against content/quran.json.
//
//   dart run tool/validate_content.dart
//
// Run before building the database; build_db.dart runs the same checks itself
// and refuses to write a file if any of them fail.

import 'dart:io';

import 'content_source.dart';

void main() {
  final questions = Questions.load();
  final mushaf = Mushaf.load();
  final errors = validate(questions, mushaf);

  final drafts = questions.all.where((q) => q['status'] == 'draft').toList();
  final published = questions.published;

  stdout.writeln('content version ${questions.contentVersion}');
  stdout.writeln('${questions.categories.length} categories');
  stdout.writeln('${published.length} published, ${drafts.length} draft');
  for (final d in drafts) {
    stdout.writeln('  draft: ${d['slug']}');
    final note = d['reviewNote'] as String?;
    if (note != null) stdout.writeln('         $note');
  }

  if (errors.isEmpty) {
    stdout.writeln('OK');
    return;
  }
  stderr.writeln('\n${errors.length} problem(s):');
  for (final e in errors) {
    stderr.writeln('  $e');
  }
  exitCode = 1;
}
