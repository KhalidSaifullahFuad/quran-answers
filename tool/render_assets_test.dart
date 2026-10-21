/// Renders the launcher icons and the Play Store graphics.
///
///     flutter test tool/render_assets_test.dart
///
/// A widget test rather than an image script because the feature graphic and
/// the screenshots carry Bengali, and only Flutter's text stack shapes Bengali
/// conjuncts correctly. The screenshots are the real app on the real content
/// database, so they stay truthful after a content or design change: rerun
/// this and commit the output. Each one is framed for the listing: a two-line
/// benefit caption above the screen in a phone.
///
/// Writes into `android/app/src/main/res/mipmap-*` and `store/`.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
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
import 'package:quran_answers/core/text/numerals.dart';
import 'package:quran_answers/core/theme/colors.dart';
import 'package:quran_answers/core/theme/typography.dart';
import 'package:quran_answers/features/ayah/ayah_screen.dart';
import 'package:quran_answers/features/home/home_screen.dart';
import 'package:quran_answers/features/questions/question_providers.dart';
import 'package:quran_answers/features/settings/settings_provider.dart';
import 'package:quran_answers/features/settings/settings_screen.dart';
import 'package:quran_answers/shared/logo_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Icon canvas: the design's dark page.
const _canvas = Color(0xFF131313);

/// The logo's colours: gold mark on deep green.
const _gold = Color(0xFFF5C466);
const _green = Color(0xFF004D42);

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

/// The logo mark ([LogoMarkPainter]) over an optional [background] cut to
/// [shape]. [reach] is how far the mark may extend from the centre, as a
/// fraction of the shortest side. Without a background it is one colour on
/// transparency, so it also serves the monochrome (themed) icon.
class _IconPainter extends CustomPainter {
  const _IconPainter({
    required this.color,
    required this.reach,
    this.background,
    this.shape = _Shape.none,
  });

  final Color color;
  final double reach;

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
    LogoMarkPainter(color: color, reach: reach).paint(canvas, size);
  }

  @override
  // The generator paints several icons in a row at the same size; a stale
  // false here once left the monochrome layer in the foreground's colour.
  bool shouldRepaint(_IconPainter old) => true;
}

enum _Shape { none, circle, squircle }

/// A phone around [screen]: a dark bezel with rounded corners. [width] is the
/// outside width; the height follows the screen's aspect.
class _Phone extends StatelessWidget {
  const _Phone({required this.screen, required this.width});

  final ui.Image screen;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bezel = width * .016;
    final inner = width - 2 * bezel;
    return Container(
      width: width,
      height: inner * screen.height / screen.width + 2 * bezel,
      padding: EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(width * .085),
        border: Border.all(color: const Color(0xFF3A3A3A), width: width * .003),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * .085 - bezel),
        child: RawImage(image: screen, fit: BoxFit.fill),
      ),
    );
  }
}

/// Status bar height and gesture-bar height in dp, as on a current Android
/// phone; the app is laid out inside them.
const _statusBar = 24.0;
const _gestureBar = 16.0;

/// The system bars drawn over the app: clock and status icons on top, the
/// gesture handle below, in [dark]'s foreground.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.dark, required this.child});

  final ValueNotifier<bool> dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder(
        valueListenable: dark,
        child: child,
        builder: (context, dark, app) {
          final fg = (dark ? AppColors.dark : AppColors.light).fg1;
          return Stack(
            children: [
              app!,
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                height: _statusBar,
                child: Row(
                  children: [
                    Text(
                      '9:41',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                    const Spacer(),
                    for (final icon in [
                      Icons.signal_cellular_alt,
                      Icons.wifi,
                      Icons.battery_full,
                    ])
                      Icon(icon, size: 15, color: fg),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: _gestureBar,
                child: Center(
                  child: Container(
                    width: 108,
                    height: 4,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A faint gold glow on the canvas, so the frame is not a flat black.
const _glow = RadialGradient(
  center: Alignment(0, -.35),
  radius: .9,
  colors: [Color(0x1FF5C466), Color(0x00F5C466)],
);

/// A store screenshot: [caption]'s two lines (the second in gold) over the
/// real [screen] in a phone. 1080×1920 at a pixel ratio of 1.
class _Shot extends StatelessWidget {
  const _Shot({required this.screen, required this.caption});

  final ui.Image screen;
  final (String, String) caption;

  @override
  Widget build(BuildContext context) {
    const c = AppColors.dark;
    final style = AppText.from(
      c,
    ).tagline.copyWith(fontSize: 62, height: 1.4, fontWeight: FontWeight.w600);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _canvas, gradient: _glow),
        child: Column(
          children: [
            Container(
              height: 380,
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 52),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(caption.$1, style: style.copyWith(color: c.fg1)),
                  Text(caption.$2, style: style.copyWith(color: c.accent)),
                ],
              ),
            ),
            _Phone(screen: screen, width: 690),
          ],
        ),
      ),
    );
  }
}

/// An RGB PNG (colour type 2) from straight RGBA pixels. Play rejects alpha
/// on screenshots and the feature graphic; every pixel here is opaque, so the
/// channel is dropped, not blended.
Uint8List _opaquePng(int width, int height, ByteData rgba) {
  final rows = Uint8List(height * (width * 3 + 1));
  var o = 0;
  for (var y = 0; y < height; y++) {
    rows[o++] = 0; // filter: none
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      rows[o++] = rgba.getUint8(i);
      rows[o++] = rgba.getUint8(i + 1);
      rows[o++] = rgba.getUint8(i + 2);
    }
  }
  final out = BytesBuilder()..add(const [137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> data) {
    final body = [...type.codeUnits, ...data];
    out
      ..add(_u32(data.length))
      ..add(body)
      ..add(_u32(_crc32(body)));
  }

  chunk('IHDR', [..._u32(width), ..._u32(height), 8, 2, 0, 0, 0]);
  chunk('IDAT', ZLibCodec(level: 9).encode(rows));
  chunk('IEND', const []);
  return out.takeBytes();
}

List<int> _u32(int v) => [v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255];

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
  }
  return c ^ 0xFFFFFFFF;
}

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
    // Package fonts are in the test bundle but not loaded; without these every
    // icon is a box.
    for (final style in ['Linear', 'Bold']) {
      final loader = FontLoader('packages/iconsax_plus/IconsaxPlus$style')
        ..addFont(
          rootBundle.load('packages/iconsax_plus/fonts/IconsaxPlus$style.ttf'),
        );
      await loader.load();
    }
  });

  /// Whatever is under [boundary], at [pixelRatio].
  Future<ui.Image> snapshot(
    WidgetTester tester, {
    double pixelRatio = 1,
  }) async {
    final image = await tester.runAsync(() {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return render.toImage(pixelRatio: pixelRatio);
    });
    return image!;
  }

  /// Writes whatever is under [boundary] to [path] at [pixelRatio]; [opaque]
  /// drops the alpha channel.
  Future<void> capture(
    WidgetTester tester,
    String path, {
    double pixelRatio = 1,
    bool opaque = false,
  }) async {
    final image = await snapshot(tester, pixelRatio: pixelRatio);
    await tester.runAsync(() async {
      final bytes = opaque
          ? _opaquePng(image.width, image.height, (await image.toByteData())!)
          : (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!.buffer.asUint8List();
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
    });
    image.dispose();
  }

  Future<void> paintTo(
    WidgetTester tester,
    String path,
    int px,
    _IconPainter painter,
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
        const _IconPainter(
          color: _gold,
          reach: .36,
          background: _green,
          shape: _Shape.squircle,
        ),
      );
      await paintTo(
        tester,
        '$dir/ic_launcher_round.png',
        legacy,
        const _IconPainter(
          color: _gold,
          reach: .36,
          background: _green,
          shape: _Shape.circle,
        ),
      );
      // Adaptive foreground: 108dp, of which the launcher mask shows the
      // middle 72dp at most and guarantees only a 66dp circle. The book's
      // corners, at .29 × 108 ≈ 31dp from centre, stay inside that circle.
      // The green ground is the background layer (ic_launcher_background).
      await paintTo(
        tester,
        '$dir/ic_launcher_foreground.png',
        layer,
        const _IconPainter(color: _gold, reach: .29),
      );
      // Android 13 themed icons: the system tints this single-colour layer.
      await paintTo(
        tester,
        '$dir/ic_launcher_monochrome.png',
        layer,
        const _IconPainter(color: Colors.white, reach: .29),
      );
    }
  });

  testWidgets('splash mark', (tester) async {
    addTearDown(tester.view.reset);
    // Dark-mode splash icon. Android 12 draws an icon without a background
    // at 288dp and shows its middle 192dp circle; the book's corners, at
    // .29 × 288 ≈ 84dp from centre, stay inside it. Pre-12 centres the same
    // file on the launch window at its own size. Kept out of drawable-night
    // so the resource has a default; only night themes reference it.
    for (final MapEntry(key: density, value: (legacy, _))
        in _densities.entries) {
      await paintTo(
        tester,
        '$_res/drawable-$density/splash_mark.png',
        legacy * 6,
        const _IconPainter(color: _gold, reach: .29),
      );
    }
  });

  testWidgets('store icon', (tester) async {
    addTearDown(tester.view.reset);
    // Play applies its own mask to a full-bleed square, so this is the logo
    // full-bleed: the mark at the author's scale on the green.
    await paintTo(
      tester,
      'store/icon-512.png',
      512,
      const _IconPainter(color: _gold, reach: .38, background: _green),
    );
  });

  testWidgets('phone screenshots and feature graphic', (tester) async {
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
    late final QuestionIndex index;
    await tester.runAsync(() async {
      index = await container.read(questionIndexProvider.future);
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

    // A current phone: 20:9, 411dp wide, with status and gesture bars. The
    // store frame, not this, is Play's 9:16.
    const pixelRatio = 1080 / 411;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = pixelRatio;
    tester.view.padding = tester.view.viewPadding = const FakeViewPadding(
      top: _statusBar * pixelRatio,
      bottom: _gestureBar * pixelRatio,
    );
    final dark = ValueNotifier(true);
    addTearDown(dark.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: _SystemBars(
          dark: dark,
          child: UncontrolledProviderScope(
            container: container,
            child: const QuranAnswersApp(),
          ),
        ),
      ),
    );
    await tester.pump();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    // The header art decodes off the test clock; without this home has none.
    // Same key as home's Image.asset: half the width, max 210dp, cacheWidth.
    await tester.runAsync(
      () => precacheImage(
        ResizeImage(
          const AssetImage('assets/images/home_hero.webp'),
          width: (math.min(411 * .5, 210) * pixelRatio).round(),
        ),
        tester.element(find.byType(HomeScreen)),
      ),
    );

    // Store order: the first three show without scrolling, so they carry
    // what sets the app apart: answers from the Quran, the proof in full,
    // and the ayah in its context.
    final shots = <(String, (String, String), ui.Image)>[];
    for (final (name, caption, mode, path) in [
      (
        'home',
        ('ইসলামের প্রশ্ন,', 'উত্তর কুরআনের আয়াতে'),
        ThemeMode.dark,
        '/',
      ),
      (
        'question',
        ('প্রতিটি উত্তরের প্রমাণ', 'আরবি আয়াত ও অনুবাদসহ'),
        ThemeMode.dark,
        '/question/$slug',
      ),
      (
        'ayah',
        ('আগে-পরের আয়াতসহ', 'প্রসঙ্গ বুঝে পড়ুন'),
        ThemeMode.light,
        '/ayah/54/17',
      ),
      (
        'topics',
        (
          '${bnDigits(index.categories.length)}টি বিষয়ে সাজানো',
          '${bnDigits(index.questions.length)}টি প্রশ্ন ও উত্তর',
        ),
        ThemeMode.dark,
        '/topics',
      ),
      (
        'questions',
        ('যেকোনো শব্দে খুঁজুন', 'প্রশ্নে বা উত্তরে'),
        ThemeMode.light,
        '/questions',
      ),
      (
        'surahs',
        ('সূরা ধরে দেখুন', 'কোন আয়াত কোন প্রশ্নের প্রমাণ'),
        ThemeMode.light,
        '/surahs',
      ),
    ]) {
      await container.read(settingsProvider.notifier).setThemeMode(mode);
      dark.value = mode == ThemeMode.dark;
      router.go(path);
      // Frame by frame: the theme and the route both animate, and a single
      // long pump only starts their controllers.
      for (var f = 0; f < 12; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      shots.add((
        name,
        caption,
        await snapshot(tester, pixelRatio: pixelRatio),
      ));
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

    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 1
      ..resetPadding()
      ..resetViewPadding();
    for (final old in Directory('store/screenshots').listSync()) {
      old.deleteSync();
    }
    for (final (i, (name, caption, screen)) in shots.indexed) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: _Shot(screen: screen, caption: caption),
        ),
      );
      await capture(
        tester,
        'store/screenshots/phone-${i + 1}-$name.png',
        opaque: true,
      );
    }

    // Feature graphic: the name and promise on the left, the real home
    // screen on the right in a phone running off the bottom edge.
    tester.view.physicalSize = const Size(1024, 500);
    const c = AppColors.dark;
    final t = AppText.from(c);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: _canvas,
              gradient: RadialGradient(
                center: Alignment(.55, 0),
                radius: .8,
                colors: [Color(0x24F5C466), Color(0x00F5C466)],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: 72,
                  top: 0,
                  bottom: 0,
                  width: 560,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const LogoMark(size: 64, color: _gold),
                          const SizedBox(width: 18),
                          Text(
                            Strings.wordmark,
                            style: t.wordmark.copyWith(fontSize: 48),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        Strings.tagline,
                        style: t.tagline.copyWith(
                          fontSize: 30,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: c.fg1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${bnDigits(index.questions.length)}টি প্রশ্ন'
                        '  ·  অফলাইন  ·  বিজ্ঞাপন নেই',
                        style: t.tagline.copyWith(
                          fontSize: 24,
                          height: 1.5,
                          color: c.fg2,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 80,
                  top: 48,
                  child: _Phone(screen: shots.first.$3, width: 290),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await capture(tester, 'store/feature-graphic.png', opaque: true);
    for (final (_, _, screen) in shots) {
      screen.dispose();
    }
  });
}
