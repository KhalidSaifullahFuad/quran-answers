import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../core/strings.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';
import 'widgets.dart';

/// A screen with a fixed [AppHeader] on top and a [body] that scrolls under
/// it. The header owns the status-bar inset, so its tint reaches the top
/// edge; the body keeps the bottom and side insets.
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.header, required this.body});

  final AppHeader header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          header,
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: SafeArea(top: false, child: body),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 64dp top bar: back button, a title (or any [child], such as the
/// search field), then actions. Stays put while the page scrolls; once
/// content is underneath it takes the card tint and a hairline edge, the
/// Material scrolled-under state.
///
/// [bottom] sits inside the bar, under the title row, and shares its tint:
/// for controls that stay in reach while a list scrolls.
///
/// Edges line up with the page gutter: a title with no back button starts on
/// it, and the last action's glyph ends on it (6dp pad + 12dp button inset).
class AppHeader extends StatefulWidget {
  const AppHeader({
    super.key,
    this.title,
    this.child,
    this.showBack = true,
    this.actions = const [],
    this.bottom,
  }) : assert(title == null || child == null);

  final String? title;
  final Widget? child;
  final bool showBack;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  ScrollNotificationObserverState? _observer;

  /// Content has scrolled under the bar.
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll(ScrollNotification n) {
    // Only the page's own vertical scroll: not chip rows, not nested lists.
    if (n is! ScrollUpdateNotification ||
        !defaultScrollNotificationPredicate(n) ||
        n.metrics.axis != Axis.vertical) {
      return;
    }
    final under = n.metrics.extentBefore > 0;
    if (under != _scrolledUnder) setState(() => _scrolledUnder = under);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final w = widget;
    final overlay =
        Theme.of(context).appBarTheme.systemOverlayStyle ??
        SystemUiOverlayStyle.light;

    final title =
        w.child ??
        (w.title == null
            ? const SizedBox.shrink()
            : Text(
                w.title!,
                style: t.barTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _scrolledUnder ? c.card : c.background,
          border: Border(
            bottom: BorderSide(
              color: _scrolledUnder
                  ? c.divider
                  : c.divider.withValues(alpha: 0),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: MediaQuery.paddingOf(context).top + Space.barTopInset,
            ),
            ContentFrame(
              child: SizedBox(
                height: Space.barHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: w.showBack ? 4 : Space.gutter,
                    right: w.actions.isEmpty ? Space.gutter : 6,
                  ),
                  child: Row(
                    children: [
                      if (w.showBack) ...[
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          tooltip: Strings.back,
                          icon: const Icon(IconsaxPlusLinear.arrow_left_1),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: title),
                      for (final (i, action) in w.actions.indexed) ...[
                        if (i > 0) const SizedBox(width: 4),
                        action,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (w.bottom case final bottom?) ContentFrame(child: bottom),
          ],
        ),
      ),
    );
  }
}
