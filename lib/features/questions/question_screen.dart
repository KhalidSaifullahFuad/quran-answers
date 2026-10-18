import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/db/content_db.dart';
import '../../core/db/content_queries.dart';
import '../../core/db/database_providers.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/ayah_card.dart';
import '../../shared/folder_sheet.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import 'question_providers.dart';

/// A question, its compiled answer, and every ayah it cites in full.
///
/// The ayat are the point of the screen: the answer is only a summary of them,
/// so each one is shown whole, in Arabic and in translation, never excerpted.
class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  /// One key per evidence card, so a citation pill or grid cell can scroll to
  /// the verse it names.
  final _cardKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    ref
        .read(userDatabaseProvider.future)
        .then((db) => db.recordView(widget.slug));
  }

  void _scrollTo(int ayahId) {
    final target = _cardKeys[ayahId]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 260),
      curve: const Cubic(.2, 0, 0, 1),
      alignment: .1,
    );
  }

  Future<void> _toggleBookmark() async {
    final messenger = ScaffoldMessenger.of(context);
    final db = await ref.read(userDatabaseProvider.future);
    final on = await db.toggleBookmark(widget.slug);
    if (!mounted) return;
    showStatusToast(
      messenger,
      icon: on ? IconsaxPlusBold.archive_1 : IconsaxPlusLinear.archive_1,
      text: on ? Strings.bookmarked : Strings.unbookmarked,
      actionLabel: on ? Strings.folderAction : Strings.undo,
      onAction: on
          ? () async {
              final choice = await pickFolder(context, current: null);
              if (choice != null) await db.moveBookmark(widget.slug, choice.id);
            }
          : () => db.toggleBookmark(widget.slug),
    );
  }

  /// The question, its answer and its citations as plain text.
  void _share(QuestionWithAyahs detail) {
    final q = detail.question;
    final refs = [
      for (final a in detail.ayahs) refLong(detail.surahOf(a), a.id),
    ];
    final text = [
      q.questionBn,
      q.answerBn,
      if (refs.isNotEmpty) '${Strings.quranEvidence}: ${refs.join('; ')}',
      '— ${Strings.appName}',
    ].join('\n\n');
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(questionDetailProvider(widget.slug));
    final bookmarked = ref.watch(isBookmarkedProvider(widget.slug)).value;
    final loaded = detail.value;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentFrame(
                child: ScreenHeader(
                  actions: [
                    if (loaded != null)
                      IconButton(
                        onPressed: () => _share(loaded),
                        tooltip: Strings.share,
                        icon: const Icon(IconsaxPlusLinear.send_2),
                      ),
                    IconButton(
                      onPressed: _toggleBookmark,
                      tooltip: Strings.bookmark,
                      isSelected: bookmarked ?? false,
                      icon: const Icon(IconsaxPlusLinear.archive_1),
                      selectedIcon: const Icon(IconsaxPlusBold.archive_1),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AsyncBody(
                value: detail,
                data: (detail) => detail == null
                    ? Padding(
                        padding: const EdgeInsets.all(Space.gutter),
                        child: Text(
                          Strings.notFound,
                          style: AppText.of(context).section,
                        ),
                      )
                    : ContentFrame(child: _content(context, detail)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, QuestionWithAyahs detail) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final q = detail.question;
    final index = ref.watch(questionIndexProvider).value;
    final category = index?.categories[q.category];
    final next = index?.nextInCategory(q);
    final related =
        index?.related(q, exclude: {?next?.slug}) ?? const <Question>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (category != null)
            Row(
              children: [
                CategoryIcon(category.id, size: 14, color: c.fg3),
                const SizedBox(width: 6),
                Flexible(child: Text(category.nameBn, style: t.label)),
              ],
            ),
          const SizedBox(height: 10),
          Text(q.questionBn, style: t.questionTitle),
          const SizedBox(height: 28),
          Text(Strings.compiledAnswer, style: t.label),
          const SizedBox(height: 8),
          Text(q.answerBn, style: t.answer),
          // A "not in the Qur'an" answer has nothing to cite.
          if (detail.ayahs.isNotEmpty) ..._evidence(context, detail),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 28),
            SectionTitle(Strings.relatedQuestions),
            const SizedBox(height: 4),
            for (final r in related)
              QuestionTile(
                icon: CategoryIcon(r.category),
                title: r.questionBn,
                meta: refsSummary(index!.citationsOf(r)),
                onTap: () => context.openQuestion(r.slug),
                inset: 0,
              ),
          ],
          if (next != null) ...[
            const SizedBox(height: 24),
            _NextQuestion(
              question: next,
              onTap: () => context.replaceQuestion(next.slug),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _evidence(BuildContext context, QuestionWithAyahs detail) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return [
      // With one or two ayat the cards follow right below; the jump row
      // would only repeat the header.
      if (detail.ayahs.length >= 3) ...[
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(Strings.evidence, style: t.meta),
            for (final a in detail.ayahs)
              RefPill(label: refShort(a.id), onTap: () => _scrollTo(a.id)),
          ],
        ),
      ],
      const SizedBox(height: 28),
      Row(
        children: [
          Icon(IconsaxPlusLinear.book_1, size: 18, color: c.highlight),
          const SizedBox(width: 8),
          Expanded(child: Text(Strings.quranEvidence, style: t.section)),
          Text(Strings.ayahCount(bnDigits(detail.ayahs.length)), style: t.meta),
        ],
      ),
      for (final a in detail.ayahs) ...[
        const SizedBox(height: 12),
        AyahCard(
          key: _cardKeys.putIfAbsent(a.id, GlobalKey.new),
          ayah: a,
          surah: detail.surahOf(a),
        ),
      ],
    ];
  }
}

/// The next question in the same topic, for reading straight through.
class _NextQuestion extends StatelessWidget {
  const _NextQuestion({required this.question, required this.onTap});

  final Question question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(Space.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Strings.nextQuestion, style: t.label),
                    const SizedBox(height: 6),
                    Text(
                      question.questionBn,
                      style: t.rowTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(IconsaxPlusLinear.arrow_right_3, size: 22, color: c.fg2),
            ],
          ),
        ),
      ),
    );
  }
}
