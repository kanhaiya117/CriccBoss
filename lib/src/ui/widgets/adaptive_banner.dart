import 'package:cricboss/src/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdaptiveBanner extends ConsumerWidget {
  const AdaptiveBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(adsServiceProvider).adaptiveBanner(context);
}
