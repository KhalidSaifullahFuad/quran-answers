import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/database_providers.dart';
import '../../core/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/folder_sheet.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import '../questions/question_providers.dart';

/// Questions read recently, newest first, with a way to clear them.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(
      context,
      Strings.clearHistoryConfirm,
      action: Strings.delete,
    );
    if (!ok) return;
    final db = await ref.read(userDatabaseProvider.future);
    await db.clearHistory();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(questionIndexProvider);
    final history = ref.watch(recentSlugsProvider).value ?? const [];
    final t = AppText.of(context);
    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: index,
          data: (index) {
            final questions = history.map(index.bySlug).nonNulls.toList();
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ContentFrame(
                  child: ScreenHeader(
                    title: Strings.readingHistory,
                    actions: [
                      if (questions.isNotEmpty)
                        IconButton(
                          onPressed: () => _clear(context, ref),
                          tooltip: Strings.clearHistory,
                          icon: const Icon(IconsaxPlusLinear.trash),
                        ),
                    ],
                  ),
                ),
                ContentFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      if (questions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.gutter,
                            vertical: 10,
                          ),
                          child: Text(
                            Strings.historyEmpty,
                            style: t.meta.copyWith(fontSize: 14),
                          ),
                        ),
                      for (final q in questions)
                        QuestionTile(
                          icon: CategoryIcon(q.category),
                          title: q.questionBn,
                          meta: index.rowMeta(q),
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
