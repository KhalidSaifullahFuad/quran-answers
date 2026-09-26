import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/content_db.dart';
import '../../core/db/content_queries.dart';
import '../../core/db/database_providers.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/ayah_card.dart';
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
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            on ? Strings.bookmarked : Strings.unbookmarked,
            textAlign: TextAlign.center,
          ),
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(questionDetailProvider(widget.slug));
    final bookmarked = ref.watch(isBookmarkedProvider(widget.slug)).value;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentFrame(
                child: ScreenHeader(
                  actions: [
                    IconButton(
                      onPressed: _toggleBookmark,
                      tooltip: Strings.bookmark,
                      isSelected: bookmarked ?? false,
                      icon: const Icon(Icons.bookmark_border_rounded),
                      selectedIcon: const Icon(Icons.bookmark_rounded),
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
    final related = [
      for (final other in index?.inCategory(q.category) ?? const <Question>[])
        if (other.slug != q.slug) other,
    ].take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (category != null)
            Row(
              children: [
                Icon(categoryIcon(category.id), size: 14, color: c.fg3),
                const SizedBox(width: 6),
                Text(category.nameBn, style: t.label),
              ],
            ),
          const SizedBox(height: 10),
          Text(q.questionBn, style: t.questionTitle),
          const SizedBox(height: 28),
          Text(Strings.compiledAnswer, style: t.label),
          const SizedBox(height: 12),
          Text(q.answerBn, style: t.answer),
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
          if (_OccurrenceGrid.applies(detail)) ...[
            const SizedBox(height: 28),
            _OccurrenceGrid(detail: detail, onOpen: _scrollTo),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 18, color: c.highlight),
              const SizedBox(width: 8),
              Expanded(child: Text(Strings.quranEvidence, style: t.section)),
              Text(
                Strings.ayahCount(bnDigits(detail.ayahs.length)),
                style: t.meta,
              ),
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
          if (related.isNotEmpty) ...[
            const SizedBox(height: 28),
            SectionTitle(Strings.relatedQuestions),
            const SizedBox(height: 4),
            for (final r in related)
              QuestionTile(
                icon: categoryIcon(r.category),
                title: r.questionBn,
                meta: refsSummary(index!.citationsOf(r)),
                onTap: () => context.openQuestion(r.slug),
                inset: 0,
              ),
          ],
        ],
      ),
    );
  }
}

/// Where the cited ayat sit within their surah, one cell per verse.
///
/// Derived purely from the citations, so it states nothing the content does not:
/// the marked cells are the ayat this answer cites.
class _OccurrenceGrid extends StatelessWidget {
  const _OccurrenceGrid({required this.detail, required this.onOpen});

  final QuestionWithAyahs detail;
  final void Function(int ayahId) onOpen;

  /// Only meaningful for several citations from a single surah.
  static bool applies(QuestionWithAyahs detail) =>
      detail.ayahs.length >= 2 &&
      detail.ayahs.every((a) => a.surah == detail.ayahs.first.surah);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final surah = detail.surahOf(detail.ayahs.first);
    final hits = {for (final a in detail.ayahs) a.ayah};
    // Short surahs get numbered cells; long ones a denser, unlabelled grid.
    final compact = surah.ayahCount > 60;
    final columns = compact ? 19 : 11;
    final cellHeight = compact ? 13.0 : 22.0;
    final gap = compact ? 3.0 : 4.0;
    final sorted = hits.toList()..sort();

    Widget cell(int n) {
      final hit = hits.contains(n);
      final box = Container(
        height: cellHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hit ? c.highlight : c.track,
          borderRadius: BorderRadius.circular(compact ? 3 : Space.radiusCell),
        ),
        child: hit && !compact ? Text(bnDigits(n), style: t.cell) : null,
      );
      if (!hit) return box;
      return Semantics(
        button: true,
        label: refShort(ayahId(surah.number, n)),
        child: GestureDetector(
          onTap: () => onOpen(ayahId(surah.number, n)),
          child: box,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(Space.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Strings.citedPositions,
            style: t.rowTitle.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          for (var row = 0; row * columns < surah.ayahCount; row++) ...[
            if (row > 0) SizedBox(height: gap),
            Row(
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) SizedBox(width: gap),
                  Expanded(
                    child: row * columns + col < surah.ayahCount
                        ? cell(row * columns + col + 1)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '${surahLabel(surah)} · '
            '${Strings.ayatInSurah(bnDigits(surah.ayahCount))} · '
            '${sorted.map(bnDigits).join(', ')}',
            style: t.meta.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
