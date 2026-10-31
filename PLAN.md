# Quran Answers — Project Plan

> Living spec + progress tracker. Steps are ticked as they land. Work stops at every 🛑 checkpoint for review.
>
> Design: claude.ai/design project `2e3fb7db-7db7-43c6-b11c-0965d3087574` → `Quran Answers App.dc.html` (built on `quran-majeed-design-system`). Session-to-session gotchas live in `HANDOFF.md`.

**Status:** steps 18–19 (brand colours) landed 2026-10-19, awaiting device check; steps 1–10 and 12 done (12 awaits a device check); step 11 (content migration) in progress — 200 questions entered (all 200 published); review done 2026-10-10 and 2026-10-17. Store screenshots deferred until the app is feature-complete (see Later).


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
| Navigation | go_router, `StatefulShellRoute` with five tabs |
| UI | Material 3 plumbing + own design tokens (`AppColors` / `AppText` ThemeExtensions) |
| Icons | Iconsax (`iconsax_plus`): Linear by default, Bold for on/selected states |
| Settings | SharedPreferences |
| Mushaf | All 6,236 ayat; Arabic Uthmani + Bengali translation 163, Sheikh Mujibur Rahman (Darussalaam) |
| Package id | `com.khalidfuad.quran_answers` (iOS `com.khalidfuad.quranAnswers`); name "Quran Answers" |

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
- Qur'anic text sits on a **neutral** block (`evidence`). Green (`highlight`, brand hue: dark `#5FC2AE`, light `#004D42`) is used only small: cited positions and the evidence icon. No green fills on content.
- Brand (logo): green `#004D42` + gold `#F5C466`. Gold `accent` = brand/action/selection: wordmark, active tab, selected chip, text links, the featured-card label (light theme uses darkened `#8A5F0A`). `brand` green is never a UI fill (rejected on the featured card, tab pill and chips: mud on the dark canvas). It only seeds Material, tints `highlight` (also cursor/selection) and colours the Android splash. Never gold body text, never brand colour on evidence blocks, no gradients.
- Fonts: Noto Sans Bengali (UI + translation), Amiri Quran (Arabic, line height ≥ 2.0, RTL), Cinzel (wordmark only), Roboto as Latin fallback. All OFL, licenses registered.
- Bottom nav: হোম / প্রশ্ন / বিষয় / সূরা / সংরক্ষিত. Always navigate with `context.openQuestion()` etc. so the screen stays in its tab.

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
- [x] **11.4** `content.db` rebuilt with all 200 questions.
🛑 **Checkpoint:** author reviews the migrated set.

### Step 12: Visual polish (after step 10)
- [x] **12.1** Remove the green fill behind ayat; `evidence` is neutral, home snippet uses `track`.
- [x] **12.2** Replace every Material icon with Iconsax.
- [x] **12.3** Run `dart format lib`, `flutter analyze`, `flutter test` on 12.1–12.2, then commit.
🛑 **Checkpoint:** author checks the new look on device.

### Step 13: Design customization (author-led)
- [x] **13.1** Own Iconsax icon per category (words quote_up, quran-itself book, iman heart, worship moon, prophets messages_2, family profile_2user, wealth money_send, ethics people, law judge, dua message_favorite, calendar calendar, akhirah unlimited, signs tree, not-in-quran minus_cirlce); none reuse nav/settings glyphs. Test: every category has a distinct, non-fallback icon.
🛑 **Checkpoint:** author checks the icons on device.
- [x] **13.2** Two-tone category icons: Iconsax Plus has no Bulk set, so `DuoIcon` layers the Bold glyph at low opacity under the Linear one. `categoryIcon()` returns a line/fill pair; `TopicChip`, `QuestionTile` and the topic card take an icon widget sized and coloured through `IconTheme`.
- [x] **13.3** Topics screen: squarish two-column tiles (bare 28px icon top-left, title and count pinned to the bottom edge, height ≈0.66× width; title 17, count 13.5). Grid is built as rows with `IntrinsicHeight` + stretch, so both tiles in a row match when one title wraps to two lines so the grid fills the screen instead of half of it. Tiles keep a square minimum height and grow with large text.
- [x] **13.4** (2026-10-18) Author's 14 categories replace the 11: words, quran-itself (কুরআন ও ওহি), iman (+ শিরক), worship, **dua** (দোয়া, সালাম ও আল্লাহর স্মরণ), prophets, family, charity → **wealth** (সম্পদ, দান ও লেনদেন), conduct → **ethics** (নৈতিকতা, অধিকার ও সামাজিক দায়িত্ব), **law** (বিধিবিধান, হালাল-হারাম ও বিচার), akhirah (আখিরাত, কিয়ামত ও বিচার), signs (আল্লাহর সৃষ্টি ও নিদর্শন), **calendar** (সময়, মাস ও পঞ্জিকা), not-in-quran. Moves: amana-ar-rasul → iman; 006, 019, 051, 059, 103, 105, 106, 128, 129, 141, 142 → dua; 164 → wealth; 022, 077 → ethics; 093, 111, 192, 200 → law; 040, 052, 149 → calendar. Icons: dua message_favorite, wealth money_send, ethics people, law judge, calendar calendar. Phrase-location questions (লা ইলাহা ইল্লাল্লাহ্, আল্লাহু আকবার, …) stay in words. Question-screen category label now `Flexible` (the longer names overflowed). `content.db` rebuilt.
- [x] **13.5** (2026-10-18) Header audit fixes: tab titles align to the 18dp gutter (no extra 4dp when there is no back button); back and action icons both 24dp; search reuses `ScreenHeader` via a `child` slot; 8dp gap between header and first content on every list screen (surahs, surah detail, category, saved).
- [x] **13.6** (2026-10-18) Category screen: question count moves from its own row into the header, right-aligned on the gutter in muted meta style; list starts 8dp below the header.
- [x] **13.7** (2026-10-18) Search field is 41dp like the home search pill (was ~48dp from Material's icon minimums), and stays 41dp when the clear button appears.

### Step 14: UI/UX audit fixes (2026-10-18, author-approved)
Audit of every screen; author decisions: the all-questions list leaves home for its own page, reading history gets its own page, share/copy + next-question + search example chips are in, quiz mode is later.
- [x] **14.1** Home + All questions: home drops the 200-row list ("সব দেখুন" → new All-questions page with category filter chips); topic chips capped at 5 + "সব বিষয়" (switches to Topics tab); "সর্বশেষ পড়া" up to 3 rows + "সব" → history; featured card shows its ayah only when whole (≤140 chars), never cut to 2 lines; otherwise just the ref pill. Topics gets a wide "সব প্রশ্ন" tile on top.
- [x] **14.2** Reading history page (`history` route) moved out of Saved, with clear; Saved links to it.
- [x] **14.3** Saved cleanup: saved ayat as compact rows (ref + one-line translation, opens the ayah screen; a navigation row, not evidence); saved question rows show their category icon; folders managed from a visible header button, not long-press only; one empty state when nothing is saved.
- [x] **14.4** Question screen: occurrence grid removed (it repeated the ayah numbers); "প্রমাণ" pill row only with 3+ ayat; related ranked by shared ayah → shared surah → category neighbours after the current one; "পরের প্রশ্ন" at the bottom; bookmark toast redesigned (compact floating pill with status icon, text-link action: folder on save, undo on remove) for questions and ayat; folder sheet shared.
- [x] **14.5** Small fixes: category rows numbered instead of 42 identical icons; search empty state gets example chips; surahs sort toggle (number / most questions); "রং" → "থিম".
- [x] **14.6** Share question (question + answer + refs) and copy ayah, via `share_plus` 13.3.1; its plugin manifest declares no permissions (checked in the pub cache), so the release manifest still has no INTERNET. Search examples are Bengali + a reference only (rule 1: no Arabic in code).
🛑 **Checkpoint:** author checks step 14 on device (toast look, home length, saved rows, share sheet).

### Step 15: Home on first launch (2026-10-18)
- [x] **15.1** Home looked empty with no history. New "পড়ে দেখুন" section between topics and the all-questions card: 5 questions, one per category, rotating daily (`QuestionIndex.dailyPicks`, date-derived like the featured question), never the featured one or one in "সর্বশেষ পড়া". Shown always. Topic chips stay a horizontal scroll (author).

### Step 16: All questions as a tab (2026-10-18)
- [x] **16.1** Fifth bottom-nav tab প্রশ্ন (`/questions`, message_question icon) showing `AllQuestionsScreen`; the pushed `questions` route and `openAllQuestions()` go.
- [x] **16.2** The all-questions card leaves Topics and Home; Home's "পড়ে দেখুন" gets a "সব দেখুন" link that switches to the tab.
- [x] **16.3** Inline search field on the questions tab: filters question + answer text as you type (shared `normalizeForSearch`), combined with the category chip; no match offers "পুরো কুরআনে খুঁজুন", which opens global search prefilled (`openSearch(query:)`, `?q=`).
- [x] **16.4** Design-rule pass on the questions tab: 8dp under the header; search field and topic chips pinned while only the list scrolls; one shared `AppSearchField` for search screen + questions tab; chip rows (questions tab, saved folders) capped by `ContentFrame` on tablets.
- [x] **16.5** (2026-10-19) Search pill and field go from 41dp to 48dp (`Space.searchHeight`): 41 was under Material's 48dp touch minimum and cramped Bengali; supersedes the 41dp of 13.7. Test pins both heights.
- [x] **16.6** (2026-10-19) Bottom nav: icon 21 → 24dp, pill 54×27 → 60×30, bar 68 → 72dp, label 12.5sp / line 1.3 (Bengali vowel signs), inactive `fg4` → `fg3` for text contrast. Micro-animation on tap: the pill grows out from the icon's centre, the icon gives a short press-and-settle pop (~280ms), outline/filled icon cross-fade; all off when the system asks to reduce motion.

### Step 17: Methodology entry points (2026-10-19)
- [x] **17.1** Info icon beside "সংকলিত উত্তর" on the question screen (and the methodology sheet it opened) removed; the settings "উত্তর কীভাবে সংকলিত" row removed. The sheet stays reachable from the About page only.
- [x] **17.2** Question-screen share icon: `export_1` (box + arrow) → `send_2` (paper plane), author's pick.
- [x] **17.3** Content: `হ্র` rendered as হ + র-ফলা in আল্লাহ্র (12×) and তাহ্রিম (1×); a ZWNJ after the hasanta (`হ্‌র`) keeps the visible hasanta, as in the source. Search already strips ZWNJ. `content.db` + web preview rebuilt.
- [x] **17.4** Content: ku-007 question word “আহম্মদ” → “আহমাদ” (author). Source snapshot under `content/source/` left as received.
- [x] **17.5** Translation: ইহ্রাম/ইহ্রামের (5:95, 5:96) → ZWNJ after the hasanta, patched in `content/quran.json` and in `fetch_quran.dart`'s cleanup so a re-fetch keeps it. হ্রাস (5×) is standard Bengali and stays.

### Step 18: Brand colours (2026-10-19)
Brand from the draft logo: deep green `#004D42`, gold `#F5C466`. Rule: **gold = brand/action, green = Qur'an**. The UI stays mostly monochrome.
Contrast (WCAG): gold on dark bg 11.5:1 ✓; gold on paper 1.4:1 ✗ (never gold text in light); `#004D42` on dark bg 1.9:1 ✗ (never green text in dark); `#004D42` on paper 8.7:1 ✓; gold on `#004D42` 6.1:1 ✓; paper on `#004D42` 8.7:1 ✓.
- [x] **18.1** Tokens: static `AppColors.brand` (`#004D42`); per-theme `accent` (dark `#F5C466`; light `#8A5F0A`, a darkened gold at 5.0:1 on paper). Add them to `lerp`. `seedColor` → `brand`.
- [x] **18.2** `highlight` (Qur'an only) shifts to the brand hue so there is one green family instead of two: dark `#20C08D` → `#5FC2AE` (8.7:1), light `#0F7A57` → `#004D42` (8.7:1). The usage rule is unchanged: small, never a fill.
- [x] **18.3** ~~Home featured card on a `brand` fill~~: tried, author rejected it (2026-10-19). The card stays the neutral `card`; only the "আজকের প্রশ্ন" label and the "উত্তর ও প্রমাণ" link and arrow are `accent`. `onBrand`/`onBrandMuted` and `RefPill(onBrand:)` removed.
- [x] **18.4** Home wordmark (Cinzel) in `accent`.
- [x] **18.5** Bottom nav, selected tab: icon and label in `accent`, pill stays neutral `selected`. Inactive tabs unchanged.
- [x] **18.6** Text-link actions in `accent` (`AppText.link` now gold): toast action (folder/undo), "সব দেখুন" links, the "পরের প্রশ্ন" label. Not body text, not chips, not category icons.
- [x] **18.7** Selected filter chip (questions tab, saved folders): unchanged neutral. Gold here would compete with the nav.
- [x] **18.8** Android splash `#004D42` (`splash_background`: pre-12 launch drawable and 12+ `windowSplashScreenBackground`), so launch matches the logo tile. `NormalTheme` keeps the canvas colour, so no green shows behind Flutter. The launcher icon waits for the final logo.
- [x] **18.9** Design-language section updated; `dart format`, `flutter analyze` (clean), `flutter test` (118 pass). Device check in both themes at the checkpoint.
Don't: gold or green on evidence blocks, gradients, gold body text, brand fills on list rows or cards other than the featured card.
🛑 **Checkpoint:** author checks both themes on device.

### Step 19: Brand green for active/selected (2026-10-19), 19.1–19.2 reverted
Green = active/selected, gold = action. Green only as a small fill with gold or paper on top (gold on `#004D42` 6.1:1, paper 8.7:1).
- [x] **19.1** ~~Reverted (author: ugly; green pill is mud on the dark canvas).~~ Bottom nav, selected tab: pill `brand` fill, icon logo gold `#F5C466` in both themes; label stays `accent`.
- [x] **19.2** ~~Reverted with 19.1; chips back to neutral `selected`.~~ Selected `TopicChip` (questions tab, saved folders, folder sheet, settings theme, surahs sort): `brand` fill, icon and label paper `#F4F1EA`. Unselected unchanged.
- [x] **19.5** Selected `TopicChip`: neutral `selected` pill, icon and label in `accent` (gold), matching the active tab.
- [x] **19.6** Category icons (`DuoIcon`): the filled under-layer is `accent` gold at the same 28% opacity; the outline keeps its ink. Shows on topic tiles, topic chips and question rows. Author's pick over my advice to keep them neutral.
- [x] **19.3** Search cursor, text selection and handles in `highlight` (the readable green per theme), via `TextSelectionThemeData`.
- [x] **19.4** `dart format`, `flutter analyze`, `flutter test` (118 pass); design-language note.
🛑 **Checkpoint:** author checks both themes on device.

### Step 20: Home header (2026-10-19)
- [x] **20.1** Wordmark 16 → 18sp, `accent` gold (Latin Cinzel kept: matches logo and store name).
- [x] **20.2** Tagline demoted from a 23sp two-line headline to a one-line 14sp `fg3` subtitle under the wordmark (`AppText.tagline`, was `display`); original text kept (a shortened version was reverted at the author's request); wraps rather than truncates on narrow phones or large text. Search moves up; the featured card is the hero.
- [x] **20.3** (author) Tagline 14 → 16sp; pulled 10dp closer to the wordmark; 28dp above the search, 20dp below it (author: 32 too loose).
- [x] **20.4** (author) Wordmark 18 → 22sp; 12dp above the home header so it clears the status bar.
🛑 **Checkpoint:** author checks home on device.

### Step 21: Home header art (2026-10-19)
- [x] **21.1** Author's AI-generated night scene (lantern, rehal, arch, moon) cropped to its right corner (792×600 from 1672×941) → `assets/images/home_hero.webp`, q80, 30KB (was a 1.5MB PNG). No credit needed.
- [x] **21.2** Home: `_HeaderArt` top-right behind the header, 62% of the width (max 360dp), runs up behind the status bar (home's `SafeArea` drops `top`, content inset by hand). Left 30% and bottom 40% fade out (the art's `#05080A` ground is darker than the canvas), opacity .85, no hit-testing, no semantics. Dark theme only. Scrolls with the page.
- [x] **21.3** (author) 40% black overlay dims the art; width 62% → 58% (max 340dp); bottom fade 40% → 50%.
- [x] **21.4** (author: stand hidden behind the search) Art now fits the strip above the search: height = status bar + 112dp, width 50% (max 210dp), `BoxFit.cover` aligned to keep lantern and stand; left fade 15%, bottom fade 20%.
- [x] **21.5** (author: should melt into the background like the reference) Asset regraded offline: blacks lifted to the canvas `#131313`, lights scaled ×0.62 (`out = canvas + (in − #05080A)·0.62`), 22KB. Runtime black overlay and opacity removed (they made the ground darker than the canvas).
- [x] **21.6** (author) Dimmer: lights ×0.62 → ×0.38.
🛑 **Checkpoint:** author checks the header on device.

### Step 22: Play Store submission (2026-10-19)
- [x] **22.1** Regenerate store graphics on the full 200-question database; screenshot set now home, topics, question, ayah, questions tab, surahs (topics and questions tabs added; settings dropped). Generator now loads the Iconsax fonts (icons were boxes) and precaches the home header art.
- [x] **22.5** Listing graphics pass (app-store-screenshots checklist): screenshots get a two-line Bengali benefit caption above the real screen in a phone frame; order puts the differentiators first (home, question + proof, ayah in context, topics, questions, surahs); feature graphic shows the real home screen in a phone; store PNGs written without alpha at exact 1080×1920.
- [x] **22.6** (author: frame looked fat) App now rendered as a 20:9 phone (1080×2400, 411dp) with a drawn status bar (24dp) and gesture handle (16dp), then framed at 690px wide in the 1080×1920 store image.
- [x] **22.7** (author) Package id `com.fuad.quran_answers` → `com.khalidfuad.quran_answers` (iOS `com.khalidfuad.quranAnswers`): gradle namespace + applicationId, MainActivity package + dir, privacy policy.
- [x] **22.8** (author) Static homepage + privacy policy site in sibling folder `../quran-answers-site/` (`index.html`, `privacy.html`, `styles.css`): app tokens (dark default, paper light via `prefers-color-scheme`), self-hosted app fonts, gold mark + Cinzel wordmark, real sample question (ku-011, 25:33) drawn like the question screen, store screenshots. "যেভাবে তৈরি" section removed (author). Contact email filled (site, `store/privacy-policy.md`, `store/listing.md`); dated "Last updated: 19 October 2026".
- [x] **22.9** (author, from a reference listing) Screenshot restyle: warm cream→gold gradient, small eyebrow line, large serif Bengali headline (Noto Serif Bengali, tool-only font in `tool/fonts/`) with the second line in amber, thick dark bezel phone with large corners and a punch-hole camera, phone bigger and running off the bottom edge. Drawn status bar 24→32dp with wider insets so the clock clears the larger corners. Regenerated 2026-10-21.
- [ ] **22.2** (author) Upload key + `android/key.properties`; contact email and hosted privacy-policy URL.
- [ ] **22.3** (author) Device pass on steps 12, 18–21 checkpoints; airplane-mode cold install.
- [ ] **22.4** `flutter build appbundle --release`, closed test (12 testers × 14 days), then production.

### Step 23: Final logo (2026-10-19)
Source: author's `store/Logo — vector.svg` (2048², gold #F5C466 open book + question mark + rays on brand green #004D42); `.png` is the same art rasterised. Rename to `assets/logo/logo.svg` (no spaces or dash in the path). The green ground is part of the logo, not a UI fill, so it may stay on the icon.
- [x] **23.1** `lib/shared/logo_mark.dart`: the SVG's 16 gold paths copied in, parsed by a small M/L/C/Z reader (no new dependency); `LogoMarkPainter` + `LogoMark`. Generator's `_StarPainter` → `_IconPainter`. Files moved to `assets/logo/logo.svg` / `logo.png` (source only, not bundled).
- [x] **23.2** Launcher icons: legacy and round = logo as supplied (green ground, mark scaled to fit); adaptive = green background layer + gold mark foreground scaled into the 66dp safe circle (mark spans ~65% of the art, so ~.8×); monochrome = mark silhouette.
- [x] **23.3** `store/icon-512.png`: logo full-bleed (Play masks it).
- [x] **23.4** Feature graphic: mark beside the wordmark on the left; phone stays on the right.
- [x] **23.5** Home: 22dp gold (`accent`) mark before the wordmark, no green tile; below 48dp the rays are dropped and the book + question mark fill the box.
- [x] **23.6** Splash: already the adaptive icon on `splash_background` green (Android 12+); now shows the logo mark. `ic_launcher_background` #131313 → #004D42.
- [x] **23.7** Regenerated. Rays kept on launcher icons (fine at xxhdpi, what phones use). Fixed generator bug: `shouldRepaint => false` made the monochrome layer reuse the foreground paint; it is now white (the old star one was green).
- [x] **23.8** (author) Dark-mode splash: canvas `#131313` with the gold mark centred, no green tile. Generator writes `drawable-*dpi/splash_mark.png` (288dp, the Android 12 no-background icon size; mark inside its 192dp circle). `values-night/colors.xml` overrides `splash_background`; `values-night-v31` sets `windowSplashScreenAnimatedIcon`; `drawable-night/launch_background.xml` centres the mark for pre-12. Light splash unchanged.
🛑 **Checkpoint:** author checks icon on the launcher and home header on device.

### Step 24: Store folder layout (2026-10-31)
Match `quranic_ramadan_calendar/store_assets/`: `store/` → `store_assets/`; final Play graphics in `store_assets/output/` named `0_feature.png`, `1_home.png` … `6_surahs.png` (+ `icon_512.png`); captions documented in `store_assets/screenshot_copy.md`. Docs (`README.md`, `listing.md`, `privacy-policy.md`) stay at the folder root. No HTML template/render.ps1: graphics still come from `tool/render_assets_test.dart` (Bengali shaping).
- [x] **24.1** `git mv` files to the new layout.
- [x] **24.2** Generator writes the new paths; README, HANDOFF, PLAN references updated.
- [x] **24.3** `screenshot_copy.md` with the approved captions.
- [x] **24.4** (author) `store_assets/output/` gitignored (generated; rerun the generator before upload). Docs stay tracked.

### Step 25: iOS and web icons (2026-10-31)
Both still had Flutter's default logo and template metadata.
- [x] **25.1** iOS `AppIcon.appiconset`: every size in `Contents.json`, logo full-bleed on green, opaque (Apple rejects alpha; iOS applies its own mask).
- [x] **25.2** Web: `favicon.png` (32), `Icon-192/512` full-bleed, `Icon-maskable-192/512` with the mark inside the 80% safe circle.
- [x] **25.3** `web/manifest.json` + `index.html`: name Quran Answers, Bengali tagline, colours `#131313`.

### Step 26: README (2026-11-01)
- [x] **26.1** Replace the Flutter template README: logo, tagline, badges, features, 4 screenshots (tracked copies in `docs/screenshots/`, since `store_assets/output/` is ignored), download table, build steps, content pipeline, stack, credits.

### Later (not scheduled)
- [ ] Quiz / practice mode: answer hidden until tapped, then next (author: later version).
- [ ] Decide on the uncommitted Chrome preview (`lib/web_preview*.dart`, `native_opener*.dart`); kept uncommitted for now.
- [ ] Design features waiting on content fields: question kind + segmented filter, lead/detail answer split, highlighted phrase in the Arabic, interpretive-note block, curated collections, Bengali transliterated surah names.
- [ ] "Same phrase in this surah" on the ayah screen (needs phrase data).
- [ ] Compare search, saved, ayah, settings and about screens against the `.dc.html`.
- [ ] iOS: device pass (icons done in step 25).
- [ ] Remote content updates via a static JSON manifest (out of scope for V1).

## Verification
- `flutter analyze` clean and `flutter test` green after every step.
- Unit: `normalize.dart` fixtures for both scripts; `validate_content.dart` against broken fixtures; every `question_ayahs` row resolves to a real ayah.
- Widget: search returns expected questions; question detail shows the right citation; bookmarks persist.
- **Physical Android device**: tashkeel not clipped, Bengali conjuncts correct, RTL aligned. Chrome proves nothing (different font fallback).
- **Airplane mode from a cold install**: every question, ayah, search and bookmarks work.

## Open items
- Methodology wording: author review.
- Keystore, contact email, privacy-policy hosting URL (`store_assets/README.md`).
- Git remote: none yet. Author will create a (private) repo and share the URL; then `git remote add origin <url>` + push.
