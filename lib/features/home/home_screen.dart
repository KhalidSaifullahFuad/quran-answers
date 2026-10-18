import 'dart:math' as math;

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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(questionIndexProvider);
    // No top safe area: the header art runs up behind the status bar, and
    // the content is inset by hand instead.
    return Scaffold(
      body: SafeArea(
        top: false,
        child: AsyncBody(
          value: index,
          data: (index) => ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Stack(
                children: [
                  const _HeaderArt(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Home has no back button or title bar above it, so the
                      // wordmark gets room from the status bar.
                      SizedBox(height: MediaQuery.paddingOf(context).top + 12),
                      ContentFrame(
                        child: ScreenHeader(
                          wordmark: true,
                          showBack: false,
                          actions: [
                            IconButton(
                              onPressed: context.openSettings,
                              tooltip: Strings.settings,
                              icon: const Icon(IconsaxPlusLinear.setting_2),
                            ),
                          ],
                        ),
                      ),
                      ContentFrame(child: _Body(index: index)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lantern and Qur'an stand behind the top-right of the header, dark theme
/// only (a night scene reads as a smudge on the paper theme).
///
/// The asset is graded to the dark canvas: its blacks are lifted to exactly
/// #131313 and its lights scaled to 38%, so it has no box edge and the gold
/// wordmark stays the brightest thing. Do not dim it at runtime with black
/// or opacity; that pushes the ground below the canvas again. The short
/// fades only soften the crop edges.
class _HeaderArt extends StatelessWidget {
  const _HeaderArt();

  /// From the top of the content (below the status bar) to the top of the
  /// search pill: 12 + header 52 + tagline ~23 + gap 18, plus a little that
  /// the opaque pill covers. The scene fits here, so the lantern and the
  /// Qur'an stand both show above the search.
  static const _height = 112.0;

  /// Wide enough that lantern-to-stand (two thirds of the art's height) still
  /// fits in [_height] once the box crops.
  static const _maxWidth = 210.0;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return const SizedBox.shrink();
    }
    final width = math.min(MediaQuery.sizeOf(context).width * .5, _maxWidth);
    final height = MediaQuery.paddingOf(context).top + _height;
    Shader fade(Rect r, Alignment from, Alignment to, double solidFrom) =>
        LinearGradient(
          begin: from,
          end: to,
          colors: const [Colors.transparent, Colors.white],
          stops: [0, solidFrom],
        ).createShader(r);

    return Positioned(
      top: 0,
      right: 0,
      child: IgnorePointer(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) =>
              fade(r, Alignment.centerLeft, Alignment.centerRight, .15),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) =>
                fade(r, Alignment.bottomCenter, Alignment.topCenter, .2),
            child: Image.asset(
              'assets/images/home_hero.webp',
              width: width,
              height: height,
              fit: BoxFit.cover,
              // Crops mostly the empty top (chain, dark wall), keeping the
              // lantern and the stand.
              alignment: const Alignment(0, .4),
              excludeFromSemantics: true,
              // Decoration: if it cannot load, show nothing, not an error.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                  .round(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.index});

  /// Topic chips shown before the link to the topics tab.
  static const _shownTopics = 5;

  final QuestionIndex index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppText.of(context);
    final featured = questionOfTheDay(
      index.questions,
      ref.watch(todayProvider),
    );
    final recent = ref.watch(recentSlugsProvider).value ?? const [];
    final lastRead = recent.map(index.bySlug).nonNulls.take(3).toList();
    final categories = index.categories.values.toList();
    final picks = index.dailyPicks(
      ref.watch(todayProvider),
      exclude: {?featured?.slug, for (final q in lastRead) q.slug},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A subtitle to the wordmark, not a headline: the featured
              // question below is the hero. Pulled up into the header's
              // bottom padding so it reads as one unit with the wordmark;
              // the translate leaves its layout slot, so the gap below grows
              // by the same 10dp (18 + 10 = 28dp above the search).
              Transform.translate(
                offset: const Offset(0, -10),
                child: Text(Strings.tagline, style: t.tagline),
              ),
              const SizedBox(height: 18),
              SearchFieldButton(
                hint: Strings.searchHint,
                onTap: context.openSearch,
              ),
            ],
          ),
        ),
        if (featured != null) ...[
          const SizedBox(height: 20),
          _FeaturedCard(question: featured),
        ],
        if (lastRead.isNotEmpty) ...[
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: SectionTitle(
              Strings.lastRead,
              actionLabel: Strings.seeAll,
              onAction: context.openHistory,
            ),
          ),
          const SizedBox(height: 4),
          for (final q in lastRead)
            QuestionTile(
              icon: CategoryIcon(q.category),
              title: q.questionBn,
              meta: index.rowMeta(q),
              onTap: () => context.openQuestion(q.slug),
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
              // A handful of shortcuts; the topics tab holds them all.
              for (final c in categories.take(_shownTopics)) ...[
                TopicChip(
                  label: c.nameBn,
                  icon: CategoryIcon(c.id),
                  onTap: () => context.openCategory(c.id),
                ),
                const SizedBox(width: 8),
              ],
              if (categories.length > _shownTopics)
                TopicChip(
                  label: Strings.allTopics,
                  icon: const Icon(IconsaxPlusLinear.category),
                  onTap: () => context.goTab(AppTab.topics),
                ),
            ],
          ),
        ),
        if (picks.isNotEmpty) ...[
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: SectionTitle(
              Strings.startReading,
              actionLabel: Strings.seeAll,
              onAction: () => context.goTab(AppTab.questions),
            ),
          ),
          const SizedBox(height: 4),
          for (final q in picks)
            QuestionTile(
              icon: CategoryIcon(q.category),
              title: q.questionBn,
              meta: index.rowMeta(q),
              onTap: () => context.openQuestion(q.slug),
            ),
        ],
      ],
    );
  }
}

/// Today's question: its first cited ayah, the question, the citation.
///
/// The ayah is shown only when it fits whole in a few lines. A verse is never
/// cut short, so a long one is left to the question screen and only its
/// citation shows here.
class _FeaturedCard extends ConsumerWidget {
  const _FeaturedCard({required this.question});

  /// Longest Uthmani text (in characters) the card shows in full.
  static const _maxAyahLength = 140;

  final Question question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final detail = ref.watch(questionDetailProvider(question.slug)).value;
    final first = detail?.ayahs.firstOrNull;
    final showAyah =
        first != null && first.textUthmani.length <= _maxAyahLength;

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
                      child: Text(
                        Strings.questionOfTheDay,
                        style: t.label.copyWith(color: c.accent),
                      ),
                    ),
                    Text(
                      bnDayMonth(ref.watch(todayProvider)),
                      style: t.meta.copyWith(color: c.fg4),
                    ),
                  ],
                ),
                if (showAyah) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                    decoration: BoxDecoration(
                      // Sits inside a card, so one step up from [evidence].
                      color: c.track,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ArabicText(
                      first.textUthmani,
                      ayah: first.ayah,
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
                                icon: IconsaxPlusLinear.book_1,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(Strings.answerAndEvidence, style: t.link),
                    Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      size: 18,
                      color: c.accent,
                    ),
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
