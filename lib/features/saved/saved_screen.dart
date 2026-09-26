import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_db.dart';
import '../../core/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import '../questions/question_providers.dart';

/// Bookmarked questions, then reading history.
///
/// Both lists hold slugs from the user database. A slug whose question a
/// content update removed is simply skipped.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(questionIndexProvider);
    final saved = ref.watch(bookmarkedSlugsProvider).value ?? const [];
    final history = ref.watch(recentSlugsProvider).value ?? const [];
    final t = AppText.of(context);

    List<Widget> rows(
      QuestionIndex index,
      List<String> slugs,
      IconData icon,
      String empty,
    ) {
      final questions = slugs.map(index.bySlug).nonNulls.toList();
      if (questions.isEmpty) {
        return [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.gutter,
              vertical: 10,
            ),
            child: Text(empty, style: t.meta.copyWith(fontSize: 14)),
          ),
        ];
      }
      return [
        for (final Question q in questions)
          QuestionTile(
            icon: icon,
            title: q.questionBn,
            meta: refsSummary(index.citationsOf(q)),
            onTap: () => context.openQuestion(q.slug),
          ),
      ];
    }

    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: index,
          data: (index) => ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const ContentFrame(
                child: ScreenHeader(title: Strings.navSaved, showBack: false),
              ),
              ContentFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...rows(
                      index,
                      saved,
                      Icons.bookmark_rounded,
                      Strings.savedEmpty,
                    ),
                    const SizedBox(height: 22),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                      child: SectionTitle(Strings.readingHistory),
                    ),
                    const SizedBox(height: 4),
                    ...rows(
                      index,
                      history,
                      Icons.history_rounded,
                      Strings.historyEmpty,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
