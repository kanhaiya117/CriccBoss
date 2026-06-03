import 'package:cricboss/src/app/app_theme.dart';
import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/providers/app_providers.dart';
import 'package:cricboss/src/ui/screens/home_screen.dart';
import 'package:cricboss/src/ui/screens/live_match_screen.dart';
import 'package:cricboss/src/ui/widgets/overlay_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CricBossApp extends ConsumerStatefulWidget {
  const CricBossApp({super.key});

  @override
  ConsumerState<CricBossApp> createState() => _CricBossAppState();
}

class _CricBossAppState extends ConsumerState<CricBossApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(adsServiceProvider).showAppOpenAdOnce(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routes: {
        '/': (_) => const HomeScreen(),
        LiveMatchScreen.route: (_) => const LiveMatchScreen(),
      },
    );
  }
}

class CricBossOverlayApp extends StatelessWidget {
  const CricBossOverlayApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark(),
    home: const OverlayBubble(),
  );
}
