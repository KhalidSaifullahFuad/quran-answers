import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_answers/features/settings/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults follow the system at design size', () async {
    final container = await containerWith({});
    expect(container.read(settingsProvider), const Settings());
  });

  test('changes are written and read back by a fresh container', () async {
    final first = await containerWith({});
    final notifier = first.read(settingsProvider.notifier);
    await notifier.setThemeMode(ThemeMode.light);
    await notifier.setArabicScale(1.3);
    await notifier.setBengaliScale(1.1);

    final prefs = await SharedPreferences.getInstance();
    final second = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    expect(
      second.read(settingsProvider),
      const Settings(
        themeMode: ThemeMode.light,
        arabicScale: 1.3,
        bengaliScale: 1.1,
      ),
    );
  });

  test(
    'stored values outside the range are clamped, unknown modes ignored',
    () async {
      final container = await containerWith({
        'themeMode': 'sepia',
        'arabicScale': 9.0,
        'bengaliScale': .1,
      });
      final s = container.read(settingsProvider);
      expect(s.themeMode, ThemeMode.system);
      expect(s.arabicScale, Settings.arabicRange.max);
      expect(s.bengaliScale, Settings.bengaliRange.min);
    },
  );
}
