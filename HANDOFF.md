# Handoff — Quran Answers app

State as of commit `eccbfc0`. Steps 1–5 of the plan are done. Next is step 6,
with a design import in front of it.

Full plan: `C:\Users\Fuad\.claude\plans\pasted-content-id-1712-want-to-smooth-rossum.md`

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
flutter test                          # 71 tests, all passing

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
lib/core/db/content_store.dart    copies the asset out of the bundle
lib/core/db/user_tables.dart      bookmarks, reading_history
lib/core/db/user_db.dart          toggleBookmark, recordView, recentSlugs
lib/core/db/database_providers.dart  Riverpod wiring
lib/app.dart                      PLACEHOLDER screen — delete at step 6
tool/                             fetch_quran, validate_content, build_db
test/core/                        6 test files
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
- **Writing Dart via shell heredocs mangles backslashes** and Edit anchors fail
  on lines with RTL comments. Use the Write tool for files with `\u` escapes.

## Content status

5 questions, 11 citations, 3 categories. Translation 163, Sheikh Mujibur Rahman
(Darussalaam) — credit it in the About screen. Four questions were verified
programmatically against the mushaf. Corrections already made: the "great
tiding" question occurs once in the definite form (78:2) and once indefinite
(38:67), not twice definite.

`hudna-ilayk` is published **at the author's explicit direction** even though
7:156 says nothing about hajj or the talbiyah. See its `reviewNote`. Do not
re-raise it.

## Next steps

**Step 6 is preceded by a design import.** The user has a design at
`https://claude.ai/design/p/2e3fb7db-7db7-43c6-b11c-0965d3087574?file=Quran+Answers+App.dc.html`
built on a `quran-majeed-design-system`. It needs `/design-login` first, then the
`DesignSync` tool (`list_files`, `get_file`) to read:

- `Quran Answers App.dc.html`
- `_ds/quran-majeed-design-system-b396c861-4920-478c-a09b-f98fcd8c6ceb/tokens/*.css`
  (colors, effects, fonts, spacing, typography), `styles.css`, `_ds_bundle.js`
- `support.js`

Open question to ask the user: is the design system the source of truth for the
whole app, or is the `.dc.html` screen the thing to match?

Take layout, colors, type scale and spacing from the design. **Never take
Arabic or Bengali strings from it** — text always comes from the database.

Then:

| Step | Work |
|---|---|
| 6 | Theme + bundled fonts (Noto Sans Bengali, Amiri Quran — both OFL), home, question list, detail with real Arabic/Bengali rendering |
| 7 | Search: FTS + `54:15` reference parser, with prefix matching |
| 8 | Bookmarks and history UI (data layer already exists) |
| 9 | Topics, standalone ayah screen with context verses, settings, about + credits |
| 10 | Dark mode, app icon, Play Store assets |
| 11 | Full content migration from the user's original `.docx`/`.pdf` |

Arabic needs `textDirection: TextDirection.rtl` and `height: >= 1.9` or
diacritics clip. Verify rendering on a **physical Android device** — Chrome's
font fallback differs and proves nothing. `flutter devices` currently lists no
Android device.

## Still needed from the user

1. The original `.docx`/`.pdf` for the real content migration.
2. App name and final package id (currently `com.hastech.quran_answers`).
3. A physical Android device for step 6 verification.
