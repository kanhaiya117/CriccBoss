import 'package:cricboss/src/data/datasources/cricket_remote_datasource.dart';
import 'package:cricboss/src/data/repositories/cricket_repository_impl.dart';
import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:cricboss/src/domain/repositories/cricket_repository.dart';
import 'package:cricboss/src/services/ads_service.dart';
import 'package:cricboss/src/services/country_service.dart';
import 'package:cricboss/src/services/cricket_news_service.dart';
import 'package:cricboss/src/services/local_storage_service.dart';
import 'package:cricboss/src/services/notification_service.dart';
import 'package:cricboss/src/services/overlay_service.dart';
import 'package:cricboss/src/services/tts_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final storageProvider = Provider((ref) => LocalStorageService.instance);
final dioProvider = Provider(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  ),
);
final cricketRepositoryProvider = Provider<CricketRepository>((ref) {
  return CricketRepositoryImpl(
    RapidApiCricketDataSource(ref.watch(dioProvider)),
  );
});
final matchesProvider = StreamProvider(
  (ref) => ref.watch(cricketRepositoryProvider).watchMatches(),
);
final cricketNewsProvider = FutureProvider(
  (ref) => CricketNewsService(ref.watch(dioProvider)).latest(),
);
final matchProvider = FutureProvider.family<CricketMatch, String>(
  (ref, id) => ref.watch(cricketRepositoryProvider).getMatch(id),
);
final overlayServiceProvider = Provider((ref) => OverlayService());
final ttsServiceProvider = Provider((ref) => TtsService());
final notificationServiceProvider = Provider(
  (ref) => NotificationService.instance,
);
final adsServiceProvider = Provider((ref) => AdsService.instance);
final localCountryTeamProvider = Provider(
  (ref) => CountryService().detectCountryTeam(),
);

final favoriteTeamsProvider = StateProvider<List<String>>(
  (ref) => ref.watch(storageProvider).favoriteTeams,
);
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => ref.watch(storageProvider).themeMode,
);
final voiceModeProvider = StateProvider<VoiceMode>(
  (ref) => ref.watch(storageProvider).voiceMode,
);
final languageProvider = StateProvider<CommentaryLanguage>(
  (ref) => ref.watch(storageProvider).language,
);
final pinnedMatchIdProvider = StateProvider<String?>(
  (ref) => ref.watch(storageProvider).pinnedMatchId,
);
final savedMatchIdsProvider = StateProvider<List<String>>(
  (ref) => ref.watch(storageProvider).savedMatchIds,
);
final enabledVoiceEventsProvider = StateProvider<Set<AlertEventType>>(
  (ref) => ref.watch(storageProvider).enabledVoiceEvents,
);
