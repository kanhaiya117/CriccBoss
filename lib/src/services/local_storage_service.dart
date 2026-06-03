import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  LocalStorageService._();
  static final instance = LocalStorageService._();

  static const _settingsBox = 'settings';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_settingsBox);
    await _box.put('favoriteTeams', favoriteTeams);
  }

  List<String> get favoriteTeams => List<String>.from(
    _box.get('favoriteTeams', defaultValue: const ['India']),
  );
  Future<void> setFavoriteTeams(List<String> teams) =>
      _box.put('favoriteTeams', teams);

  ThemeMode get themeMode =>
      ThemeMode.values[_box.get(
        'themeMode',
        defaultValue: ThemeMode.system.index,
      )];
  Future<void> setThemeMode(ThemeMode mode) =>
      _box.put('themeMode', mode.index);

  VoiceMode get voiceMode =>
      VoiceMode.values[_box.get(
        'voiceMode',
        defaultValue: VoiceMode.importantOnly.index,
      )];
  Future<void> setVoiceMode(VoiceMode mode) =>
      _box.put('voiceMode', mode.index);

  CommentaryLanguage get language =>
      CommentaryLanguage.values[_box.get(
        'language',
        defaultValue: CommentaryLanguage.english.index,
      )];
  Future<void> setLanguage(CommentaryLanguage language) =>
      _box.put('language', language.index);

  DateTime? get lastAppOpenAdAt {
    final value = _box.get('lastAppOpenAdAt');
    return value is String ? DateTime.tryParse(value) : null;
  }

  Future<void> setLastAppOpenAdAt(DateTime time) =>
      _box.put('lastAppOpenAdAt', time.toIso8601String());
}
