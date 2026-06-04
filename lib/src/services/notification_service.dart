import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings(
        '@drawable/ic_cricboss_launcher',
      );
      await _plugin.initialize(const InitializationSettings(android: android));
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> showEvent(CricketMatch match, CommentaryEvent event) async {
    if (!_initialized) return;
    if (!event.isImportant) return;
    try {
      await _plugin.show(
        event.id.hashCode,
        _title(event.type),
        '${match.title}: ${event.text}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cricboss_events',
            'Match alerts',
            channelDescription:
                'Fours, sixes, wickets, milestones, and results',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 90, amplitude: 80);
      }
    } catch (_) {}
  }

  Future<void> showPinnedScore(CricketMatch match) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        7,
        'CricBoss Live',
        '${match.title}  ${match.scoreSummary}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cricboss_live',
            'Pinned live score',
            channelDescription: 'Persistent live score updates',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: false,
          ),
        ),
      );
    } catch (_) {}
  }

  String _title(AlertEventType type) => switch (type) {
    AlertEventType.four => 'Four',
    AlertEventType.six => 'Six',
    AlertEventType.wicket => 'Wicket',
    AlertEventType.fifty => 'Fifty',
    AlertEventType.century => 'Century',
    AlertEventType.inningsBreak => 'Innings break',
    AlertEventType.partnership => 'Partnership',
    AlertEventType.matchResult => 'Match result',
    AlertEventType.normal => 'CricBoss',
  };

  Future<void> cancelPinnedScore() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(7);
    } catch (_) {}
  }
}
