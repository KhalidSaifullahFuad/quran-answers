import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

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
/// optional title (or any [child], such as the search field), then actions.
///
/// Edges line up with the page gutter: a title with no back button starts on
/// it, and the last action's glyph ends on it (6dp pad + 12dp button inset).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    this.title,
    this.child,
    this.wordmark = false,
    this.showBack = true,
    this.actions = const [],
  }) : assert(title == null || child == null);

  final String? title;
  final Widget? child;
  final bool wordmark;
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return SizedBox(
      height: Space.headerHeight,
      child: Padding(
        padding: EdgeInsets.only(
          left: showBack ? 4 : Space.gutter,
          right: actions.isEmpty ? Space.gutter : 6,
        ),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: Strings.back,
                icon: const Icon(IconsaxPlusLinear.arrow_left_1),
              ),
            // The wordmark takes the title's place and scales down rather
            // than overflow on a narrow phone or at large text sizes.
            if (wordmark)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(Strings.wordmark, style: text.wordmark),
                ),
              )
            else
              Expanded(
                child:
                    child ??
                    (title == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: EdgeInsets.only(left: showBack ? 4 : 0),
                            child: Text(
                              title!,
                              style: text.screenTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
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
            height: Space.searchHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    IconsaxPlusLinear.search_normal_1,
                    size: 20,
                    color: c.fg2,
                  ),
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

/// The live search field: the [SearchFieldButton] pill, typed into.
///
/// One widget for every screen that takes a query, so the search screen and
/// the questions tab stay identical: as tall as the home pill, a clear
/// button once there is text.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        // Queries may be Arabic: Noto Sans Bengali has no Arabic glyphs, so
        // name a fallback rather than trust the platform's.
        style: t.meta.copyWith(
          fontSize: 15,
          color: c.fg1,
          fontFamilyFallback: [...Fonts.latinFallback, Fonts.arabic],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: t.meta.copyWith(fontSize: 14, color: c.fg3),
          filled: true,
          fillColor: c.track,
          isDense: true,
          // [Space.searchHeight] tall like the home pill: a 21dp line
          // (15 × 1.4) plus 13.5 above and below. Set by padding, not the
          // icon boxes, so the clear button appearing doesn't change it.
          contentPadding: const EdgeInsets.symmetric(vertical: 13.5),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 20,
            color: c.fg2,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIconConstraints: const BoxConstraints(minWidth: 44),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  tooltip: Strings.clearSearch,
                  icon: Icon(
                    IconsaxPlusLinear.close_circle,
                    size: 18,
                    color: c.fg2,
                  ),
                  onPressed: onClear,
                ),
        ),
      ),
    );
  }
}

/// An outline glyph and its filled twin, for [DuoIcon].
typedef DuoIconData = ({IconData line, IconData fill});

/// A two-tone icon: the filled glyph tinted under the outline.
///
/// Iconsax Plus ships no Bulk style, but its Bold and Linear glyphs share a
/// grid, so stacking them gives the same look in a single colour.
class DuoIcon extends StatelessWidget {
  const DuoIcon(this.icon, {super.key, this.size, this.color});

  final DuoIconData icon;
  final double? size;
  final Color? color;

  /// How strongly the fill shows under the outline.
  static const fillOpacity = .28;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final ink = color ?? theme.color!;
    // The fill is a soft brand-gold glow; the outline keeps the ink.
    final glow = AppColors.of(context).accent;
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          icon.fill,
          size: size,
          color: glow.withValues(alpha: ink.a * fillOpacity),
        ),
        Icon(icon.line, size: size, color: ink),
      ],
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

  /// Usually an [Icon] or [DuoIcon]; sized and coloured by the chip.
  final Widget icon;
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
                IconTheme.merge(
                  data: IconThemeData(
                    size: 18,
                    color: selected ? c.accent : c.fg2,
                  ),
                  child: icon,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.of(context).pill.copyWith(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : null,
                      color: selected ? c.accent : null,
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

/// A heading above a block, with an optional right-hand note or link.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.text, {
    super.key,
    this.trailing,
    this.actionLabel,
    this.onAction,
  }) : assert(trailing == null || actionLabel == null);

  final String text;
  final String? trailing;

  /// A text link on the right, e.g. `সব দেখুন`, in place of [trailing].
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(text, style: t.section)),
        if (trailing != null) Text(trailing!, style: t.meta),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(actionLabel!, style: t.link),
            ),
          ),
      ],
    );
  }
}

/// A short confirmation floating above the bottom bar: a status icon, a line
/// of text and at most one text-link action.
///
/// Compact and quiet on purpose. The SnackBar it rides in is transparent (see
/// the theme), so only this pill shows, sized to its content rather than
/// stretched across the screen like a button.
void showStatusToast(
  ScaffoldMessengerState messenger, {
  required IconData icon,
  required String text,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 2500),
        content: Center(
          child: _StatusToast(
            icon: icon,
            text: text,
            actionLabel: actionLabel,
            onAction: onAction == null
                ? null
                : () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
          ),
        ),
      ),
    );
}

class _StatusToast extends StatelessWidget {
  const _StatusToast({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, actionLabel == null ? 16 : 6, 10),
      decoration: BoxDecoration(
        color: c.selected,
        borderRadius: BorderRadius.circular(Space.radiusCard),
        // The one shadow in the app: the toast floats over content.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .45 : .12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c.fg1),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: t.meta.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: c.fg1,
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: c.fg4.withValues(alpha: .5)),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  actionLabel!,
                  style: t.link.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
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
    this.titleMaxLines,
  });

  /// Usually an [Icon] or [DuoIcon]; sized and coloured by the tile.
  final Widget icon;
  final String title;
  final String meta;
  final VoidCallback? onTap;

  /// Shown at the end of the row, e.g. a button to file it into a folder.
  final Widget? trailing;

  /// Horizontal padding. Zero when the parent already pads by the gutter.
  final double inset;

  /// Caps the title, e.g. a saved verse's translation shown as a preview.
  final int? titleMaxLines;

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
              alignment: Alignment.center,
              child: IconTheme.merge(
                data: IconThemeData(size: 16, color: c.fg3),
                child: icon,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.rowTitle,
                    maxLines: titleMaxLines,
                    overflow: titleMaxLines == null
                        ? null
                        : TextOverflow.ellipsis,
                  ),
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
