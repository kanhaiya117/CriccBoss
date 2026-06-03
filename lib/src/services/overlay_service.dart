import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  Future<bool> ensurePermission() async {
    if (await FlutterOverlayWindow.isPermissionGranted()) return true;
    return await FlutterOverlayWindow.requestPermission() ?? false;
  }

  Future<void> showScoreBubble(CricketMatch match) async {
    if (!await ensurePermission()) return;
    await FlutterOverlayWindow.shareData({
      'title': match.title,
      'score': match.scoreSummary,
      'matchId': match.id,
    });
    if (await FlutterOverlayWindow.isActive()) return;
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: 'CricBoss',
      overlayContent: match.scoreSummary,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      height: 132,
      width: 360,
      positionGravity: PositionGravity.auto,
    );
  }

  Future<void> close() => FlutterOverlayWindow.closeOverlay();
}
