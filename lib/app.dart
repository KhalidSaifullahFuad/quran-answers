import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/strings.dart';
import 'core/theme/theme.dart';
import 'features/home/home_screen.dart';
import 'features/questions/category_screen.dart';
import 'features/questions/question_screen.dart';
import 'features/saved/saved_screen.dart';
import 'features/search/search_screen.dart';
import 'features/surahs/surahs_screen.dart';
import 'features/topics/topics_screen.dart';
import 'shared/navigation.dart';

/// Opened from any tab, and registered under each of them so the bottom bar
/// stays visible and back returns to that tab's own screen.
List<RouteBase> _detailRoutes() => [
  GoRoute(
    path: 'question/:slug',
    builder: (context, state) =>
        QuestionScreen(slug: state.pathParameters['slug']!),
  ),
  GoRoute(
    path: 'category/:id',
    builder: (context, state) =>
        CategoryScreen(categoryId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: 'surah/:number',
    builder: (context, state) => SurahQuestionsScreen(
      number: int.parse(state.pathParameters['number']!),
    ),
  ),
  GoRoute(path: 'search', builder: (context, state) => const SearchScreen()),
];

/// Routes are paths, so a question or category can later be opened from a
/// share link or a notification without a separate lookup.
GoRouter buildRouter() => GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => Scaffold(
        body: shell,
        bottomNavigationBar: AppBottomNav(
          current: shell.currentIndex,
          // Tapping the current tab again returns it to its first screen.
          onTap: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      ),
      branches: [
        for (final tab in AppTab.values)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: tab.path,
                builder: (context, state) => switch (tab) {
                  AppTab.home => const HomeScreen(),
                  AppTab.topics => const TopicsScreen(),
                  AppTab.surahs => const SurahsScreen(),
                  AppTab.saved => const SavedScreen(),
                },
                routes: _detailRoutes(),
              ),
            ],
          ),
      ],
    ),
  ],
);

class QuranAnswersApp extends StatefulWidget {
  const QuranAnswersApp({super.key});

  @override
  State<QuranAnswersApp> createState() => _QuranAnswersAppState();
}

class _QuranAnswersAppState extends State<QuranAnswersApp> {
  /// Owned by the widget rather than global, so each test gets a fresh stack.
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      // The design is dark-first; the light "paper" theme follows the system
      // until the settings screen offers a choice.
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
