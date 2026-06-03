import 'dart:async';

import 'package:cricboss/src/app/cricboss_app.dart';
import 'package:cricboss/src/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CricBossOverlayApp()));
}

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (kDebugMode) {
          debugPrint(details.exceptionAsString());
        }
      };

      await LocalStorageService.instance.init();
      runApp(const ProviderScope(child: CricBossApp()));
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught app error: $error');
        debugPrintStack(stackTrace: stack);
      }
    },
  );
}
