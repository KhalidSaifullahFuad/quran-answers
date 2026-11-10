import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/content_db.dart';
import '../../core/db/content_search.dart';
import '../../core/db/database_providers.dart';
import '../../core/db/user_db.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/app_header.dart';
import '../../shared/empty_state.dart';
import '../../shared/ayah_card.dart';
import '../../shared/navigation.dart';
import '../../shared/references.dart';
import '../../shared/search_highlight.dart';
import '../../shared/widgets.dart';
import '../questions/question_providers.dart';
import '../surahs/surahs_screen.dart';

/// One search: the text, and how many verses to fetch.
typedef SearchRequest = ({String query, int ayahLimit});

/// Verses fetched per page; "show more" adds another page.
const searchAyahPage = 50;

/// Questions listed before "show all".
const searchQuestionPreview = 5;

/// Results for one request. Auto-disposed, so only the one on screen is kept.
final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, SearchRequest>((ref, request) async {
      final db = await ref.watch(contentDatabaseProvider.future);
      return db.search(request.query, ayahLimit: request.ayahLimit);
    });

/// The last few queries, newest first.
final recentSearchesProvider = StreamProvider.autoDispose<List<String>>((
  ref,
) async* {
  final db = await ref.watch(userDatabaseProvider.future);
  yield* db.watchRecentSearches();
});

/// Which results a text search shows.
enum SearchTab { all, questions, ayat }

/// Search across surahs, questions and the whole mushaf, or jump to a verse
/// by reference.
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
  int _ayahLimit = searchAyahPage;
  bool _allQuestions = false;
  SearchTab _tab = SearchTab.all;

  /// Held from the start: [dispose] can no longer read providers.
  late final Future<UserDatabase> _userDb;

  /// The last results that finished loading, and the query they are for.
  /// Shown while the next query runs, so the list does not blank out on every
  /// keystroke.
  SearchResults? _shown;
  String? _shownQuery;

  SearchRequest get _request => (query: _query, ayahLimit: _ayahLimit);

  @override
  void initState() {
    super.initState();
    _userDb = ref.read(userDatabaseProvider.future);
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _controller.text = initial;
      _query = initial;
    }
  }

  @override
  void dispose() {
    _remember();
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the current query in recent searches, if it found anything.
  ///
  /// Called when the user commits to it: submitting, opening a result, or
  /// leaving the screen. Not on every keystroke, or half-typed words would
  /// crowd out the real queries.
  void _remember() {
    final query = _query;
    final shown = _shown;
    if (query.isEmpty || _shownQuery != query || shown == null) return;
    if (shown.isEmpty) return;
    unawaited(_userDb.then((db) => db.addRecentSearch(query)));
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
      _ayahLimit = searchAyahPage;
      _allQuestions = false;
      _tab = SearchTab.all;
      if (query.isEmpty) {
        _shown = null;
        _shownQuery = null;
      }
    });
  }

  void _onSubmitted(String text) {
    _setQuery(text);
    _remember();
  }

  /// Puts [query] in the field, cursor at the end.
  void _fill(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  /// Fills the field with an example or a recent query and searches it.
  void _pick(String query) {
    _fill(query);
    _setQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    var loading = false;
    if (_query.isNotEmpty) {
      final value = ref.watch(searchResultsProvider(_request));
      if (value case AsyncData(:final value)) {
        _shown = value;
        _shownQuery = _query;
      }
      loading = value.isLoading;
    }

    final Widget body;
    if (_query.isEmpty) {
      body = _Examples(onPick: _pick, onEdit: _fill);
    } else if (_shown == null) {
      body = AsyncBody(
        value: ref.watch(searchResultsProvider(_request)),
        data: (_) => const SizedBox.shrink(),
      );
    } else {
      body = _Results(
        results: _shown!,
        tab: _tab,
        onTab: (t) => setState(() => _tab = t),
        allQuestions: _allQuestions,
        onShowAllQuestions: () => setState(() => _allQuestions = true),
        // Asks for the next page only once the current one is on screen.
        onShowMoreAyat: loading
            ? null
            : () => setState(() => _ayahLimit += searchAyahPage),
        onOpen: _remember,
      );
    }

    return AppPage(
      header: AppHeader(child: _field()),
      body: Stack(
        children: [
          Positioned.fill(child: body),
          // Old results stay up while the next query runs; this says so.
          if (loading && _shown != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.of(context).fg3,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _field() => AppSearchField(
    controller: _controller,
    hint: Strings.searchHint,
    autofocus: true,
    onChanged: _onChanged,
    onSubmitted: _onSubmitted,
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
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.belowHeader,
          Space.gutter,
          0,
        ),
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

/// The empty state: recent queries, then what can be searched.
class _Examples extends ConsumerWidget {
  const _Examples({required this.onPick, required this.onEdit});

  /// Searches the text.
  final ValueChanged<String> onPick;

  /// Puts the text in the field without searching.
  final ValueChanged<String> onEdit;

  Future<void> _clear(WidgetRef ref) async {
    final db = await ref.read(userDatabaseProvider.future);
    await db.clearRecentSearches();
  }

  static const _guideIcons = [
    IconsaxPlusLinear.message_text,
    IconsaxPlusLinear.translate,
    IconsaxPlusLinear.book_1,
    IconsaxPlusLinear.export_3,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppText.of(context);
    final c = AppColors.of(context);
    final recent = ref.watch(recentSearchesProvider).value ?? const [];
    return ContentFrame(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.belowHeader,
          Space.gutter,
          24,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recent.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(Strings.recentSearches, style: t.section),
                    ),
                    IconButton(
                      onPressed: () => _clear(ref),
                      tooltip: Strings.clearRecentSearches,
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      color: c.fg3,
                      icon: const Icon(IconsaxPlusLinear.trash),
                    ),
                  ],
                ),
                for (final q in recent)
                  _RecentRow(
                    query: q,
                    onTap: () => onPick(q),
                    onEdit: () => onEdit(q),
                  ),
                const SizedBox(height: 24),
              ],
              Text(Strings.searchGuideTitle, style: t.section),
              const SizedBox(height: 12),
              for (final (i, g) in Strings.searchGuide.indexed) ...[
                _GuideCard(
                  icon: _guideIcons[i],
                  title: g.title,
                  hint: g.hint,
                  example: g.example,
                  onTap: () => onPick(g.example),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A recent query: tap searches it, the arrow puts it in the field to edit.
class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.query,
    required this.onTap,
    required this.onEdit,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(IconsaxPlusLinear.clock, size: 20, color: c.fg3),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.rowTitle.copyWith(
                  fontWeight: FontWeight.w400,
                  fontFamilyFallback: [...Fonts.latinFallback, Fonts.arabic],
                ),
              ),
            ),
            IconButton(
              onPressed: onEdit,
              tooltip: Strings.editRecentSearch,
              color: c.fg3,
              iconSize: 18,
              // An up-left arrow: the text goes up into the field.
              icon: Transform.rotate(
                angle: -math.pi / 4,
                child: const Icon(IconsaxPlusLinear.arrow_up_1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One way to search, with an example that runs it.
class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.example,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String example;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final arabic = example.runes.any((r) => r >= 0x0600 && r <= 0x06FF);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: c.fg2),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.rowTitle),
                    const SizedBox(height: 2),
                    Text(hint, style: t.meta.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                example,
                style: arabic
                    ? t.arabic.copyWith(fontSize: 18, color: c.fg2, height: 1.4)
                    : t.meta.copyWith(fontSize: 15, color: c.fg2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// সব / প্রশ্ন / আয়াত, a grey pill on the selected one.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.onTab});

  final SearchTab tab;
  final ValueChanged<SearchTab> onTab;

  static const _labels = {
    SearchTab.all: Strings.searchTabAll,
    SearchTab.questions: Strings.searchQuestions,
    SearchTab.ayat: Strings.searchAyat,
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.track,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          for (final e in _labels.entries)
            Expanded(
              child: Semantics(
                selected: e.key == tab,
                button: true,
                child: Material(
                  color: e.key == tab ? c.selected : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                  child: InkWell(
                    onTap: () => onTab(e.key),
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          e.value,
                          style: t.meta.copyWith(
                            fontSize: 14,
                            color: e.key == tab ? c.fg1 : c.fg2,
                            fontWeight: e.key == tab
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.results,
    required this.tab,
    required this.onTab,
    required this.allQuestions,
    required this.onShowAllQuestions,
    required this.onShowMoreAyat,
    required this.onOpen,
  });

  final SearchResults results;
  final SearchTab tab;
  final ValueChanged<SearchTab> onTab;

  /// Whether every matching question is listed, not just the first few.
  final bool allQuestions;
  final VoidCallback onShowAllQuestions;

  /// Null while the next page is loading.
  final VoidCallback? onShowMoreAyat;

  /// Called before a result is opened, so the query can be remembered.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = results;
    if (r.tooShort) return const _Message(Strings.searchTypeMore);
    if (r.ref case final address? when r.refAyah == null) {
      return _Message(
        Strings.noSuchAyah(bnDigits(address.surah), bnDigits(address.ayah)),
      );
    }
    if (r.isEmpty) {
      return const EmptyState(
        icon: IconsaxPlusBold.search_normal_1,
        title: Strings.noResults,
        message: Strings.noResultsHint,
      );
    }

    final c = AppColors.of(context);
    final t = AppText.of(context);
    final index = ref.watch(questionIndexProvider).value;
    final isRef = r.refAyah != null;
    // Tabs only for a text search; a reference has one verse to show.
    final tab = isRef ? SearchTab.all : this.tab;
    final questions = isRef ? r.citingRef : r.questions;
    final shownQuestions = allQuestions || isRef || tab == SearchTab.questions
        ? questions
        : questions.take(searchQuestionPreview).toList();
    final terms = r.terms;
    // Matches are weight, not colour: green is kept for the Qur'an itself.
    final hit = TextStyle(fontWeight: FontWeight.w700, color: c.fg1);

    // Sections stack with a 28dp gap; the first sits 8dp under the header
    // gap, or flush when it is a verse card.
    final children = <Widget>[];
    void section(List<Widget> widgets, {double firstGap = 8}) {
      children
        ..add(SizedBox(height: children.isEmpty ? firstGap : 28))
        ..addAll(widgets);
    }

    if (r.relaxed) {
      section([
        Text(Strings.searchRelaxed, style: t.meta.copyWith(fontSize: 13)),
      ], firstGap: 0);
    }
    if (r.refAyah case final ayah?) {
      section([
        AyahCard(ayah: ayah, surah: r.surahs[ayah.surah]!),
      ], firstGap: 0);
    }
    if (tab == SearchTab.all && r.matchedSurahs.isNotEmpty) {
      section([
        const SectionTitle(Strings.searchSurahs),
        const SizedBox(height: 4),
        for (final s in r.matchedSurahs)
          SurahRow(
            surah: s,
            padding: const EdgeInsets.symmetric(vertical: 10),
            onTap: () {
              onOpen();
              context.openSurah(s.number);
            },
          ),
      ]);
    }
    if (tab != SearchTab.ayat && questions.isNotEmpty) {
      section([
        SectionTitle(
          isRef ? Strings.citingThisAyah : Strings.searchQuestions,
          trailing: Strings.questionCount(bnDigits(questions.length)),
        ),
        const SizedBox(height: 4),
        for (final q in shownQuestions)
          _QuestionRow(
            question: q,
            meta: _questionMeta(q, index, r.surahs),
            terms: terms,
            hit: hit,
            onTap: () {
              onOpen();
              context.openQuestion(q.slug);
            },
          ),
        if (shownQuestions.length < questions.length)
          _MoreLink(
            label: Strings.showAllQuestions(bnDigits(questions.length)),
            onTap: onShowAllQuestions,
          ),
      ]);
    }
    if (tab != SearchTab.questions && r.ayahs.isNotEmpty) {
      final remaining = r.ayahTotal - r.ayahs.length;
      section([
        SectionTitle(
          Strings.searchAyat,
          trailing: Strings.searchAyatInTranslation,
        ),
        for (final a in r.ayahs)
          _AyahRow(
            ayah: a,
            surah: r.surahs[a.surah]!,
            terms: terms,
            hit: hit,
            onTap: () {
              onOpen();
              context.openAyah(a.surah, a.ayah);
            },
          ),
        if (remaining > 0) ...[
          const SizedBox(height: 4),
          _MoreLink(
            label: Strings.showMoreAyat(
              bnDigits(remaining.clamp(0, searchAyahPage)),
            ),
            onTap: onShowMoreAyat,
          ),
        ],
      ]);
    }
    if (children.isEmpty) {
      // A tab with nothing in it.
      section([
        Text(Strings.noResults, style: t.meta.copyWith(fontSize: 14)),
      ], firstGap: 0);
    }

    final list = ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        isRef ? Space.belowHeader : 16,
        Space.gutter,
        36,
      ),
      children: [for (final child in children) ContentFrame(child: child)],
    );
    if (isRef) return list;
    return Column(
      children: [
        ContentFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.belowHeader,
              Space.gutter,
              0,
            ),
            child: _TabBar(tab: tab, onTab: onTab),
          ),
        ),
        Expanded(child: list),
      ],
    );
  }

  /// `At-Tawbah ৯:৩৬`: the first verse the answer cites, else its category.
  static String _questionMeta(
    Question q,
    QuestionIndex? index,
    Map<int, Surah> surahs,
  ) {
    final cited = index?.citationsOf(q) ?? const <int>[];
    if (cited.isEmpty) return index?.categories[q.category]?.nameBn ?? '';
    final surah = surahs[surahOfAyahId(cited.first)];
    final ref = refShort(cited.first);
    return surah == null ? ref : '${surahLabel(surah)} $ref';
  }
}

/// A matched question: its title with the match in bold, and where it cites.
class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.question,
    required this.meta,
    required this.terms,
    required this.hit,
    required this.onTap,
  });

  final Question question;
  final String meta;
  final SearchTerms? terms;
  final TextStyle hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                highlightSpan(question.questionBn, terms, hit),
                style: t.rowTitle.copyWith(fontWeight: FontWeight.w400),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(meta, style: t.meta.copyWith(fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A matched verse: its citation in a pill, then two lines of translation.
class _AyahRow extends StatelessWidget {
  const _AyahRow({
    required this.ayah,
    required this.surah,
    required this.terms,
    required this.hit,
    required this.onTap,
  });

  final Ayah ayah;
  final Surah surah;
  final SearchTerms? terms;
  final TextStyle hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    // Starts a few words before the first match, so it is inside two lines.
    final excerpt = terms == null
        ? null
        : snippetSpan(ayah.translationBn, terms!, hit, before: 3, after: 30);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.track,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconsaxPlusBold.book_1, size: 14, color: c.fg1),
                    const SizedBox(width: 6),
                    Text(
                      refLong(surah, ayah.id),
                      style: t.meta.copyWith(
                        fontSize: 13,
                        color: c.fg1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                excerpt ?? TextSpan(text: ayah.translationBn),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.meta.copyWith(fontSize: 14, color: c.fg2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A text link closing a section: "show all", "show more".
class _MoreLink extends StatelessWidget {
  const _MoreLink({required this.label, required this.onTap});

  final String label;

  /// Null shows the link disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          // The 48dp touch minimum, however short the label.
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text(
                label,
                style: onTap == null
                    ? t.link.copyWith(color: AppColors.of(context).fg3)
                    : t.link,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
