import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

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
import '../questions/question_providers.dart';
import '../surahs/surahs_screen.dart';

typedef AyahAddress = ({int surah, int ayah});

/// Everything the ayah screen shows, read in one go.
class AyahPage {
  const AyahPage({
    required this.surah,
    required this.ayah,
    required this.before,
    required this.after,
    required this.citing,
    required this.previous,
    required this.next,
  });

  final Surah surah;
  final Ayah ayah;

  /// Neighbouring verses of the same surah, in order.
  final List<Ayah> before;
  final List<Ayah> after;

  /// Questions that cite this verse as evidence.
  final List<Question> citing;

  /// The verse before and after in mushaf order, crossing into the adjacent
  /// surah at either end. Null only at 1:1 and 114:6.
  final AyahAddress? previous;
  final AyahAddress? next;
}

/// Null when the address names no verse, e.g. a stale link.
final ayahPageProvider = FutureProvider.family<AyahPage?, AyahAddress>((
  ref,
  address,
) async {
  final db = await ref.watch(contentDatabaseProvider.future);
  final (surah, ayah) = await (
    db.surah(address.surah),
    db.ayahAt(address.surah, address.ayah),
  ).wait;
  if (surah == null || ayah == null) return null;

  final window = await db.ayahWindow(address.surah, address.ayah);
  final citing = await db.questionsCiting(address.surah, address.ayah);

  AyahAddress? previous;
  if (ayah.ayah > 1) {
    previous = (surah: surah.number, ayah: ayah.ayah - 1);
  } else if (surah.number > 1) {
    final prior = await db.surah(surah.number - 1);
    if (prior != null) {
      previous = (surah: prior.number, ayah: prior.ayahCount);
    }
  }
  final AyahAddress? next = ayah.ayah < surah.ayahCount
      ? (surah: surah.number, ayah: ayah.ayah + 1)
      : surah.number < 114
      ? (surah: surah.number + 1, ayah: 1)
      : null;

  return AyahPage(
    surah: surah,
    ayah: ayah,
    before: [
      for (final a in window)
        if (a.ayah < ayah.ayah) a,
    ],
    after: [
      for (final a in window)
        if (a.ayah > ayah.ayah) a,
    ],
    citing: citing,
    previous: previous,
    next: next,
  );
});

/// One verse, whole, with the verses around it and the questions it answers.
///
/// Context verses are there so a reader can check that a cited ayah is not
/// being read out of its passage; they are set quieter than the verse itself.
class AyahScreen extends ConsumerWidget {
  const AyahScreen({super.key, required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(ayahPageProvider((surah: surah, ayah: ayah)));
    final t = AppText.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentFrame(
                child: ScreenHeader(
                  title: page.value == null
                      ? null
                      : refLong(page.value!.surah, page.value!.ayah.id),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AsyncBody(
                value: page,
                data: (page) => page == null
                    ? Padding(
                        padding: const EdgeInsets.all(Space.gutter),
                        child: Text(
                          Strings.noSuchAyah(bnDigits(surah), bnDigits(ayah)),
                          style: t.section,
                        ),
                      )
                    : ContentFrame(child: _Body(page: page)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.page});

  final AyahPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppText.of(context);
    final index = ref.watch(questionIndexProvider).value;
    void go(AyahAddress a) => context.replaceAyah(a.surah, a.ayah);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [
              if (page.surah.nameBn.isNotEmpty) page.surah.nameBn,
              surahMeta(page.surah),
            ].join(' · '),
            style: t.meta,
          ),
          const SizedBox(height: 16),
          for (final a in page.before) ...[
            _ContextVerse(
              ayah: a,
              onTap: () => go((surah: a.surah, ayah: a.ayah)),
            ),
            const SizedBox(height: 8),
          ],
          AyahCard(ayah: page.ayah, surah: page.surah, linkToAyah: false),
          for (final a in page.after) ...[
            const SizedBox(height: 8),
            _ContextVerse(
              ayah: a,
              onTap: () => go((surah: a.surah, ayah: a.ayah)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StepButton(
                  label: Strings.previousAyah,
                  target: page.previous,
                  onTap: go,
                  leading: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StepButton(
                  label: Strings.nextAyah,
                  target: page.next,
                  onTap: go,
                  leading: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionTitle(
            Strings.citingThisAyah,
            trailing: page.citing.isEmpty
                ? null
                : Strings.questionCount(bnDigits(page.citing.length)),
          ),
          const SizedBox(height: 4),
          if (page.citing.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(Strings.notCitedYet, style: t.meta),
            ),
          for (final q in page.citing)
            QuestionTile(
              icon: CategoryIcon(q.category),
              title: q.questionBn,
              meta: index?.rowMeta(q) ?? '',
              onTap: () => context.openQuestion(q.slug),
              inset: 0,
            ),
        ],
      ),
    );
  }
}

/// A neighbouring verse, set quieter than the one being read. Tapping it
/// makes it the verse being read.
class _ContextVerse extends StatelessWidget {
  const _ContextVerse({required this.ayah, required this.onTap});

  final Ayah ayah;
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(refShort(ayah.id), style: t.meta),
              const SizedBox(height: 4),
              ArabicText(
                ayah.textUthmani,
                ayah: ayah.ayah,
                style: t.arabic.copyWith(
                  fontSize: t.arabic.fontSize! * .82,
                  color: c.fg2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ayah.translationBn,
                style: t.translation.copyWith(
                  fontSize: t.translation.fontSize! * .9,
                  color: c.fg3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Previous or next verse, with its reference. Disabled at either end of the
/// mushaf.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.target,
    required this.onTap,
    required this.leading,
  });

  final String label;
  final AyahAddress? target;
  final ValueChanged<AyahAddress> onTap;

  /// Chevron before the text (previous) or after it (next).
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final target = this.target;
    final color = target == null ? c.fg4 : c.fg1;
    final text = Flexible(
      child: Column(
        crossAxisAlignment: leading
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: t.pill.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (target != null)
            Text(
              refShort(ayahId(target.surah, target.ayah)),
              style: t.meta.copyWith(fontSize: 12),
            ),
        ],
      ),
    );
    final chevron = Icon(
      leading
          ? IconsaxPlusLinear.arrow_left_1
          : IconsaxPlusLinear.arrow_right_3,
      size: 22,
      color: color,
    );
    return Material(
      color: c.track,
      borderRadius: BorderRadius.circular(Space.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: target == null ? null : () => onTap(target),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: leading
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: leading
                ? [chevron, const SizedBox(width: 4), text]
                : [text, const SizedBox(width: 4), chevron],
          ),
        ),
      ),
    );
  }
}
