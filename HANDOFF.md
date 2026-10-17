# Handoff — Quran Answers app

Steps 1–10 of the plan are done. **Next is step 11
(content migration)** — blocked on the user's original `.docx`/`.pdf`.
105 tests passing; `flutter build appbundle --release` builds.

The uncommitted `lib/web_preview*.dart`, `native_opener*.dart` and the edits to
`main.dart` / `database_providers.dart` are a temporary Chrome preview on static
data (not from the step-7 session). Search is not overridden there, so on web
the search screen spins forever. Decide whether to keep or drop it. The user chose
to **keep it, uncommitted**. Its only footprint in tracked files is the
uncommitted diff in `main.dart` (a `kIsWeb` override line + two imports) and
`database_providers.dart` (conditional `native_opener` import); commit around
those hunks.

**Plan + progress checklist: `PLAN.md`** (repo root). Tick steps there as they
land; add a step before starting any new request. The original plan is
`C:\Users\Fuad\.claude\plans\pasted-content-id-1712-want-to-smooth-rossum.md`
(historical; `PLAN.md` supersedes it).

## What this app is

Android-first Flutter app (iOS later). Bengali Q&A about Islam where every
answer is grounded **only** in ayat from the Qur'an. Offline-first, $0/month, no
backend, no accounts, no analytics, and **no LLM in the answer path**.

## Stack

Flutter 3.41.9 / Dart 3.11.5 · Riverpod · Drift + SQLite · FTS5 · go_router ·
Material 3 + own design system.

Two dependency facts that will look wrong but are deliberate:

- `drift` is pinned `>=2.34.0 <2.35.0`. Drift 2.35+ needs `meta ^1.18.3`; the
  Flutter 3.41.9 SDK pins `meta 1.17.0`. Do not "fix" this.
- `sqlite3_flutter_libs` is **not** used — it is end-of-life (`0.6.0+eol`,
  "no longer does anything"). `sqlite3` 3.x bundles SQLite via Dart hooks, and
  its default compile defines already include `SQLITE_ENABLE_FTS5`.

## Data pipeline

```
content/quran.json      fetched once from api.quran.com  (BUILD TIME ONLY)
content/questions.json  authored by hand, reviewed
        │  dart run tool/build_db.dart
        ▼
assets/db/content.db    10.7 MB, ships in the APK, read-only
        │  copied out on first launch (sha256 marker decides)
        ▼
<app dir>/content.db  +  <app dir>/user.db (bookmarks, history)
```

The shipped app makes **zero network calls**.

### Rules that must not be broken

1. **Arabic is never typed or pasted.** `questions.json` carries
   `"refs": ["54:15"]` only; Arabic and the Bengali translation are resolved
   from the mushaf at build time. The original source document has
   PDF-corrupted Arabic, and this rule is what keeps it out of the app.
2. **Two databases.** `content.db` is replaced wholesale on app update;
   `user.db` is never touched by that.
3. **Questions are keyed by slug**, not by an integer id. Integer ids get
   reassigned on every content rebuild and would repoint saved bookmarks at
   different questions.
4. **`lib/core/text/normalize.dart` is shared** by the build tool and the app.
   The FTS index is built with it and queries are normalized with it; if the two
   diverge, search silently returns nothing instead of failing.
5. **An answer whose cited ayah does not support it does not ship** without the
   author's explicit say-so. `status: "draft"` in `questions.json` excludes an
   entry from the build.

## Commands

```bash
cd D:/DEVELOPMENT/HOME_WORKSPACE/quran-answers

flutter analyze
flutter test                          # 98 tests, all passing

dart run tool/validate_content.dart   # check content before building
dart run tool/build_db.dart           # rebuild assets/db/content.db + .version
dart run build_runner build           # after changing any Drift table
dart run tool/fetch_quran.dart        # re-fetch the mushaf (only to change translation)
```

`dart format` after edits. Rebuild the DB after any `questions.json` change.

## Layout

```
lib/core/text/normalize.dart      Arabic + Bengali search normalization
lib/core/db/content_tables.dart   Drift schema, content (read-only)
lib/core/db/content_db.dart       DB class, ayahId(), FTS table DDL + tokenizer
lib/core/db/content_queries.dart  reads: question detail, ayah windows, etc.
lib/core/db/content_search.dart   parseAyahRef, ftsMatchExpression, search()
lib/core/db/content_store.dart    copies the asset out of the bundle
lib/core/db/user_tables.dart      bookmarks, ayah_bookmarks, folders, reading_history
lib/core/db/user_db.dart          schema 2 + migration; bookmarks, verse bookmarks, folders, history
lib/core/db/database_providers.dart  Riverpod wiring
lib/app.dart                      MaterialApp.router + go_router routes
lib/core/theme/                   AppColors / AppText ThemeExtensions (design tokens)
lib/core/strings.dart             UI chrome labels only — never content
lib/core/text/numerals.dart       Bengali/Arabic digits, ayah end mark, Bengali date
lib/shared/                       design primitives (widgets.dart), citation labels, AyahCard
lib/shared/navigation.dart        AppTab, bottom bar, tab-relative openQuestion/Category/Surah
lib/features/                     home, topics, surahs, saved (tabs); category, surah, question, search, ayah, settings, about
tool/                             fetch_quran, validate_content, build_db
test/core/                        7 test files (DB, queries, search, normalize, store)
test/widget_test.dart             app boot, question detail, tabs, search, ayah, settings, about
test/settings_test.dart           settings persistence + clamping
```

## Gotchas already paid for — do not rediscover

- **Bengali needs prefix search.** 54:15 says নিদর্শন**রূপে**; an exact-token
  query for নিদর্শন misses it. Suffixes attach directly to words, so the search
  layer must append `*`.
- **Bengali combining marks are declared as FTS `tokenchars`.** Without that,
  `unicode61` treats vowel signs as separators and shreds কোন into ক and ন.
- **`remove_diacritics 0`** is deliberate — `normalize.dart` owns diacritic
  policy per script.
- **The definite article is not stripped**, so a bare query will not reach an
  ayah carrying `ال`. That is the search layer's problem, by decision.
- **DateTime is stored as ISO text** (`build.yaml`), not unix seconds. Second
  granularity made "most recent first" unreliable.
- **Widget tests:** resolve Riverpod providers inside `tester.runAsync()`
  *before* `pumpWidget`. A future started during a build belongs to the fake
  clock zone and never advances — it hangs rather than fails. Also override
  `databaseOpenerProvider` with `NativeDatabase.new` (no background isolate),
  and never use `pumpAndSettle` against the indeterminate spinner.
- **Search** (`content_search.dart`): a query that parses as `54:15`
  (Bengali/Arabic digits; colon, space, dot or Bengali visarga as separator)
  skips FTS and goes to `ayahAt` + `questionsCiting`. Otherwise every word
  becomes a quoted prefix term, ANDed; quoting means user input is never FTS
  syntax. A bare Arabic word also tries the article-prefixed form, so qamar
  finds al-qamar. Verse hits are capped at 50 with a separate total. Other
  attached Arabic prefixes (wa, fa, bi, li) are **not** handled.
- **User DB schema 2** adds `ayah_bookmarks` (keyed by ayah id, which is
  stable across content releases) and `folders`, plus nullable `folder_id` on
  both bookmark tables. One folder per item. No SQL foreign keys (they need a
  per-connection pragma); `deleteFolder` unfiles its items in a transaction.
  `onUpgrade` from 1 is tested against the exact v1 DDL.
- **Every new user-DB stream provider a screen watches must be pre-resolved in
  widget tests** (`bookmarksProvider`, `foldersProvider`, `savedAyahsProvider`,
  `isAyahBookmarkedProvider(id)` for each visible AyahCard), or tearDown hangs.
- **In UI handlers, open sheets/dialogs before awaiting a provider future.**
  Awaiting `userDatabaseProvider.future` first stalls in widget tests (future
  from the real zone) so the sheet never opens. The folder picker captures
  `ProviderScope.containerOf` up front, since filing can remove the row.
- **Auto-dispose providers in widget tests:** `container.listen(...)` must also
  run inside `runAsync`, or the query starts on the fake clock and hangs.
- **Writing Dart via shell heredocs mangles backslashes** and Edit anchors fail
  on lines with RTL comments. Use the Write tool for files with `\u` escapes.

## Step 9 (ayah, settings, about)

- **Ayah screen** `/ayah/:surah/:ayah` (`features/ayah/`): `ayahPageProvider`
  keyed by a `({surah, ayah})` record; 2 context verses either side (quieter
  cards, tap to move), prev/next crossing surah boundaries (`replaceAyah`, so
  back leaves the screen), questions citing it. Every `AyahCard` citation pill
  now opens it (`linkToAyah: false` on the ayah screen itself). The screen
  opens scrolled to the top, so with context the focused verse sits below
  54:13–14; auto-scroll to it if that bothers.
- **Settings** in SharedPreferences (`features/settings/settings_provider.dart`).
  `sharedPreferencesProvider` is loaded in `main` before `runApp` and **must be
  overridden** in every test container (`setMockInitialValues`). Arabic scale
  multiplies `AppText.arabic`; Bengali scale only questionTitle/answer/
  translation, chrome keeps its size. Preview verse is 1:1 read from the DB.
- **About** reads the translation credit from `meta`. Font OFL texts are
  assets now and registered with `LicenseRegistry` (`registerFontLicenses()` in
  `main`), shown via `showLicensePage`.
- **Methodology sheet** (`features/about/methodology_sheet.dart`): info icon
  beside "সংকলিত উত্তর" on every question, plus settings and about. Its five
  points are in `Strings.methodologyPoints` — **written by Claude, the author
  should review the wording.**
- Gear on home header opens settings. `bottomSheetTheme` now uses `c.sheet`
  (fixes the greenish sheet). `TopicChip` label ellipsizes.
- Not built: "same phrase in this surah" on the ayah screen (no phrase data in
  the schema), collections.

## Step 10 (icon, store kit)

- **Icon**: a rub el hizb (۞) outline with a centre disc, scripture green
  `#20C08D` on the dark canvas `#131313`. Adaptive (foreground + background
  colour + Android 13 monochrome) plus legacy square/round PNGs.
- **All graphics are generated** by `flutter test tool/render_assets_test.dart`:
  launcher mipmaps, `store/icon-512.png`, `store/feature-graphic.png`,
  `store/screenshots/*.png` (1080×1920, real app on the real DB). It lives in
  `tool/` so the normal `flutter test` doesn't rewrite assets. **Rerun after
  step 11** — screenshots currently show the 5-question pilot.
- **Splash**: window colour = app canvas per system theme (paper / dark), with
  the Android 12+ system splash on the same colour. No white flash.
- **Label** "Quran Answers" on Android and iOS `CFBundleName`. iOS icons not
  done (iOS later).
- **Release signing** reads `android/key.properties` (gitignored); falls back
  to the debug key if absent. No keystore exists yet — the author must create
  it (`store/README.md` has the commands).
- **Release manifest has no INTERNET permission** (only debug/profile add it),
  which is what the "collects no data" Data-safety answer rests on. Keep it
  that way: adding any network plugin changes the privacy policy.
- `store/`: `listing.md` (Bengali name/short/full description, lengths
  checked), `privacy-policy.md` (EN + BN, needs date + email + hosting),
  `README.md` (build, Data safety and content-rating answers, 12-tester /
  14-day closed-test rule for new accounts).

## After step 10 (visual polish, step 12)

- **No green fill on verses.** The user disliked the green tint behind ayat.
  `AppColors.evidence` is now neutral (= `card`: `#1C1C1C` / `#EBE7DF`); green
  survives only as `highlight` (evidence icon, cited cells). The home
  question-of-the-day snippet sits inside a card, so it uses `c.track`.
- **Icons are Iconsax** (`iconsax_plus`, app.iconsax.io) — no Material
  `Icons.` left in `lib/`. Linear by default, Bold for on/selected states.
  Bookmark = `archive_1` (Iconsax's ribbon). Chevrons are always Linear
  `arrow_left_1` / `arrow_right_3` (Bold draws different shapes). No mosque
  glyph exists; the worship topic uses `moon`.
- Verified: format, analyze and 105 tests clean. No test looks icons up by
  `Icons.*`. Not yet seen on a device.

## Content status

**200 questions (all published after the author's review of 2026-10-10/17),
280 citations, 9 categories** since step 11; rulings are in `PLAN.md` and
`content/source/review-2026-10-09.md`. New entries carry `source` (PDF number)
and a `reviewNote`. An answer ships with no ayah only if marked
`"noAyah": true` (7 do, by the author's ruling). Slugs `ku-NNN` follow the PDF numbering — never renumber
them, bookmarks depend on them. Python run with `-I` ignores
`PYTHONIOENCODING`; use `-X utf8` to print Bengali on Windows.

Before step 11: 5 questions, 11 citations, 3 categories. Translation 163, Sheikh Mujibur Rahman
(Darussalaam) — credit it in the About screen. Four questions were verified
programmatically against the mushaf. Corrections already made: the "great
tiding" question occurs once in the definite form (78:2) and once indefinite
(38:67), not twice definite.

`hudna-ilayk` is published **at the author's explicit direction** even though
7:156 says nothing about hajj or the talbiyah. See its `reviewNote`. Do not
re-raise it.

## Design (imported at step 6)

Source: claude.ai/design project `2e3fb7db-7db7-43c6-b11c-0965d3087574`,
`Quran Answers App.dc.html`, built on `quran-majeed-design-system`. The
`.dc.html` is the screen to match; the design system supplies tokens only (it
describes a different, English, dark-only app). Tokens now live in
`lib/core/theme/`. Dark is the design default; the light "paper" palette comes
from the `.dc.html`. `themeMode` follows the system until settings exist.

Bottom nav is a `StatefulShellRoute` with four branches (হোম / বিষয় / সূরা /
সংরক্ষিত). Detail routes are registered under every branch so the bar stays
visible; always navigate with `context.openQuestion()` etc., never a bare
`push('/question/..')`, or the screen lands in the wrong tab.

Search screen was built from existing primitives without re-reading the
`.dc.html` (DesignSync is only usable under a user-started `/design-sync`);
compare against the design's search layout when convenient. Ayah results are
not tappable yet — wire them to `/ayah/:surah/:ayah` in step 9.

The saved tab (step 8) was also built without the `.dc.html`: folder chips
(tap filters, long-press renames/deletes), saved questions with a file-into-
folder button, saved verses (`AyahCard` now has a bookmark toggle everywhere),
history with a confirmed clear. Bottom sheets use the default M3 surface,
which reads slightly green on the paper theme; set `bottomSheetTheme` if it
bothers.

Design screens still to build: collections, "same phrase in this surah". The
ayah, settings and about screens were built without re-reading the `.dc.html`;
compare against it when convenient.

Design features the **schema cannot yet feed** — need content fields before
they can be built honestly:
- question kind (কোথায় / কতবার / নির্দেশনা) and the segmented filter
- lead/detail split of the answer; highlighted phrase inside the Arabic
- interpretive note block ("ব্যাখ্যামূলক টীকা · কুরআনের পাঠ নয়")
- topic icons and curated collections
- **Bengali transliterated surah names** (আল-কামার). The DB has only the
  meaning (চাঁদ) and English. `surahLabel()` in `lib/shared/references.dart`
  uses English for now and is the one place to switch.

Fonts: Noto Sans Bengali (static 400/500/600), Amiri Quran, Cinzel (variable,
wordmark only), all OFL, licenses in `assets/fonts/`. Noto Sans Bengali has no
Latin or ASCII punctuation; `Fonts.latinFallback` (Roboto) covers those.
The ayah ornament is joined with a no-break space, or it wraps onto its own line.

Widget tests that open a question must end with `drain`/`unmount` (see
`test/widget_test.dart`): `recordView` writes on the fake clock while Drift
work from provider setup is in the real zone, and closing the user DB from
tearDown otherwise deadlocks.

## Next steps

| Step | Work |
|---|---|
| 11 | Full content migration from the user's original `.docx`/`.pdf` |

Arabic needs `textDirection: TextDirection.rtl` and `height: >= 1.9` or
diacritics clip. Verify rendering on a **physical Android device** — Chrome's
font fallback differs and proves nothing. The user confirmed step 6 on a device.

**Eyeballing screens without a device:** a throwaway test that loads the bundled
fonts with `FontLoader` (plus `C:/dev/flutter/bin/cache/artifacts/material_fonts/`
`materialicons-regular.otf` and `roboto-*.ttf`), pumps the app, `GoRouter.of(ctx).go(path)`,
then `matchesGoldenFile('shots/x.png')` run with `--update-goldens`. Read the PNGs,
then delete the test and `test/shots/` — never commit them. This caught the tofu
punctuation and the overlapping surah names. Web can't run the app (native SQLite).

## Environment quirks

- A Safety Net hook blocks `rm -rf`; delete files individually and `rmdir`.
- `flutter` sometimes prints `Unable to find git in your PATH` from Git Bash
  instead of its result; re-run `flutter analyze` from PowerShell.
- Design files are re-readable: `/design-login`, then the `DesignSync` tool
  (`list_files`, `get_file`) on project `2e3fb7db-7db7-43c6-b11c-0965d3087574`.
  The screen `Quran Answers App.dc.html` holds the search, ayah, saved and
  settings layouts still to build (lines ~236–628). Take layout and tokens only,
  never Arabic/Bengali content strings.

## Still needed from the user

1. The original `.docx`/`.pdf` for the real content migration.
2. Upload keystore + `android/key.properties`, contact email, privacy-policy
   hosting URL (see `store/README.md`).
3. ~~Package id~~ — now `com.fuad.quran_answers` (iOS `com.fuad.quranAnswers`). App name stays Quran Answers.
4. ~~Device check~~ — user confirmed Bengali and Arabic render correctly on device.
