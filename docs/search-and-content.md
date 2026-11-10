# Questions and Search: How They Work

The state as of Step 32 (2026-11-09).

---

## 1. How a question is authored

**Source of truth:** `content/questions.json`. Content is written and reviewed there, then compiled into the app's database by `dart run tool/build_db.dart`.

```json
{
  "slug": "ku-040",
  "status": "published",
  "category": "calendar",
  "sortOrder": 40,
  "questionBn": "বার মাস কোন আয়াতে উল্লেখ করা হয়েছে?",
  "answerBn": "সূরা আত-তাওবা ৯:৩৬।",
  "refs": ["9:36"],
  "source": "known-unknown-2026-10-09 #40",
  "reviewNote": "Checked: the cited ayah supports the answer."
}
```

| Field | Meaning |
|---|---|
| `slug` | Permanent ID. Bookmarks and reading history point to it, so it never changes. |
| `status` | `published` is included in the app. `draft` is left out of the build. |
| `category` | One of 14 category IDs (`words`, `quran-itself`, `iman`, `worship`, `dua`, `prophets`, `family`, `wealth`, `ethics`, `law`, `akhirah`, `signs`, `calendar`, `not-in-quran`). |
| `sortOrder` | The author's order inside lists. |
| `questionBn` / `answerBn` | Question and answer, in Bengali. |
| `refs` | The cited ayahs as `surah:ayah`, in display order. |
| `noAyah` | `true` for answers with no citation (7 questions, mostly "not in the Qur'an"). |
| `source` | Where the question came from, e.g. the original document and its item number. Present on 195 of the 200 questions. |
| `reviewNote` | The review result. Not shown in the app. |

**Rule:** questions hold only references. Arabic text and the translation are never written into a question. They are looked up from `content/quran.json` at build time, so there is exactly one copy of each ayah. That file holds the Bengali translation by Sheikh Mujibur Rahman (Darussalaam), fetched from api.quran.com.

**Current numbers:**
- 200 questions, all published.
- Citations per question:
  - 151 cite one ayah.
  - 42 cite more than one; the most is 12.
  - 7 cite none.

---

## 2. How it is stored in the app

There are two SQLite files.

### `assets/db/content.db`
Read-only. It ships with the app and is replaced on each update.

| Table | Contents |
|---|---|
| `surahs` | number, `nameAr`, `nameBn` (the meaning, e.g. চাঁদ), `nameEn` (Al-Qamar), ayah count, revelation place. |
| `ayahs` | `id = surah×1000 + ayah` (54:15 → 54015), Uthmani text, plain Arabic text, Bengali translation, and two search copies (`searchAr`, `searchBn`). |
| `categories` | id, Bengali name, English name, order. |
| `questions` | slug, question, answer, category, `searchBn`, order. |
| `question_ayahs` | (question slug, ayah id, order). Links each question to the ayahs it cites. |
| `meta` | content version, build time, translation credit, counts. |

**Full-text search indexes (SQLite FTS5):**

| Index | Columns |
|---|---|
| `ayahs_fts` | `search_ar`, `search_bn`, `loose_bn`. It stores no ayah text of its own; the rowid is the ayah id. |
| `questions_fts` | `slug` (not searchable), `question_bn`, `answer_bn`, `loose_question_bn`, `loose_answer_bn`. |

How the search text is prepared:
- **Normalized text:** produced by `normalizeForSearch`, which removes harakat and evens out alef and hamza forms in Arabic, and evens out Bengali characters.
  - The same function runs when the index is built and when a query is typed, so both sides always match.
- **Loose text:** produced by `looseFold`, which treats these Bengali letters as the same, so different spellings of a word still match:
  - ী=ি, ূ=ু, ো=ু
  - য=জ, ণ=ন, শ/ষ=স, ড়/ঢ়=র
  - hasanta (্) is dropped
- **Plain Arabic spelling:** `search_ar` also holds the plain spelling of each ayah alongside the Uthmani text. That is why الكتاب finds the Uthmani الكتب.

### The user database
Read-write, on the phone. It holds bookmarks, folders, reading history and recent searches (the last 10). It is a separate file, so a content update never touches it.

---

## 3. How a search runs

Entry point: `ContentDatabase.search()` in `lib/core/db/content_search.dart`. It checks the input in this order and stops at the first that fits:

```
input
 │  remove a leading "সূরা / সুরা / surah / sura / surat"
 ├─ 1. ayah reference?       ৫৪:১৫ · 54.15 · 2 255 · ৯ঃ৩৬     → jump to the ayah
 ├─ 2. number alone?         ৩৬ · 114                         → that surah
 ├─ 3. surah name + number?  baqarah ২৫৫ · Al-Qamar 17        → jump to the ayah
 ├─ 4. too short?            every word is 1 letter (ক)        → "অন্তত দুই অক্ষরের শব্দ লিখুন।"
 └─ 5. text search           surah names + questions + ayahs
       └─ no result with ALL words? → retry with ANY word, and show a note
```

Digits can be ASCII, Bengali (০-৯) or Arabic-Indic. Separators can be `:` `.` a space or `ঃ`.

### Building a text search

1. **Words:** the query is normalized and split on spaces. One-letter words are dropped.
2. **Each word becomes a group of forms:**
   - the word itself
   - its loose form
   - for Arabic, the form with the article ال (so قمر also finds القمر)
   - its synonyms from `lib/core/text/synonyms.dart`. There are 16 groups, for example:
     - নামাজ = সালাত
     - রোজা = সিয়াম
     - দোযখ = জাহান্নাম
     - রমজান = রমাদান
3. **How each form matches:**

| Word | Matches | Example |
|---|---|---|
| Long word (4+ letters) or Arabic | Any word that **starts with** it | নিদর্শন → নিদর্শনরূপে |
| Short Bengali word (≤3 letters) | **Only the word itself, or the word plus a common ending**: ের এর র ে এ য় তে কে টি টা টির টিতে গুলো গুলি দের রা ও ই সমূহ খানা | মাস → মাস, মাসের; **not** মাসজিদুল |

4. **Combining words:** groups are joined with AND: every word must appear somewhere in the result. If nothing matches, the search retries with OR and shows "সব শব্দ একসাথে কোথাও মেলেনি…".

### Ranking

| Results | Order |
|---|---|
| Questions | 1. Whole-word matches come first (a whole word or a short word with an ending; a match on only the start of a word ranks lower). 2. Then by FTS5 bm25 score, where a match in the **question** weighs 10, a match in the answer 1, and loose-spelling matches less than exact ones. |
| Ayahs | 1. Whole-word matches first. 2. Then bm25 score across Arabic, Bengali and loose Bengali. |
| Surahs | An exact name match ranks above a name that only starts with the query, then surah number. At most 3 are shown. |

### Surah name matching
Each surah can be found by:
- its Bengali meaning (চাঁদ), whole or by a single word of it
- its English name with or without the article (`Al-Qamar`, `qamar`)
- its Arabic name with or without ال

> Gap: there are no Bengali spellings of the Arabic names yet, so বাকারা finds no surah.

---

## 4. Which search shows which result

| You type | Example | Screen shows |
|---|---|---|
| Ayah reference | `৯:৩৬`, `54.17`, `সূরা ২:২৫৫` | The **full ayah card**, then "এই আয়াত যেসব প্রশ্নের প্রমাণ" (the questions citing it). **No tabs.** |
| Reference past the end of a surah | `1:8` | Message: no such ayah. |
| Number alone | `৩৬` | One surah row (Ya-Sin). |
| Surah name + number | `baqarah ২৫৫` | Same as an ayah reference (2:255). |
| One letter | `ক` | "অন্তত দুই অক্ষরের শব্দ লিখুন।" |
| Bengali word or phrase | `বার মাস`, `নামাজ`, `নুহ` | **Tabs সব / প্রশ্ন / আয়াত**, then sections (below). |
| Arabic word | `مدكر`, `الكتاب` | Same tabs. It matches Arabic ayah text, without harakat. |
| Surah name | `qamar`, `চাঁদ`, `القمر` | Tabs. A **সূরা** section first, then any question and ayah matches. |
| Words that never appear together | `নূহ zzz` | Results matching any one word, with the "সব শব্দ…" note. |
| Nothing matches | `zzzz` | Empty state: "কিছু পাওয়া যায়নি". |

### Sections in a text search

| Section | Tab সব | Tab প্রশ্ন | Tab আয়াত |
|---|---|---|---|
| **সূরা**: up to 3 surah rows | ✓ | – | – |
| **প্রশ্ন**: title with the match in bold, surah + verse underneath (category if it cites none), count on the right | First 5, then "সব nটি প্রশ্ন দেখুন" | All | – |
| **আয়াত**: grey pill (surah · verse), two lines of translation around the match in bold, "অনুবাদে মিল" on the right | 50, then "আরও nটি আয়াত দেখুন" | – | 50 + more |

Tapping a result opens it: a question opens its answer screen, an ayah opens that ayah, and a surah opens the surah.

### Empty search screen

- **সাম্প্রতিক:** the last 10 searches.
  - Tapping a row searches it again.
  - The ↖ arrow puts the text in the box without searching.
  - The trash button clears all of them.
  - A search is saved only if it found something, and only when you submit it, open a result, or leave the screen.
- **যেভাবে খুঁজতে পারেন:** four cards, each running its example:
  - বাংলায় প্রশ্ন → বার মাস
  - আরবি শব্দ → مدكر
  - সূরার নাম → القمر
  - আয়াত নম্বর → ৫৪:১৭

---

## 5. The Questions tab filter

The filter box on **সব প্রশ্ন** does not use the database search. It filters in memory with the same matching rules: loose spelling, synonyms, short-word endings, and every word required.

It covers only the questions in the selected category. When nothing matches, it offers "পুরো কুরআনে খুঁজুন", which opens the full search.

---

## 6. Files

| What | Where |
|---|---|
| Questions (source) | `content/questions.json` |
| Qur'an text and translation (source) | `content/quran.json` |
| Database build | `tool/build_db.dart` → `assets/db/content.db` |
| Table definitions | `lib/core/db/content_tables.dart`, `content_db.dart` (FTS tables and ranking weights) |
| Normalizing and loose spelling | `lib/core/text/normalize.dart` |
| Synonyms | `lib/core/text/synonyms.dart` |
| Search logic | `lib/core/db/content_search.dart` |
| Search screen | `lib/features/search/search_screen.dart` |
| Bold highlighting | `lib/shared/search_highlight.dart` |
| Tests | `test/core/content_search_test.dart`, `content_db_test.dart`, `normalize_test.dart` |
