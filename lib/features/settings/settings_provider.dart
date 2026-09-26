import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded once in `main` before the first frame, so the first frame is already
/// drawn in the reader's chosen theme and text size.
///
/// Overridden in `main` and in tests; reading it without an override is a
/// wiring mistake, not a state the app can recover from.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Reader preferences. Small and flat, so SharedPreferences rather than a
/// table in the user database.
@immutable
class Settings {
  const Settings({
    this.themeMode = ThemeMode.system,
    this.arabicScale = 1.0,
    this.bengaliScale = 1.0,
  });

  final ThemeMode themeMode;

  /// Multiplies the size of Qur'anic text.
  final double arabicScale;

  /// Multiplies the size of the reading text — questions, answers and
  /// translations. Interface labels keep their size, so the layout holds.
  final double bengaliScale;

  static const arabicRange = (min: .8, max: 1.6);
  static const bengaliRange = (min: .85, max: 1.4);

  Settings copyWith({
    ThemeMode? themeMode,
    double? arabicScale,
    double? bengaliScale,
  }) => Settings(
    themeMode: themeMode ?? this.themeMode,
    arabicScale: arabicScale ?? this.arabicScale,
    bengaliScale: bengaliScale ?? this.bengaliScale,
  );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.themeMode == themeMode &&
      other.arabicScale == arabicScale &&
      other.bengaliScale == bengaliScale;

  @override
  int get hashCode => Object.hash(themeMode, arabicScale, bengaliScale);
}

abstract final class _Keys {
  static const themeMode = 'themeMode';
  static const arabicScale = 'arabicScale';
  static const bengaliScale = 'bengaliScale';
}

class SettingsNotifier extends Notifier<Settings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Settings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final mode = prefs.getString(_Keys.themeMode);
    // Clamped on the way in: a range narrowed in a later release must not
    // leave an old stored value outside it.
    double scale(String key, ({double min, double max}) range) =>
        (prefs.getDouble(key) ?? 1.0).clamp(range.min, range.max);
    return Settings(
      themeMode: ThemeMode.values.asNameMap()[mode] ?? ThemeMode.system,
      arabicScale: scale(_Keys.arabicScale, Settings.arabicRange),
      bengaliScale: scale(_Keys.bengaliScale, Settings.bengaliRange),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_Keys.themeMode, mode.name);
  }

  Future<void> setArabicScale(double value) async {
    state = state.copyWith(arabicScale: value);
    await _prefs.setDouble(_Keys.arabicScale, value);
  }

  Future<void> setBengaliScale(double value) async {
    state = state.copyWith(bengaliScale: value);
    await _prefs.setDouble(_Keys.bengaliScale, value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
