import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/database_providers.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets.dart';
import 'methodology_sheet.dart';

/// The bundled fonts, their license files, and the package name each is
/// listed under on the license page.
const _fontLicenses = {
  'Noto Sans Bengali': 'assets/fonts/OFL-NotoSansBengali.txt',
  'Amiri Quran': 'assets/fonts/OFL-AmiriQuran.txt',
  'Cinzel': 'assets/fonts/OFL-Cinzel.txt',
};

/// Adds the bundled fonts' OFL texts to Flutter's license page, beside the
/// packages. The OFL requires the license to travel with the fonts. Read
/// lazily, only when the license page is opened.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: font, value: path) in _fontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString(path));
    }
  });
}

/// What the app is, where its text comes from, and whom it owes.
///
/// The translation credit is read from the content database, so it names
/// whichever translation the shipped mushaf was actually built with.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(contentMetadataProvider);
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final body = t.meta.copyWith(fontSize: 14.5, height: 1.65, color: c.fg2);

    Widget block(String title, List<String> lines) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: t.label),
          const SizedBox(height: 6),
          for (final line in lines) Text(line, style: body),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            const ContentFrame(child: ScreenHeader(title: Strings.about)),
            ContentFrame(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: AsyncBody(
                  value: meta,
                  data: (meta) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(Strings.wordmark, style: t.wordmark),
                      const SizedBox(height: 8),
                      Text(Strings.tagline, style: t.section),
                      const SizedBox(height: 28),
                      block(Strings.quranTextTitle, const [
                        Strings.quranTextSource,
                      ]),
                      block(Strings.translationTitle, [
                        [
                          ?meta['translationName'],
                          ?meta['translationAuthor'],
                        ].join(' · '),
                      ]),
                      block(Strings.fontsTitle, [
                        for (final font in _fontLicenses.keys)
                          '$font — SIL Open Font License 1.1',
                      ]),
                      block(Strings.privacyTitle, const [Strings.privacyNote]),
                      block(Strings.contentTitle, [
                        Strings.contentSummary(
                          bnDigits(meta['contentVersion'] ?? '-'),
                          bnDigits(meta['questionCount'] ?? '-'),
                          bnDigits(meta['ayahCount'] ?? '-'),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TopicChip(
                            label: Strings.methodology,
                            icon: IconsaxPlusLinear.task_square,
                            onTap: () => showMethodologySheet(context),
                          ),
                          TopicChip(
                            label: Strings.licenses,
                            icon: IconsaxPlusLinear.document_text,
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: Strings.appName,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
