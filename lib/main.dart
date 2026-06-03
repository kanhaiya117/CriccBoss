import 'package:cricboss/src/app/cricboss_app.dart';
import 'package:cricboss/src/services/ads_service.dart';
import 'package:cricboss/src/services/local_storage_service.dart';
import 'package:cricboss/src/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CricBossOverlayApp()));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.instance.init();
  await NotificationService.instance.init();
  await AdsService.instance.init();
  await FlutterOverlayWindow.isPermissionGranted();

  runApp(const ProviderScope(child: CricBossApp()));
}
