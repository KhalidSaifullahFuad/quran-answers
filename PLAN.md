# Quran Answers — Project Plan

> Living spec + progress tracker. Steps are ticked as they land. Work stops at every 🛑 checkpoint for review.
>
> Design: claude.ai/design project `2e3fb7db-7db7-43c6-b11c-0965d3087574` → `Quran Answers App.dc.html` (built on `quran-majeed-design-system`). Session-to-session gotchas live in `HANDOFF.md`.

**Status:** steps 1–10 and 12 done (12 awaits a device check); step 11 (content migration) in progress — 200 questions entered (all 200 published); review done 2026-10-10 and 2026-10-17. Remaining: screenshots (11.4).


## Context
An Android-first Flutter app (iOS later): Bengali questions and answers about Islam where **every answer is grounded only in ayat of the Qur'an**. No hadith, no scholarly opinion, **no LLM in the answer path**. The source is the author's Bengali Word/PDF document of numbered entries, e.g.

> ১) "মুদ্দাক্কির" শব্দটি ছয়বার কোন সূরায় আছে? → সূরা আল-কামার (৫৪), আয়াত ১৫, ১৭, ২২, ৩২, ৪০, ৫১

About 100 questions to start, growing. Hard constraints: **$0/month, no backend, no accounts, no analytics, offline-first**. Arabic and Bengali typography both matter; search matters; bookmarks, history and settings are needed.

Outcome: a Flutter app that ships a prebuilt SQLite database holding the full mushaf plus the verified Q&A set, fully usable in airplane mode.

## Stack
| Area | Choice |
|---|---|
| Mobile | Flutter 3.41.9 / Dart 3.11.5 |
| State | Riverpod |
| Database | Drift + SQLite (`sqlite3` 3.x bundles SQLite with FTS5; `sqlite3_flutter_libs` is end-of-life and not used) |
| Search | SQLite FTS5 over normalized shadow columns |
| Navigation | go_router, `StatefulShellRoute` with four tabs |
| UI | Material 3 plumbing + own design tokens (`AppColors` / `AppText` ThemeExtensions) |
| Icons | Iconsax (`iconsax_plus`): Linear by default, Bold for on/selected states |
| Settings | SharedPreferences |
| Mushaf | All 6,236 ayat; Arabic Uthmani + Bengali translation 163, Sheikh Mujibur Rahman (Darussalaam) |
| Package id | `com.fuad.quran_answers` (iOS `com.fuad.quranAnswers`); name "Quran Answers" |

Pinned on purpose: `drift >=2.34.0 <2.35.0` (2.35+ needs a `meta` newer than the Flutter SDK pins).

## Architecture rules (must not be broken)
1. **Arabic is never typed or pasted.** `content/questions.json` carries `refs` like `"54:15"` only; Arabic and the translation are resolved from the mushaf at build time. The source document's Arabic is PDF-corrupted, and this rule keeps it out of the app.
2. **Two databases.** `content.db` is read-only, shipped, replaced wholesale on update. `user.db` (bookmarks, folders, history) is never touched by content updates.
3. **JSON is the source of truth; SQLite is the build artifact.** `tool/build_db.dart` compiles `questions.json` + `quran.json` → `assets/db/content.db`.
4. **Questions are keyed by slug**, never by integer id (ids change on every rebuild).
5. **One shared normalizer** (`lib/core/text/normalize.dart`) for the FTS index and the runtime query; if they diverge, search silently returns nothing.
6. **An answer whose cited ayah does not support it does not ship** without the author's explicit say-so (`status: "draft"` excludes an entry). An answer ships with no ayah only when the author marks it `"noAyah": true` (ruling of 2026-10-10).
7. **The shipped app makes zero network calls.** The release manifest has no INTERNET permission; the privacy policy depends on it.

## Data model
```
content.db  surahs, ayahs (text_uthmani, translation_bn, search_ar, search_bn),
            categories, questions (slug, question_bn, answer_bn, category, search_bn),
            question_ayahs, meta  + FTS5: ayahs_fts, questions_fts
user.db     bookmarks (question_slug, folder_id?), ayah_bookmarks (ayah_id, folder_id?),
            folders, reading_history          ← schema 2, migration from 1 tested
```

## Design language
- Near-monochrome: hierarchy from four foreground greys; flat cards, no borders, no shadows. Dark is the default; light "paper" palette from the `.dc.html`.
- Qur'anic text sits on a **neutral** block (`evidence`). Green (`highlight`) is used only small: cited positions and the evidence icon. No green fills.
- Fonts: Noto Sans Bengali (UI + translation), Amiri Quran (Arabic, line height ≥ 2.0, RTL), Cinzel (wordmark only), Roboto as Latin fallback. All OFL, licenses registered.
- Bottom nav: হোম / বিষয় / সূরা / সংরক্ষিত. Always navigate with `context.openQuestion()` etc. so the screen stays in its tab.

## Implementation plan: step by step

### How we work
- One step at a time; each step ends with `flutter analyze` clean, tests passing, and one commit.
- **This file is ticked as each step lands**, so progress is visible to the author and to any agent. New requests get a step here before work starts.
- Stop at every 🛑 checkpoint for the author's review.
- If something turns out different from the plan, say so before changing course.

---

### Step 1: Scaffold
- [x] **1.1** Flutter app (android, ios), dependencies pinned.

### Step 2: Normalization
- [x] **2.1** `normalize.dart`: Arabic tashkeel/alef/ya folding, hamza seats dropped; Bengali nukta/ZWNJ. Unit tests on both scripts.

### Step 3: Mushaf
- [x] **3.1** `tool/fetch_quran.dart` → `content/quran.json` (build time only). Known ayah checked.

### Step 4: Content schema + build
- [x] **4.1** Schema, `tool/validate_content.dart`, `tool/build_db.dart`; `content.db` from the 5 seed entries.
- [x] **4.2** `hudna-ilayk` published at the author's direction (see its `reviewNote`; do not re-raise).

### Step 5: Runtime databases
- [x] **5.1** Copy `content.db` out on first launch (sha256 marker), Drift classes, Riverpod providers, `user.db`.

### Step 6: Theme + first screens
- [x] **6.1** Design tokens, bundled fonts, home, category and question screens.
- [x] **6.2** Bottom navigation: topics, surahs, saved tabs.
🛑 **Checkpoint:** Arabic and Bengali checked on a physical Android device. ✅ confirmed by the author.

### Step 7: Search
- [x] **7.1** Reference queries (`54:15`, Bengali/Arabic digits) jump to the ayah; full text via FTS5 with prefix terms; article-prefixed Arabic fallback.

### Step 8: User data
- [x] **8.1** Question and verse bookmarks, folders, reading history with clear.

### Step 9: Remaining screens
- [x] **9.1** Ayah screen (`/ayah/:surah/:ayah`) with context and prev/next.
- [x] **9.2** Settings (theme, Arabic and Bengali text size) and About (credits, licenses).
- [x] **9.3** Methodology sheet. *Wording written by Claude; the author should review it.*

### Step 10: Store readiness
- [x] **10.1** App icon (rub el hizb), launch colours, release signing via `android/key.properties`.
- [x] **10.2** Play Store kit in `store/`: listing, privacy policy, Data safety answers, generated screenshots.
🛑 **Checkpoint:** author supplies keystore, contact email and privacy-policy hosting URL.

### Step 11: Content migration
- [x] **11.1** Author supplies the original: `E:\Downloads\09 Oct 26 Known - unknown competitions (1).pdf` (16 pages, **200 questions**). Its text layer is Bijoy/SutonnyMJ legacy encoding, so Bengali is read from the page images, not copied.
  Decisions (2026-10-09): **interpretive or unsupported answers → draft + reviewNote for the author**; **light cleanup** (question verbatim, answer a short sentence with surah name + ayah numbers, no added claims); **Claude proposes ~8 categories, author approves**. The ~20 answers without any ayah are listed for the author to rule on one by one (pending).
- [x] **11.2** All 200 transcribed verbatim from the page images into `content/source/known-unknown-2026-10-09.part{1..4}.json` (no Arabic), then entered in `questions.json` as `ku-001`…`ku-200` (the 5 pilot slugs keep theirs). Content version 2.
- [x] **11.3a** First review pass by Claude: every answer read against its ayah; counts and phrases checked in the Arabic. **152 published, 48 draft.** Reference typos fixed (60 → 18:39, 76 → 17:71, 9 count corrected, 174 + 2:249). Validator now allows a draft without refs (published still needs one; tested).
- [x] **11.3b-1** (2026-10-10) Author ruled on §1 (no ayah cited): "not in the Qur'an" answers ship as is with no ayah (6); the rest get their ayah added (11); ku-194 keeps its original answer with no ayah. An entry ships without refs only if the author marks it `"noAyah": true` (validator, tested); the question screen hides the empty evidence row/section (tested). Review file gets a "Resolved" column per ruled section.
- [x] **11.3b-2** (2026-10-10) Author ruled on §2 (interpretive): 27 published with the original answer and refs; ku-151, ku-162, ku-178 stay draft for a deep dive.
- [x] **11.3b-3** (2026-10-10) Author confirmed the 4 corrections in §3 (ku-009, ku-060, ku-076, ku-174).
- [x] **11.3b-4** (2026-10-10) Author confirmed the §4 spelling fixes in question text.
- [x] **11.3b-5** (2026-10-17) Deep dive: ku-162 published with ref 19:34; ku-178 published as the source has it (12:46, not corrected).
- [x] **11.3b** (2026-10-17) Deep dive: ku-151 published with refs 2:196 and 48:27. Review complete: 200 published, 0 draft.
- [x] **11.3c** (2026-10-17) Categories approved "for now" after splitting the catch-all `society` into family, charity, conduct; 030/083 → quran-itself, 092 → iman, 043 → akhirah. Now 11: words, quran-itself, iman, worship, prophets, family, charity, conduct, akhirah, signs, not-in-quran.
- [ ] **11.4** Rebuild `content.db`, rerun `flutter test tool/render_assets_test.dart` to regenerate store screenshots.
🛑 **Checkpoint:** author reviews the migrated set.

### Step 12: Visual polish (after step 10)
- [x] **12.1** Remove the green fill behind ayat; `evidence` is neutral, home snippet uses `track`.
- [x] **12.2** Replace every Material icon with Iconsax.
- [x] **12.3** Run `dart format lib`, `flutter analyze`, `flutter test` on 12.1–12.2, then commit.
🛑 **Checkpoint:** author checks the new look on device.

### Later (not scheduled)
- [ ] Decide on the uncommitted Chrome preview (`lib/web_preview*.dart`, `native_opener*.dart`); kept uncommitted for now.
- [ ] Design features waiting on content fields: question kind + segmented filter, lead/detail answer split, highlighted phrase in the Arabic, interpretive-note block, curated collections, Bengali transliterated surah names.
- [ ] "Same phrase in this surah" on the ayah screen (needs phrase data).
- [ ] Compare search, saved, ayah, settings and about screens against the `.dc.html`.
- [ ] iOS: icons and a device pass.
- [ ] Remote content updates via a static JSON manifest (out of scope for V1).

## Verification
- `flutter analyze` clean and `flutter test` green after every step.
- Unit: `normalize.dart` fixtures for both scripts; `validate_content.dart` against broken fixtures; every `question_ayahs` row resolves to a real ayah.
- Widget: search returns expected questions; question detail shows the right citation; bookmarks persist.
- **Physical Android device**: tashkeel not clipped, Bengali conjuncts correct, RTL aligned. Chrome proves nothing (different font fallback).
- **Airplane mode from a cold install**: every question, ayah, search and bookmarks work.

## Open items
- Methodology wording: author review.
- Keystore, contact email, privacy-policy hosting URL (`store/README.md`).
- Git remote: none yet. Author will create a (private) repo and share the URL; then `git remote add origin <url>` + push.
