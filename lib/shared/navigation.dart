import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../core/strings.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';

/// The five tabs, in order. Each is a branch with its own navigation stack,
/// so switching tabs keeps where the reader was in each.
enum AppTab {
  home('/', Strings.navHome, IconsaxPlusLinear.home_2, IconsaxPlusBold.home_2),
  questions(
    '/questions',
    Strings.navQuestions,
    IconsaxPlusLinear.message_question,
    IconsaxPlusBold.message_question,
  ),
  topics(
    '/topics',
    Strings.navTopics,
    IconsaxPlusLinear.category,
    IconsaxPlusBold.category,
  ),
  surahs(
    '/surahs',
    Strings.navSurahs,
    IconsaxPlusLinear.book_1,
    IconsaxPlusBold.book_1,
  ),
  saved(
    '/saved',
    Strings.navSaved,
    IconsaxPlusLinear.archive_1,
    IconsaxPlusBold.archive_1,
  );

  const AppTab(this.path, this.label, this.icon, this.activeIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Opening a question, category, surah, verse or search inside whichever tab is current.
///
/// Detail routes are registered under every tab, so the bottom bar stays in
/// place and back returns to the tab's own screen. The destination path is
/// therefore relative to the current tab.
extension AppNavigation on BuildContext {
  String get _tabPrefix {
    final first = GoRouterState.of(this).uri.pathSegments.firstOrNull;
    for (final tab in AppTab.values) {
      if (tab != AppTab.home && tab.path == '/$first') return tab.path;
    }
    return '';
  }

  void openQuestion(String slug) => push('$_tabPrefix/question/$slug');

  void openCategory(String id) => push('$_tabPrefix/category/$id');

  void openSurah(int number) => push('$_tabPrefix/surah/$number');

  /// [query], when given, is typed into the field and searched at once.
  void openSearch({String? query}) => push(
    Uri(
      path: '$_tabPrefix/search',
      queryParameters: query == null ? null : {'q': query},
    ).toString(),
  );

  void openAyah(int surah, int ayah) => push('$_tabPrefix/ayah/$surah/$ayah');

  /// Steps to a neighbouring verse without growing the back stack, so back
  /// leaves the ayah screen rather than walking through every verse read.
  void replaceAyah(int surah, int ayah) =>
      pushReplacement('$_tabPrefix/ayah/$surah/$ayah');

  void openSettings() => push('$_tabPrefix/settings');

  void openAbout() => push('$_tabPrefix/about');

  void openHistory() => push('$_tabPrefix/history');

  /// Steps to another question without growing the back stack, so back
  /// returns to the list the reader came from.
  void replaceQuestion(String slug) =>
      pushReplacement('$_tabPrefix/question/$slug');

  /// Switches to [tab] at its first screen, as tapping it in the bottom bar does.
  void goTab(AppTab tab) => go(tab.path);
}

/// The bottom bar from the design: an icon in a pill that fills when active,
/// label below, a hairline on top. Outline icons swap for filled ones when
/// selected.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (final (i, tab) in AppTab.values.indexed)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: i == current,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab of the bottom bar, with its micro-animation: on a tap the icon
/// dips and settles, and the pill grows out from the icon when the tab
/// becomes selected. Motion is dropped when the system asks to reduce it.
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  /// Material's emphasized easing, as everywhere else in the app.
  static const _ease = Cubic(.2, 0, 0, 1);

  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  /// Press in, overshoot a touch, settle.
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: .84,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: .84, end: 1.08).chain(CurveTween(curve: _ease)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.08,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
  ]).animate(_pop);

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _tap() {
    if (!MediaQuery.disableAnimationsOf(context)) _pop.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final selected = widget.selected;
    final ink = selected ? c.fg1 : c.fg3;
    Duration ms(int n) => still ? Duration.zero : Duration(milliseconds: n);

    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: _tap,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 30,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grows from the icon's width to the full pill.
                  AnimatedContainer(
                    duration: ms(240),
                    curve: _ease,
                    width: selected ? 60 : 30,
                    height: 30,
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: selected
                          ? c.selected
                          : c.selected.withValues(alpha: 0),
                    ),
                  ),
                  ScaleTransition(
                    scale: _scale,
                    child: AnimatedSwitcher(
                      duration: ms(160),
                      child: Icon(
                        selected ? widget.tab.activeIcon : widget.tab.icon,
                        key: ValueKey(selected),
                        size: 24,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: ms(160),
              style: t.meta.copyWith(
                fontSize: 12.5,
                // Room for Bengali vowel signs above and below the line.
                height: 1.3,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: ink,
              ),
              child: Text(
                widget.tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
