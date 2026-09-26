import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/strings.dart';
import '../core/text/numerals.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';

/// Primitives from the imported design system, rebuilt in Flutter.
///
/// Flat throughout: fills a step off the canvas, pill shapes, no borders or
/// shadows. Press feedback is the Material ripple and nothing more.

/// Centers content and caps its width, so lines stay readable on a tablet.
class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// The 52dp bar at the top of every screen: back button or wordmark, an
/// optional title, then actions.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    this.title,
    this.wordmark = false,
    this.showBack = true,
    this.actions = const [],
  });

  final String? title;
  final bool wordmark;
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return SizedBox(
      height: Space.headerHeight,
      child: Padding(
        padding: EdgeInsets.only(left: showBack ? 4 : Space.gutter, right: 6),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: Strings.back,
                icon: const Icon(Icons.chevron_left_rounded, size: 30),
              ),
            if (wordmark) Text(Strings.wordmark, style: text.wordmark),
            Expanded(
              child: title == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        title!,
                        style: text.screenTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// A citation in a pill: `Al-Qamar · ৫৪:১৫`.
class RefPill extends StatelessWidget {
  const RefPill({super.key, required this.label, this.icon, this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.track,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 25),
          padding: EdgeInsets.fromLTRB(icon == null ? 12 : 10, 2, 12, 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: c.fg1),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppText.of(context).pill,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The search field as a tappable pill. The field itself lives on the search
/// screen; this only leads there.
class SearchFieldButton extends StatelessWidget {
  const SearchFieldButton({super.key, required this.hint, this.onTap});

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: hint,
      child: Material(
        color: c.track,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 41,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 20, color: c.fg2),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.of(
                        context,
                      ).meta.copyWith(fontSize: 14, color: c.fg3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pill with an icon: a topic shortcut on home, a folder filter on the saved
/// tab.
class TopicChip extends StatelessWidget {
  const TopicChip({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? c.selected : c.track,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            height: 35,
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: selected ? c.fg1 : c.fg2),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.of(context).pill.copyWith(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A heading above a block, with an optional right-hand note.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(text, style: t.section)),
        if (trailing != null) Text(trailing!, style: t.meta),
      ],
    );
  }
}

/// A question in a list: icon in a circle, question text, meta line.
class QuestionTile extends StatelessWidget {
  const QuestionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.meta,
    this.onTap,
    this.inset = Space.gutter,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String meta;
  final VoidCallback? onTap;

  /// Shown at the end of the row, e.g. a button to file it into a folder.
  final Widget? trailing;

  /// Horizontal padding. Zero when the parent already pads by the gutter.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: inset, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: c.track, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: c.fg3),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.rowTitle),
                  const SizedBox(height: 4),
                  Text(meta, style: t.meta.copyWith(letterSpacing: .2)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Qur'anic text, right to left, optionally closed with the ayah ornament.
///
/// Direction is set explicitly rather than inherited: the app's ambient
/// direction is left to right, and Arabic laid out LTR puts the verse-end mark
/// on the wrong side and breaks mixed-direction line wrapping.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.ayah,
    this.style,
    this.textAlign = TextAlign.right,
    this.maxLines,
  });

  final String text;
  final int? ayah;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      // A no-break space: an ordinary one lets the ornament wrap onto a line
      // of its own, detached from the verse it closes.
      ayah == null ? text : '$text ${ayahEndMark(ayah!)}',
      style: style ?? AppText.of(context).arabic,
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      locale: const Locale('ar'),
    );
  }
}

/// Loading, error and data states of an [AsyncValue] with the app's styling.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(T value) data;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.all(Space.gutter),
        child: Text(
          '${Strings.loadFailed}\n$error',
          style: AppText.of(context).meta,
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    };
  }
}

/// A surah number in the design's vertical hexagon.
class HexBadge extends StatelessWidget {
  const HexBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipPath(
      clipper: const _HexClipper(),
      child: Container(
        width: 33,
        height: 36,
        color: c.raised,
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppText.of(context).pill.copyWith(fontSize: 13.5, height: 1.1),
        ),
      ),
    );
  }
}

/// `polygon(50% 0, 96% 25%, 96% 75%, 50% 100%, 4% 75%, 4% 25%)` from the
/// design tokens.
class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();

  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * .5, 0)
    ..lineTo(s.width * .96, s.height * .25)
    ..lineTo(s.width * .96, s.height * .75)
    ..lineTo(s.width * .5, s.height)
    ..lineTo(s.width * .04, s.height * .75)
    ..lineTo(s.width * .04, s.height * .25)
    ..close();

  @override
  bool shouldReclip(_HexClipper oldClipper) => false;
}
