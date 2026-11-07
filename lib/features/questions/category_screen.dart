import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/app_header.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import 'question_providers.dart';

/// Every question in one category.
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(questionIndexProvider);
    final loaded = index.value;
    final meta = AppText.of(context).meta;
    return AppPage(
      header: AppHeader(
        title: loaded?.categories[categoryId]?.nameBn,
        actions: [
          if (loaded != null)
            // Plain meta text, not a button: padded so it ends on the gutter
            // like an action glyph would.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                Strings.questionCount(
                  bnDigits(loaded.inCategory(categoryId).length),
                ),
                style: meta.copyWith(fontSize: 13.5),
              ),
            ),
        ],
      ),
      body: AsyncBody(
        value: index,
        data: (index) {
          final questions = index.inCategory(categoryId);
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, Space.belowHeader, 0, 32),
            children: [
              ContentFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Numbered: every row shares the category, so its icon
                    // would only repeat down the list.
                    for (final (i, q) in questions.indexed)
                      QuestionTile(
                        icon: Text(
                          bnDigits(i + 1),
                          style: meta.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        title: q.questionBn,
                        meta: refsSummary(index.citationsOf(q)),
                        onTap: () => context.openQuestion(q.slug),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
