import 'package:flutter/material.dart';

import 'colors.dart';

/// Font family names as declared in pubspec.yaml.
abstract final class Fonts {
  static const bengali = 'NotoSansBengali';
  static const arabic = 'AmiriQuran';
  static const wordmark = 'Cinzel';

  /// Noto Sans Bengali carries Bengali glyphs only: Latin letters and ordinary
  /// punctuation (, : - ( )) come from here. Named explicitly so they never
  /// depend on whatever the platform's last-resort fallback happens to be.
  static const latinFallback = ['Roboto'];
}

/// Every text style the app uses, sizes taken from the imported design.
///
/// Arabic line height stays at 2.0 or more: Amiri Quran stacks tashkeel and
/// Qur'anic annotation marks well above and below the baseline, and anything
/// tighter clips them against the neighbouring line.
@immutable
class AppText extends ThemeExtension<AppText> {
  const AppText._({
    required this.wordmark,
    required this.display,
    required this.questionTitle,
    required this.cardTitle,
    required this.screenTitle,
    required this.section,
    required this.rowTitle,
    required this.meta,
    required this.label,
    required this.answer,
    required this.translation,
    required this.arabic,
    required this.pill,
    required this.link,
    required this.cell,
  });

  /// [arabicScale] multiplies the Qur'anic text; [bengaliScale] the reading
  /// text (question, answer, translation). Chrome keeps its design size.
  factory AppText.from(
    AppColors c, {
    double arabicScale = 1.0,
    double bengaliScale = 1.0,
  }) {
    const base = TextStyle(
      fontFamily: Fonts.bengali,
      fontFamilyFallback: Fonts.latinFallback,
    );
    return AppText._(
      wordmark: TextStyle(
        fontFamily: Fonts.wordmark,
        fontSize: 16,
        fontVariations: const [FontVariation('wght', 600)],
        letterSpacing: .6,
        color: c.fg1,
      ),
      display: base.copyWith(
        fontSize: 23,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: c.fg1,
      ),
      questionTitle: base.copyWith(
        fontSize: 22 * bengaliScale,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: c.fg1,
      ),
      cardTitle: base.copyWith(
        fontSize: 17.5,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: c.fg1,
      ),
      screenTitle: base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: c.fg1,
      ),
      section: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.fg1,
      ),
      rowTitle: base.copyWith(
        fontSize: 15.5,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: c.fg1,
      ),
      meta: base.copyWith(fontSize: 12.5, height: 1.4, color: c.fg3),
      label: base.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        letterSpacing: .3,
        color: c.fg3,
      ),
      answer: base.copyWith(
        fontSize: 17 * bengaliScale,
        fontWeight: FontWeight.w500,
        height: 1.65,
        color: c.fg1,
      ),
      translation: base.copyWith(
        fontSize: 16 * bengaliScale,
        height: 1.7,
        color: c.fg2,
      ),
      arabic: TextStyle(
        fontFamily: Fonts.arabic,
        fontSize: 26 * arabicScale,
        height: 2.0,
        color: c.fg1,
      ),
      pill: base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: c.fg1,
      ),
      link: base.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: c.fg2,
      ),
      cell: base.copyWith(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: c.background,
      ),
    );
  }

  /// "QURAN ANSWERS" on the home header.
  final TextStyle wordmark;

  /// The home tagline.
  final TextStyle display;

  /// Question heading on the detail screen.
  final TextStyle questionTitle;

  /// Question text inside the featured card.
  final TextStyle cardTitle;
  final TextStyle screenTitle;
  final TextStyle section;

  /// Question text in a list row.
  final TextStyle rowTitle;
  final TextStyle meta;

  /// Small caps-like kicker above a block ("আজকের প্রশ্ন").
  final TextStyle label;

  /// The compiled answer.
  final TextStyle answer;

  /// Bengali translation of an ayah.
  final TextStyle translation;

  /// Qur'anic text. Always paired with [TextDirection.rtl].
  final TextStyle arabic;
  final TextStyle pill;
  final TextStyle link;

  /// Ayah number inside a highlighted occurrence cell.
  final TextStyle cell;

  static AppText of(BuildContext context) =>
      Theme.of(context).extension<AppText>()!;

  @override
  AppText copyWith() => this;

  @override
  AppText lerp(AppText? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppText._(
      wordmark: l(wordmark, other.wordmark),
      display: l(display, other.display),
      questionTitle: l(questionTitle, other.questionTitle),
      cardTitle: l(cardTitle, other.cardTitle),
      screenTitle: l(screenTitle, other.screenTitle),
      section: l(section, other.section),
      rowTitle: l(rowTitle, other.rowTitle),
      meta: l(meta, other.meta),
      label: l(label, other.label),
      answer: l(answer, other.answer),
      translation: l(translation, other.translation),
      arabic: l(arabic, other.arabic),
      pill: l(pill, other.pill),
      link: l(link, other.link),
      cell: l(cell, other.cell),
    );
  }
}
