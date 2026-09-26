import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  const SearchScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);

    if (_query.isNotEmpty) {
      final value = ref.watch(searchResultsProvider(_query));
      if (value case AsyncData(:final value)) _shown = value;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ContentFrame(
              child: SizedBox(
                height: Space.headerHeight,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: Space.gutter),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: Strings.back,
                        icon: const Icon(Icons.chevron_left_rounded, size: 30),
                      ),
                      Expanded(child: _field(c, t)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? _Message(Strings.searchPrompt)
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

  Widget _field(AppColors c, AppText t) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => TextField(
        controller: _controller,
        autofocus: true,
        onChanged: _onChanged,
        onSubmitted: _setQuery,
        textInputAction: TextInputAction.search,
        // Queries may be Arabic: Noto Sans Bengali has no Arabic glyphs, so
        // name a fallback rather than trust the platform's.
        style: t.meta.copyWith(
          fontSize: 15,
          color: c.fg1,
          fontFamilyFallback: [...Fonts.latinFallback, Fonts.arabic],
        ),
        cursorColor: c.fg2,
        decoration: InputDecoration(
          hintText: Strings.searchHint,
          hintStyle: t.meta.copyWith(fontSize: 14, color: c.fg3),
          filled: true,
          fillColor: c.track,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.fg2),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: Strings.clearSearch,
                  icon: Icon(Icons.close_rounded, size: 18, color: c.fg2),
                  onPressed: () {
                    _controller.clear();
                    _setQuery('');
                  },
                ),
        ),
      ),
    );
  }
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
                icon: categoryIcon(q.category),
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
