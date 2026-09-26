import 'package:flutter/material.dart';

/// Color tokens from the imported design (`Quran Answers App.dc.html`, built on
/// the quran-majeed design system).
///
/// The design is near-monochrome: hierarchy comes from four foreground grays,
/// and the only color is reserved for scripture — Qur'anic text sits on a green
/// tint ([evidence]) and cited positions are marked in [highlight]. Keeping the
/// green for Qur'an only is what lets a reader tell verse from commentary at a
/// glance, so do not reuse it for ordinary accents.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.track,
    required this.raised,
    required this.selected,
    required this.sheet,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    required this.divider,
    required this.evidence,
    required this.highlight,
    required this.scrim,
  });

  /// Page canvas.
  final Color background;

  /// Flat card one step off the canvas. No borders, no shadows.
  final Color card;

  /// Pills, chips, search field, icon circles, empty grid cells.
  final Color track;
  final Color raised;
  final Color selected;
  final Color sheet;

  /// Titles.
  final Color fg1;

  /// Body text and translations.
  final Color fg2;

  /// Meta and labels.
  final Color fg3;

  /// Inactive.
  final Color fg4;
  final Color divider;

  /// Background of any block that shows Qur'anic text.
  final Color evidence;

  /// Cited positions and the evidence icon.
  final Color highlight;
  final Color scrim;

  static const dark = AppColors(
    background: Color(0xFF131313),
    card: Color(0xFF1C1C1C),
    track: Color(0xFF212121),
    raised: Color(0xFF262626),
    selected: Color(0xFF2B2B2B),
    sheet: Color(0xFF181818),
    fg1: Color(0xFFF4F4F4),
    fg2: Color(0xFFB4B4B4),
    fg3: Color(0xFF8C8C8C),
    fg4: Color(0xFF6E6E6E),
    divider: Color(0xFF262626),
    evidence: Color(0xFF12291F),
    highlight: Color(0xFF20C08D),
    scrim: Color(0x9E000000),
  );

  /// The design's "paper" theme.
  static const light = AppColors(
    background: Color(0xFFF4F1EA),
    card: Color(0xFFEBE7DF),
    track: Color(0xFFE4DFD5),
    raised: Color(0xFFDAD4C8),
    selected: Color(0xFFFFFFFF),
    sheet: Color(0xFFF4F1EA),
    fg1: Color(0xFF171A18),
    fg2: Color(0xFF383D39),
    fg3: Color(0xFF5A605B),
    fg4: Color(0xFF767B76),
    divider: Color(0xFFE0DAD0),
    evidence: Color(0xFFE2EDE5),
    highlight: Color(0xFF0F7A57),
    scrim: Color(0x6B14140F),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      card: l(card, other.card),
      track: l(track, other.track),
      raised: l(raised, other.raised),
      selected: l(selected, other.selected),
      sheet: l(sheet, other.sheet),
      fg1: l(fg1, other.fg1),
      fg2: l(fg2, other.fg2),
      fg3: l(fg3, other.fg3),
      fg4: l(fg4, other.fg4),
      divider: l(divider, other.divider),
      evidence: l(evidence, other.evidence),
      highlight: l(highlight, other.highlight),
      scrim: l(scrim, other.scrim),
    );
  }
}

/// Spacing and shape tokens.
abstract final class Space {
  /// Horizontal page padding.
  static const gutter = 18.0;
  static const radiusCard = 12.0;
  static const radiusCell = 4.0;
  static const headerHeight = 52.0;

  /// Content stops widening here, so lines stay readable on a tablet.
  static const maxContentWidth = 640.0;
}
