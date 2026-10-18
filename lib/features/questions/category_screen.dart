import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/typography.dart';
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
    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: index,
          data: (index) {
            final category = index.categories[categoryId];
            final questions = index.inCategory(categoryId);
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ContentFrame(
                  child: ScreenHeader(
                    title: category?.nameBn,
                    actions: [
                      // Plain meta text, not a button: padded so it ends on
                      // the gutter like an action glyph would.
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: Text(
                          Strings.questionCount(bnDigits(questions.length)),
                          style: AppText.of(
                            context,
                          ).meta.copyWith(fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
                ContentFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Numbered: every row shares the category, so its
                      // icon would only repeat down the list.
                      for (final (i, q) in questions.indexed)
                        QuestionTile(
                          icon: Text(
                            bnDigits(i + 1),
                            style: AppText.of(context).meta.copyWith(
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
      ),
    );
  }
}
