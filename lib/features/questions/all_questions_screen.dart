import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/content_db.dart';
import '../../core/strings.dart';
import '../../core/text/normalize.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/widgets.dart';
import 'question_providers.dart';

/// The questions tab: every question in authored order, narrowed by a
/// category chip and by words typed into the field.
///
/// The filter runs in memory over question and answer text. It goes through
/// [normalizeForSearch], the same normalizer as the database search, so the
/// two never disagree about what matches.
class AllQuestionsScreen extends ConsumerStatefulWidget {
  const AllQuestionsScreen({super.key});

  @override
  ConsumerState<AllQuestionsScreen> createState() => _AllQuestionsScreenState();
}

class _AllQuestionsScreenState extends ConsumerState<AllQuestionsScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  /// The category shown, or null for all.
  String? _category;

  /// The normalized filter; empty shows everything.
  String _query = '';

  /// Normalized question + answer per slug, built once per question set.
  Map<String, String> _haystacks = const {};
  List<Question>? _indexed;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 150),
      () => setState(() => _query = normalizeForSearch(text.trim())),
    );
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  /// Normalized text per slug, rebuilt only when the question set changes.
  Map<String, String> _haystacksFor(List<Question> questions) {
    if (!identical(_indexed, questions)) {
      _indexed = questions;
      _haystacks = {
        for (final q in questions)
          q.slug: normalizeForSearch('${q.questionBn} ${q.answerBn}'),
      };
    }
    return _haystacks;
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(questionIndexProvider);
    final t = AppText.of(context);
    return Scaffold(
      body: SafeArea(
        child: AsyncBody(
          value: index,
          data: (index) {
            final haystacks = _haystacksFor(index.questions);
            final category = _category;
            final questions = [
              for (final q
                  in category == null
                      ? index.questions
                      : index.inCategory(category))
                if (_query.isEmpty || haystacks[q.slug]!.contains(_query)) q,
            ];
            // Header, field and chips stay put; only the questions scroll,
            // so the filter is in reach wherever the reader is in the list.
            return Column(
              children: [
                ContentFrame(
                  child: ScreenHeader(
                    title: Strings.allQuestions,
                    showBack: false,
                    actions: [
                      // Plain meta text, padded to end on the gutter like the
                      // category screen's count.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          Strings.questionCount(bnDigits(questions.length)),
                          style: t.meta.copyWith(fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
                ContentFrame(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      8,
                      Space.gutter,
                      0,
                    ),
                    child: AppSearchField(
                      controller: _controller,
                      hint: Strings.filterQuestionsHint,
                      onChanged: _onChanged,
                      onClear: _clear,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ContentFrame(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.gutter,
                    ),
                    child: Row(
                      children: [
                        TopicChip(
                          label: Strings.all,
                          icon: const Icon(IconsaxPlusLinear.task_square),
                          selected: category == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        for (final cat in index.categories.values) ...[
                          const SizedBox(width: 8),
                          TopicChip(
                            label: cat.nameBn,
                            icon: CategoryIcon(cat.id),
                            selected: category == cat.id,
                            onTap: () => setState(() => _category = cat.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      if (questions.isEmpty)
                        ContentFrame(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Space.gutter,
                              14,
                              Space.gutter,
                              0,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Strings.noResults,
                                    style: t.meta.copyWith(fontSize: 14),
                                  ),
                                  if (_controller.text.trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    TopicChip(
                                      label: Strings.searchWholeQuran,
                                      icon: const Icon(
                                        IconsaxPlusLinear.search_normal_1,
                                      ),
                                      onTap: () => context.openSearch(
                                        query: _controller.text.trim(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      for (final q in questions)
                        ContentFrame(
                          child: QuestionTile(
                            icon: CategoryIcon(q.category),
                            title: q.questionBn,
                            // Inside one category its name would repeat.
                            meta: category == null
                                ? index.rowMeta(q)
                                : refsSummary(index.citationsOf(q)),
                            onTap: () => context.openQuestion(q.slug),
                          ),
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
