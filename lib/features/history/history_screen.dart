import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/content_db.dart';
import '../../core/db/database_providers.dart';
import '../../core/strings.dart';
import '../../core/theme/colors.dart';
import '../../shared/app_header.dart';
import '../../shared/empty_state.dart';
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
    final questions = switch (index.value) {
      final index? => history.map(index.bySlug).nonNulls.toList(),
      null => const <Question>[],
    };
    return AppPage(
      header: AppHeader(
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
      body: AsyncBody(
        value: index,
        data: (index) => questions.isEmpty
            ? const EmptyState(
                icon: IconsaxPlusBold.clock,
                title: Strings.historyEmpty,
                message: Strings.historyEmptyHint,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(0, Space.belowHeader, 0, 32),
                children: [
                  for (final q in questions)
                    ContentFrame(
                      child: QuestionTile(
                        icon: CategoryIcon(q.category),
                        title: q.questionBn,
                        meta: index.rowMeta(q),
                        onTap: () => context.openQuestion(q.slug),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
