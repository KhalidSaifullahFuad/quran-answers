import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/content_db.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import '../questions/question_providers.dart';

/// The surahs that some question cites, each with how many questions do.
///
/// Not a full surah index: a surah no question cites has nothing to open here.
class SurahsScreen extends ConsumerStatefulWidget {
  const SurahsScreen({super.key});

  @override
  ConsumerState<SurahsScreen> createState() => _SurahsScreenState();
}

class _SurahsScreenState extends ConsumerState<SurahsScreen> {
  /// Most-cited surahs first, rather than mushaf order.
  bool _byCount = false;

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(questionIndexProvider);
    final surahs = ref.watch(surahsProvider);
    final t = AppText.of(context);
    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: index,
          data: (index) => AsyncBody(
            value: surahs,
            data: (surahs) => ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const ContentFrame(
                  child: ScreenHeader(
                    title: Strings.surahsTitle,
                    showBack: false,
                  ),
                ),
                ContentFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.gutter,
                          8,
                          Space.gutter,
                          8,
                        ),
                        child: Text(
                          Strings.surahsIntro,
                          style: t.meta.copyWith(fontSize: 13.5, height: 1.6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.gutter,
                          4,
                          Space.gutter,
                          8,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TopicChip(
                              label: Strings.sortByNumber,
                              icon: const Icon(IconsaxPlusLinear.sort),
                              selected: !_byCount,
                              onTap: () => setState(() => _byCount = false),
                            ),
                            TopicChip(
                              label: Strings.sortByCount,
                              icon: const Icon(IconsaxPlusLinear.chart_2),
                              selected: _byCount,
                              onTap: () => setState(() => _byCount = true),
                            ),
                          ],
                        ),
                      ),
                      for (final MapEntry(key: n, value: count) in _sorted(
                        index.citedSurahs(),
                      ))
                        if (surahs[n] case final surah?)
                          _SurahRow(
                            surah: surah,
                            questionCount: count,
                            onTap: () => context.openSurah(n),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mushaf order, or most-cited first (ties keep mushaf order).
  Iterable<MapEntry<int, int>> _sorted(Map<int, int> cited) => _byCount
      ? (cited.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      : cited.entries;
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.questionCount,
    required this.onTap,
  });

  final Surah surah;
  final int questionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, Space.gutter, 10),
        child: Row(
          children: [
            HexBadge(label: bnDigits(surah.number)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surahLabel(surah),
                    style: t.rowTitle.copyWith(fontSize: 16, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(surahMeta(surah), style: t.meta),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ArabicText(
                  surah.nameAr,
                  style: t.arabic.copyWith(fontSize: 19, height: 1.9),
                ),
                Text(
                  Strings.questionCount(bnDigits(questionCount)),
                  style: t.meta.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.highlight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// `মাক্কী • ৫৫ আয়াত`.
String surahMeta(Surah surah) {
  final place = switch (surah.revelationPlace) {
    'makkah' => Strings.makki,
    'madinah' => Strings.madani,
    _ => null,
  };
  return [?place, Strings.ayatInSurah(bnDigits(surah.ayahCount))].join(' • ');
}

/// Questions citing one surah.
class SurahQuestionsScreen extends ConsumerWidget {
  const SurahQuestionsScreen({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(questionIndexProvider);
    final surah = ref.watch(surahsProvider).value?[number];
    final t = AppText.of(context);
    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: index,
          data: (index) => ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              ContentFrame(
                child: ScreenHeader(
                  title: surah == null ? null : surahLabel(surah),
                ),
              ),
              ContentFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (surah != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.gutter,
                          8,
                          Space.gutter,
                          10,
                        ),
                        child: Text(
                          '${surahMeta(surah)} · ${Strings.surahQuestionsNote}',
                          style: t.meta.copyWith(fontSize: 13.5, height: 1.6),
                        ),
                      ),
                    for (final q in index.citingSurah(number))
                      QuestionTile(
                        icon: CategoryIcon(q.category),
                        title: q.questionBn,
                        meta: refsSummary(index.citationsOf(q)),
                        onTap: () => context.openQuestion(q.slug),
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
