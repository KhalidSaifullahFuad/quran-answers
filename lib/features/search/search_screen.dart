import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/content_search.dart';
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

/// Results for one query. Auto-disposed, so only the query on screen is kept.
final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, String>((ref, query) async {
      final db = await ref.watch(contentDatabaseProvider.future);
      return db.search(query);
    });

/// Search across questions and the whole mushaf, or jump to a verse by
/// reference.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  /// Typed in and searched on open, e.g. handed on from the questions tab.
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  /// The last results that finished loading. Shown while the next query runs,
  /// so the list does not blank out on every keystroke.
  SearchResults? _shown;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _controller.text = initial;
      _query = initial;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _setQuery(text));
  }

  void _setQuery(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query == _query) return;
    setState(() {
      _query = query;
      if (query.isEmpty) _shown = null;
    });
  }

  /// Fills the field with an example and searches it at once.
  void _pick(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _setQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    if (_query.isNotEmpty) {
      final value = ref.watch(searchResultsProvider(_query));
      if (value case AsyncData(:final value)) _shown = value;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ContentFrame(child: ScreenHeader(child: _field())),
            Expanded(
              child: _query.isEmpty
                  ? _Examples(onPick: _pick)
                  : _shown == null
                  ? AsyncBody(
                      value: ref.watch(searchResultsProvider(_query)),
                      data: (_) => const SizedBox.shrink(),
                    )
                  : _Results(results: _shown!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field() => AppSearchField(
    controller: _controller,
    hint: Strings.searchHint,
    autofocus: true,
    onChanged: _onChanged,
    onSubmitted: _setQuery,
    onClear: () {
      _controller.clear();
      _setQuery('');
    },
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ContentFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 24, Space.gutter, 0),
        // Full width, or ContentFrame's centering would center a short line.
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            style: AppText.of(context).meta.copyWith(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

/// The empty state: what can be searched, and a few queries to try.
class _Examples extends StatelessWidget {
  const _Examples({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return ContentFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 24, Space.gutter, 0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Strings.searchPrompt, style: t.meta.copyWith(fontSize: 14)),
              const SizedBox(height: 18),
              Text(Strings.searchExamplesLabel, style: t.label),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in Strings.searchExamples)
                    TopicChip(
                      label: q,
                      icon: const Icon(IconsaxPlusLinear.search_normal_1),
                      onTap: () => onPick(q),
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

class _Results extends ConsumerWidget {
  const _Results({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = results;
    if (r.ref case final address? when r.refAyah == null) {
      return _Message(
        Strings.noSuchAyah(bnDigits(address.surah), bnDigits(address.ayah)),
      );
    }
    if (r.isEmpty) return const _Message(Strings.noResults);

    final index = ref.watch(questionIndexProvider).value;
    final questions = r.refAyah == null ? r.questions : r.citingRef;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 36),
      children: [
        for (final child in [
          if (r.refAyah case final ayah?)
            AyahCard(ayah: ayah, surah: r.surahs[ayah.surah]!),
          if (questions.isNotEmpty) ...[
            SizedBox(height: r.refAyah == null ? 8 : 28),
            SectionTitle(
              r.refAyah == null
                  ? Strings.searchQuestions
                  : Strings.citingThisAyah,
              trailing: Strings.questionCount(bnDigits(questions.length)),
            ),
            const SizedBox(height: 4),
            for (final q in questions)
              QuestionTile(
                icon: CategoryIcon(q.category),
                title: q.questionBn,
                meta: index?.rowMeta(q) ?? '',
                onTap: () => context.openQuestion(q.slug),
                inset: 0,
              ),
          ],
          if (r.ayahs.isNotEmpty) ...[
            SizedBox(height: questions.isEmpty ? 8 : 28),
            SectionTitle(
              Strings.searchAyat,
              trailing: Strings.ayahCount(bnDigits(r.ayahTotal)),
            ),
            for (final a in r.ayahs) ...[
              const SizedBox(height: 12),
              AyahCard(ayah: a, surah: r.surahs[a.surah]!),
            ],
            if (r.ayahTotal > r.ayahs.length) ...[
              const SizedBox(height: 16),
              Text(
                Strings.firstOfTotal(
                  bnDigits(r.ayahs.length),
                  bnDigits(r.ayahTotal),
                ),
                style: AppText.of(context).meta,
              ),
            ],
          ],
        ])
          ContentFrame(child: child),
      ],
    );
  }
}
