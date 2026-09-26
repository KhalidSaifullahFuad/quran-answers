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

/// Every category as a card in a two-column grid.
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
                      const gap = 8.0;
                      final width = (constraints.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final c in index.categories.values)
                            SizedBox(
                              width: width,
                              child: _TopicCard(
                                title: c.nameBn,
                                count: index.inCategory(c.id).length,
                                icon: categoryIcon(c.id),
                                onTap: () => context.openCategory(c.id),
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
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
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
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: c.fg1),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.rowTitle.copyWith(fontSize: 14.5, height: 1.35),
                    ),
                    const SizedBox(height: 3),
                    Text(Strings.questionCount(bnDigits(count)), style: t.meta),
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
