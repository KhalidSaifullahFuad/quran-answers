import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_db.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import '../questions/question_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(questionIndexProvider);
    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: index,
          data: (index) => ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              ContentFrame(
                child: ScreenHeader(
                  wordmark: true,
                  showBack: false,
                  actions: [
                    IconButton(
                      onPressed: context.openSettings,
                      tooltip: Strings.settings,
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
              ContentFrame(child: _Body(index: index)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.index});

  final QuestionIndex index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppText.of(context);
    final featured = questionOfTheDay(
      index.questions,
      ref.watch(todayProvider),
    );
    final recent = ref.watch(recentSlugsProvider).value ?? const [];
    final lastRead = recent.map(index.bySlug).nonNulls.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(Strings.tagline, style: t.display),
              const SizedBox(height: 16),
              SearchFieldButton(
                hint: Strings.searchHint,
                onTap: context.openSearch,
              ),
            ],
          ),
        ),
        if (featured != null) ...[
          const SizedBox(height: 26),
          _FeaturedCard(question: featured),
        ],
        if (lastRead != null) ...[
          const SizedBox(height: 26),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.gutter),
            child: SectionTitle(Strings.lastRead),
          ),
          const SizedBox(height: 4),
          QuestionTile(
            icon: Icons.history_rounded,
            title: lastRead.questionBn,
            meta: index.rowMeta(lastRead),
            onTap: () => context.openQuestion(lastRead.slug),
          ),
        ],
        const SizedBox(height: 26),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Space.gutter),
          child: SectionTitle(Strings.topics),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Row(
            children: [
              for (final c in index.categories.values) ...[
                TopicChip(
                  label: c.nameBn,
                  icon: categoryIcon(c.id),
                  onTap: () => context.openCategory(c.id),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: SectionTitle(
            Strings.allQuestions,
            trailing: Strings.questionCount(bnDigits(index.questions.length)),
          ),
        ),
        const SizedBox(height: 4),
        for (final q in index.questions)
          QuestionTile(
            icon: categoryIcon(q.category),
            title: q.questionBn,
            meta: index.rowMeta(q),
            onTap: () => context.openQuestion(q.slug),
          ),
      ],
    );
  }
}

/// Today's question: its first cited ayah, the question, the citation.
class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final detail = ref.watch(questionDetailProvider(question.slug)).value;
    final first = detail?.ayahs.firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(Space.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.openQuestion(question.slug),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(Strings.questionOfTheDay, style: t.label),
                    ),
                    Text(
                      bnDayMonth(ref.watch(todayProvider)),
                      style: t.meta.copyWith(color: c.fg4),
                    ),
                  ],
                ),
                if (first != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                    decoration: BoxDecoration(
                      color: c.evidence,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ArabicText(
                      first.textUthmani,
                      ayah: first.ayah,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(question.questionBn, style: t.cardTitle),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // The pill takes what the link leaves; a Spacer here would
                    // claim half the row and squeeze the citation.
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: first == null
                            ? null
                            : RefPill(
                                label: refLong(
                                  detail!.surahOf(first),
                                  first.id,
                                ),
                                icon: Icons.menu_book_rounded,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(Strings.answerAndEvidence, style: t.link),
                    Icon(Icons.chevron_right_rounded, size: 18, color: c.fg2),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
