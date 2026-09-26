import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/strings.dart';
import 'core/theme/theme.dart';
import 'features/home/home_screen.dart';
import 'features/questions/category_screen.dart';
import 'features/questions/question_screen.dart';

/// Routes are paths, so a question or category can later be opened from a
/// share link or a notification without a separate lookup.
GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) =>
          CategoryScreen(categoryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/question/:slug',
      builder: (context, state) =>
          QuestionScreen(slug: state.pathParameters['slug']!),
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
