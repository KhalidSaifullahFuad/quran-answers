import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/core/text/normalize.dart';

/// Inputs and expectations are written as explicit codepoint escapes.
/// Arabic and Bengali are easy to mistype and impossible to eyeball in a diff,
/// and a wrong expectation here would silently bless a broken search index.
void main() {
  group('normalizeArabic', () {
    test('strips tashkeel so undiacriticized queries match Uthmani text', () {
      // مُدَّكِرٍ (54:15) -> مدكر
      const uthmani = '\u0645\u064F\u062F\u0651\u064E\u0643\u0650\u0631\u064D';
      const bare = '\u0645\u062F\u0643\u0631';
      expect(normalizeArabic(uthmani), bare);
    });

    test('folds alef with hamza to bare alef', () {
      // أَحْمَد -> احمد
      expect(
        normalizeArabic('\u0623\u064E\u062D\u0645\u064E\u062F'),
        '\u0627\u062D\u0645\u062F',
      );
    });

    test('folds alef wasla to bare alef', () {
      // ٱلحمد -> الحمد
      expect(
        normalizeArabic('\u0671\u0644\u062D\u0645\u062F'),
        '\u0627\u0644\u062D\u0645\u062F',
      );
    });

    test('folds alef maksura to ya', () {
      // علَى -> علي
      expect(normalizeArabic('\u0639\u0644\u064E\u0649'), '\u0639\u0644\u064A');
    });

    test('folds ta marbuta to ha', () {
      // رحمة -> رحمه
      expect(
        normalizeArabic('\u0631\u062D\u0645\u0629'),
        '\u0631\u062D\u0645\u0647',
      );
    });

    test('drops hamza seats so every spelling of a word converges', () {
      // نَبَؤٌا (38:67) and the ordinary spelling نبأ must reduce to the same
      // form, otherwise that ayah is unreachable by search. Both become نبا.
      const onWaw = 'نبؤٍا'; // نبؤٍا
      const onAlef = 'نبأ'; // نبأ
      const bare = 'نبا'; // نبا
      expect(normalizeArabic(onWaw), bare);
      expect(normalizeArabic(onAlef), bare);
    });

    test('drops hamza on ya', () {
      // مِئَة -> مه  (the ya is only a seat)
      expect(normalizeArabic('مئَة'), 'مه');
    });

    test('drops tatweel', () {
      expect(normalizeArabic('\u0645\u0640\u0640\u062F'), '\u0645\u062F');
    });

    test('drops the end-of-ayah and sajdah annotation signs', () {
      // م ۝ د  (U+06DD end of ayah)
      expect(normalizeArabic('\u0645\u06DD\u062F'), '\u0645\u062F');
    });

    test('leaves already-bare Arabic untouched', () {
      const bare = '\u0645\u062F\u0643\u0631';
      expect(normalizeArabic(bare), bare);
    });
  });

  group('normalizeBengali', () {
    test('composes nukta sequences to their canonical codepoint', () {
      expect(normalizeBengali('\u09A1\u09BC'), '\u09DC'); // ড + ় -> ড়
      expect(normalizeBengali('\u09A2\u09BC'), '\u09DD'); // ঢ + ় -> ঢ়
      expect(normalizeBengali('\u09AF\u09BC'), '\u09DF'); // য + ় -> য়
    });

    test('composes decomposed o-kar and au-kar', () {
      expect(normalizeBengali('\u0995\u09C7\u09BE'), '\u0995\u09CB'); // কো
      expect(normalizeBengali('\u0995\u09C7\u09D7'), '\u0995\u09CC'); // কৌ
    });

    test('preserves hasanta, which forms meaningful conjuncts', () {
      // বিশ্বাস — শ + hasanta + ব must survive
      const word = '\u09AC\u09BF\u09B6\u09CD\u09AC\u09BE\u09B8';
      expect(normalizeBengali(word), word);
    });
  });

  group('foldDigits', () {
    test('folds Bengali digits to ASCII', () {
      expect(foldDigits('\u09EB\u09EA'), '54');
    });

    test('folds Arabic-Indic digits to ASCII', () {
      expect(foldDigits('\u0665\u0664'), '54');
      expect(foldDigits('\u06F5\u06F4'), '54');
    });
  });

  group('normalizeForSearch', () {
    test('keeps the colon in a verse reference after digit folding', () {
      // ৫৪:১৫ -> 54:15  (the reference parser depends on this)
      expect(normalizeForSearch('\u09EB\u09EA:\u09E7\u09EB'), '54:15');
    });

    test('drops zero-width joiners and non-joiners', () {
      expect(normalizeForSearch('\u0995\u200C\u0996'), '\u0995\u0996');
      expect(normalizeForSearch('\u0995\u200D\u0996'), '\u0995\u0996');
    });

    test('turns surrounding quotes into separators, not glue', () {
      // "মুদ্দাক্কির" -> মুদ্দাক্কির
      const quoted =
          '\u201C\u09AE\u09C1\u09A6\u09CD\u09A6\u09BE'
          '\u0995\u09CD\u0995\u09BF\u09B0\u201D';
      const bare =
          '\u09AE\u09C1\u09A6\u09CD\u09A6\u09BE'
          '\u0995\u09CD\u0995\u09BF\u09B0';
      expect(normalizeForSearch(quoted), bare);
    });

    test('collapses whitespace and trims', () {
      expect(normalizeForSearch('  a \n b  '), 'a b');
    });

    test('lowercases Latin text', () {
      expect(normalizeForSearch('Al-Qamar'), 'al qamar');
    });

    test('handles mixed Bengali and Arabic in one string', () {
      // সূরা مُدَّكِر
      const mixed =
          '\u09B8\u09C2\u09B0\u09BE '
          '\u0645\u064F\u062F\u0651\u064E\u0643\u0650\u0631';
      const expected = '\u09B8\u09C2\u09B0\u09BE \u0645\u062F\u0643\u0631';
      expect(normalizeForSearch(mixed), expected);
    });

    test('is idempotent', () {
      const samples = [
        '\u0645\u064F\u062F\u0651\u064E\u0643\u0650\u0631\u064D',
        '\u09A1\u09BC\u09BE\u0995',
        '\u09EB\u09EA:\u09E7\u09EB',
        '  Al-Qamar  ',
        '\u201C\u0995\u09CB\u09A8\u201D',
      ];
      for (final s in samples) {
        final once = normalizeForSearch(s);
        expect(normalizeForSearch(once), once, reason: 'not idempotent: $s');
      }
    });

    test(
      'returns empty string for input that is only marks and punctuation',
      () {
        expect(normalizeForSearch('\u064E\u0650 ... '), '');
      },
    );
  });
}
