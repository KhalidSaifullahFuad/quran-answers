import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/db/content_db.dart';
import '../../core/db/content_queries.dart';
import '../../core/db/database_providers.dart';
import '../../core/strings.dart';
import '../../core/text/numerals.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/navigation.dart';
import '../../shared/widgets.dart';
import 'settings_provider.dart';

/// The verse the text-size preview shows. Read from the mushaf like every
/// other verse — Arabic is never written into the code.
final previewAyahProvider = FutureProvider<Ayah?>((ref) async {
  final db = await ref.watch(contentDatabaseProvider.future);
  return db.ayahAt(1, 1);
});

/// Theme and reading text sizes, with a live preview, and the way to the
/// credits.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final preview = ref.watch(previewAyahProvider).value;
    final c = AppColors.of(context);
    final t = AppText.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            const ContentFrame(child: ScreenHeader(title: Strings.settings)),
            ContentFrame(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const SectionTitle(Strings.appearance),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (mode, label, icon) in const [
                          (
                            ThemeMode.system,
                            Strings.themeSystem,
                            IconsaxPlusLinear.autobrightness,
                          ),
                          (
                            ThemeMode.light,
                            Strings.themeLight,
                            IconsaxPlusLinear.sun_1,
                          ),
                          (
                            ThemeMode.dark,
                            Strings.themeDark,
                            IconsaxPlusLinear.moon,
                          ),
                        ])
                          TopicChip(
                            label: label,
                            icon: Icon(icon),
                            selected: settings.themeMode == mode,
                            onTap: () => notifier.setThemeMode(mode),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _ScaleSlider(
                      label: Strings.arabicSize,
                      value: settings.arabicScale,
                      range: Settings.arabicRange,
                      onChanged: notifier.setArabicScale,
                    ),
                    const SizedBox(height: 12),
                    _ScaleSlider(
                      label: Strings.bengaliSize,
                      value: settings.bengaliScale,
                      range: Settings.bengaliRange,
                      onChanged: notifier.setBengaliScale,
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        decoration: BoxDecoration(
                          color: c.evidence,
                          borderRadius: BorderRadius.circular(Space.radiusCard),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ArabicText(preview.textUthmani, ayah: preview.ayah),
                            const SizedBox(height: 10),
                            Text(preview.translationBn, style: t.translation),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            ContentFrame(
              child: Column(
                children: [
                  _LinkRow(
                    icon: IconsaxPlusLinear.info_circle,
                    label: Strings.about,
                    onTap: context.openAbout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleSlider extends StatelessWidget {
  const _ScaleSlider({
    required this.label,
    required this.value,
    required this.range,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ({double min, double max}) range;
  final ValueChanged<double> onChanged;

  /// Steps of 5%.
  int get _divisions => ((range.max - range.min) / .05).round();

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(label, trailing: '${bnDigits((value * 100).round())}%'),
        Semantics(
          label: label,
          child: Slider(
            value: value,
            min: range.min,
            max: range.max,
            divisions: _divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          children: [
            Text(Strings.sizeSample, style: t.meta.copyWith(fontSize: 12)),
            const Spacer(),
            Text(Strings.sizeSample, style: t.meta.copyWith(fontSize: 18)),
          ],
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.fg2),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: t.rowTitle)),
            Icon(IconsaxPlusLinear.arrow_right_3, color: c.fg3),
          ],
        ),
      ),
    );
  }
}
