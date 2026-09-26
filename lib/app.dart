import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/db/content_queries.dart';
import 'core/db/database_providers.dart';

/// Placeholder shell.
///
/// Exists to prove the database path works end to end: asset copied out of the
/// bundle, opened on a background isolate, queried. Replaced by the real
/// navigation and screens in the next step.
class QuranAnswersApp extends StatelessWidget {
  const QuranAnswersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Answers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
      ),
      home: const _StartupCheck(),
    );
  }
}

class _StartupCheck extends ConsumerWidget {
  const _StartupCheck();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(startupSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quran Answers')),
      body: Center(
        child: switch (summary) {
          AsyncData(:final value) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line),
                  ),
              ],
            ),
          ),
          AsyncError(:final error) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to open the database:\n$error'),
          ),
          _ => const CircularProgressIndicator(),
        },
      ),
    );
  }
}

/// A few lines proving the content database is readable.
///
/// Public so the startup test can resolve it before pumping a widget: a future
/// started during a widget build belongs to the test's fake-clock zone and will
/// not advance on its own.
final startupSummaryProvider = FutureProvider<List<String>>((ref) async {
  final db = await ref.watch(contentDatabaseProvider.future);
  final meta = await db.metadata();
  final questions = await db.allQuestions();
  final detail = await db.questionDetail(questions.first.slug);

  return [
    'content version ${meta['contentVersion']}',
    '${meta['ayahCount']} ayat, ${questions.length} questions',
    'translation: ${meta['translationName']}',
    '',
    questions.first.questionBn,
    if (detail != null && detail.ayahs.isNotEmpty)
      '${detail.surahOf(detail.ayahs.first).nameBn} '
          '${detail.ayahs.first.surah}:${detail.ayahs.first.ayah}',
    if (detail != null && detail.ayahs.isNotEmpty)
      detail.ayahs.first.textUthmani,
  ];
});
