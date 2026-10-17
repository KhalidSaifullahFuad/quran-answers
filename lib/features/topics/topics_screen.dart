import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import '../questions/question_providers.dart';

/// Every category as a square-ish tile in a two-column grid.
class TopicsScreen extends ConsumerWidget {
  const TopicsScreen({super.key});

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
              const ContentFrame(
                child: ScreenHeader(title: Strings.navTopics, showBack: false),
              ),
              ContentFrame(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    8,
                    Space.gutter,
                    0,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 10.0;
                      final width = (constraints.maxWidth - gap) / 2;
                      final cats = index.categories.values.toList();
                      Widget tile(int i) {
                        final c = cats[i];
                        return _TopicCard(
                          minHeight: width * 0.66,
                          title: c.nameBn,
                          count: index.inCategory(c.id).length,
                          icon: CategoryIcon(c.id),
                          onTap: () => context.openCategory(c.id),
                        );
                      }

                      // Rows rather than a Wrap, so a two-line title
                      // stretches its neighbour to the same height.
                      return Column(
                        children: [
                          for (var i = 0; i < cats.length; i += 2)
                            Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: tile(i)),
                                    const SizedBox(width: gap),
                                    Expanded(
                                      child: i + 1 < cats.length
                                          ? tile(i + 1)
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.minHeight,
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  /// Keeps tiles square-ish; a long title or large text can still grow them.
  final double minHeight;
  final String title;
  final int count;
  final Widget icon;
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
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          // Tight height (minimum or content, whichever is taller) so the
          // Spacer can pin the title to the bottom edge.
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(size: 28, color: c.fg1),
                    child: icon,
                  ),
                  const Spacer(),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: t.rowTitle.copyWith(fontSize: 17, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Strings.questionCount(bnDigits(count)),
                    style: t.meta.copyWith(color: c.fg2, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
