import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/strings.dart';
import '../core/theme/colors.dart';
import '../core/theme/typography.dart';

/// The four tabs, in order. Each is a branch with its own navigation stack,
/// so switching tabs keeps where the reader was in each.
enum AppTab {
  home('/', Strings.navHome, Icons.home_outlined, Icons.home_rounded),
  topics(
    '/topics',
    Strings.navTopics,
    Icons.grid_view_outlined,
    Icons.grid_view_rounded,
  ),
  surahs(
    '/surahs',
    Strings.navSurahs,
    Icons.menu_book_outlined,
    Icons.menu_book_rounded,
  ),
  saved(
    '/saved',
    Strings.navSaved,
    Icons.bookmark_border_rounded,
    Icons.bookmark_rounded,
  );

  const AppTab(this.path, this.label, this.icon, this.activeIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Opening a question, category or surah inside whichever tab is current.
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
    final t = AppText.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final (i, tab) in AppTab.values.indexed)
                Expanded(
                  child: Semantics(
                    selected: i == current,
                    button: true,
                    child: InkResponse(
                      onTap: () => onTap(i),
                      radius: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: const Cubic(.2, 0, 0, 1),
                            width: 54,
                            height: 27,
                            decoration: ShapeDecoration(
                              shape: const StadiumBorder(),
                              color: i == current
                                  ? c.selected
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              i == current ? tab.activeIcon : tab.icon,
                              size: 21,
                              color: i == current ? c.fg1 : c.fg4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: t.meta.copyWith(
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: i == current
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: i == current ? c.fg1 : c.fg4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
