/// Renders the launcher icons and the Play Store graphics.
///
///     flutter test tool/render_assets_test.dart
///
/// A widget test rather than an image script because the feature graphic and
/// the screenshots carry Bengali, and only Flutter's text stack shapes Bengali
/// conjuncts correctly. The screenshots are the real app on the real content
/// database, so they stay truthful after a content or design change: rerun
/// this and commit the output.
///
/// Writes into `android/app/src/main/res/mipmap-*` and `store/`.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_answers/app.dart';
import 'package:quran_answers/core/db/content_db.dart';
import 'package:quran_answers/core/db/database_providers.dart';
import 'package:quran_answers/core/strings.dart';
import 'package:quran_answers/core/theme/colors.dart';
import 'package:quran_answers/core/theme/typography.dart';
import 'package:quran_answers/features/ayah/ayah_screen.dart';
import 'package:quran_answers/features/home/home_screen.dart';
import 'package:quran_answers/features/questions/question_providers.dart';
import 'package:quran_answers/features/settings/settings_provider.dart';
import 'package:quran_answers/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Icon canvas: the design's dark page.
const _canvas = Color(0xFF131313);

/// The mark: the dark theme's scripture green.
const _mark = Color(0xFF20C08D);

const _res = 'android/app/src/main/res';

/// Launcher icon sizes in px per density: legacy (48dp) and adaptive layer
/// (108dp).
const _densities = {
  'mdpi': (48, 108),
  'hdpi': (72, 162),
  'xhdpi': (96, 216),
  'xxhdpi': (144, 324),
  'xxxhdpi': (192, 432),
};

/// A rub el hizb (۞) — the outline of two overlapping squares around a disc —
/// the ornament that marks divisions of the mushaf.
///
/// [radius] is the distance from the centre to a star point, as a fraction of
/// the shortest side. Drawn in one colour on transparency, so the same painter
/// serves the monochrome (themed) icon.
class _StarPainter extends CustomPainter {
  const _StarPainter({
    required this.color,
    required this.radius,
    this.background,
    this.shape = _Shape.none,
  });

  final Color color;
  final double radius;

  final Color? background;
  final _Shape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final c = size.center(Offset.zero);
    if (background case final bg?) {
      final paint = Paint()..color = bg;
      switch (shape) {
        case _Shape.none:
          canvas.drawRect(Offset.zero & size, paint);
        case _Shape.circle:
          canvas.drawCircle(c, side / 2, paint);
        case _Shape.squircle:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Offset.zero & size,
              Radius.circular(side * .22),
            ),
            paint,
          );
      }
    }

    final r = radius * side;
    Path square(double turn) {
      final p = Path();
      for (var i = 0; i < 4; i++) {
        final a = turn + i * math.pi / 2;
        final pt = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    }

    final star = Path.combine(
      PathOperation.union,
      square(-math.pi / 2),
      square(-math.pi / 4),
    );
    canvas.drawPath(
      star,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .15
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(c, r * .3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

enum _Shape { none, circle, squircle }

Future<void> _font(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(p).readAsBytesSync())),
    );
  }
  await loader.load();
}

void main() {
  const materialFonts = 'C:/dev/flutter/bin/cache/artifacts/material_fonts';
  final boundary = GlobalKey();

  setUpAll(() async {
    await _font('NotoSansBengali', [
      'assets/fonts/NotoSansBengali-Regular.ttf',
      'assets/fonts/NotoSansBengali-Medium.ttf',
      'assets/fonts/NotoSansBengali-SemiBold.ttf',
    ]);
    await _font('AmiriQuran', ['assets/fonts/AmiriQuran-Regular.ttf']);
    await _font('Cinzel', ['assets/fonts/Cinzel-Variable.ttf']);
    await _font('Roboto', [
      '$materialFonts/roboto-regular.ttf',
      '$materialFonts/roboto-medium.ttf',
    ]);
    await _font('MaterialIcons', ['$materialFonts/materialicons-regular.otf']);
  });

  /// Writes whatever is under [boundary] to [path] at [pixelRatio].
  Future<void> capture(
    WidgetTester tester,
    String path, {
    double pixelRatio = 1,
  }) async {
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: pixelRatio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> paintTo(
    WidgetTester tester,
    String path,
    int px,
    _StarPainter painter,
  ) async {
    tester.view.physicalSize = Size.square(px.toDouble());
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: CustomPaint(painter: painter, size: Size.infinite),
      ),
    );
    await capture(tester, path);
  }

  testWidgets('launcher icons', (tester) async {
    addTearDown(tester.view.reset);
    for (final MapEntry(key: density, value: (legacy, layer))
        in _densities.entries) {
      final dir = '$_res/mipmap-$density';
      // Pre-adaptive launchers draw the file as is, so it carries its own
      // shape and a smaller mark.
      await paintTo(
        tester,
        '$dir/ic_launcher.png',
        legacy,
        const _StarPainter(
          color: _mark,
          radius: .34,
          background: _canvas,
          shape: _Shape.squircle,
        ),
      );
      await paintTo(
        tester,
        '$dir/ic_launcher_round.png',
        legacy,
        const _StarPainter(
          color: _mark,
          radius: .34,
          background: _canvas,
          shape: _Shape.circle,
        ),
      );
      // Adaptive foreground: 108dp, of which the launcher mask shows the
      // middle 72dp at most and guarantees only a 66dp circle. A point at
      // .27 × 108 ≈ 29dp from centre stays inside that circle.
      await paintTo(
        tester,
        '$dir/ic_launcher_foreground.png',
        layer,
        const _StarPainter(color: _mark, radius: .27),
      );
      // Android 13 themed icons: the system tints this single-colour layer.
      await paintTo(
        tester,
        '$dir/ic_launcher_monochrome.png',
        layer,
        const _StarPainter(color: Colors.white, radius: .27),
      );
    }
  });

  testWidgets('store icon and feature graphic', (tester) async {
    addTearDown(tester.view.reset);
    // Play applies its own mask to a full-bleed square, the way a launcher
    // masks the adaptive icon, so the mark keeps the adaptive proportion
    // (.27 of 108dp ≈ .4 of the 72dp that shows), a touch smaller
    // since nothing clips the stroke here.
    await paintTo(
      tester,
      'store/icon-512.png',
      512,
      const _StarPainter(color: _mark, radius: .38, background: _canvas),
    );

    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1;
    final t = AppText.from(AppColors.dark);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: _canvas,
            child: Row(
              children: [
                const SizedBox(width: 84),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Strings.wordmark,
                        style: t.wordmark.copyWith(fontSize: 46),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        Strings.tagline,
                        style: t.tagline.copyWith(
                          fontSize: 30,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark.fg1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 360,
                  height: 500,
                  child: CustomPaint(
                    painter: _StarPainter(color: _mark, radius: .36),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
    await capture(tester, 'store/feature-graphic.png');
  });

  testWidgets('phone screenshots', (tester) async {
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('store_shots');
    // A test in all but location: it lives in tool/ so `flutter test` does
    // not rewrite the assets on every run.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDirectoryProvider.overrideWith((ref) async => dir),
        databaseOpenerProvider.overrideWithValue(NativeDatabase.new),
      ],
    );
    const slug = 'muddakkir-al-qamar';
    await tester.runAsync(() async {
      final index = await container.read(questionIndexProvider.future);
      await container.read(recentSlugsProvider.future);
      await container.read(surahsProvider.future);
      for (final q in index.questions) {
        await container.read(questionDetailProvider(q.slug).future);
        await container.read(isBookmarkedProvider(q.slug).future);
      }
      final detail = await container.read(questionDetailProvider(slug).future);
      for (final a in detail!.ayahs) {
        await container.read(isAyahBookmarkedProvider(a.id).future);
      }
      await container.read(ayahPageProvider((surah: 54, ayah: 17)).future);
      await container.read(isAyahBookmarkedProvider(ayahId(54, 17)).future);
      await container.read(previewAyahProvider.future);
    });

    // 9:16, as Play requires sides within a 2:1 ratio; 411dp wide like a
    // common phone.
    const pixelRatio = 1080 / 411;
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = pixelRatio;
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: UncontrolledProviderScope(
          container: container,
          child: const QuranAnswersApp(),
        ),
      ),
    );
    await tester.pump();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

    for (final (i, name, mode, path) in [
      (1, 'home', ThemeMode.dark, '/'),
      (2, 'question', ThemeMode.dark, '/question/$slug'),
      (3, 'ayah', ThemeMode.light, '/ayah/54/17'),
      (4, 'surahs', ThemeMode.light, '/surahs'),
      (5, 'settings', ThemeMode.dark, '/settings'),
    ]) {
      await container.read(settingsProvider.notifier).setThemeMode(mode);
      router.go(path);
      // Frame by frame: the theme and the route both animate, and a single
      // long pump only starts their controllers.
      for (var f = 0; f < 12; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await capture(
        tester,
        'store/screenshots/phone-$i-$name.png',
        pixelRatio: pixelRatio,
      );
    }

    // Opening the question recorded a view; let that write finish before the
    // test ends, or its pending work fails the run.
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
  });
}
