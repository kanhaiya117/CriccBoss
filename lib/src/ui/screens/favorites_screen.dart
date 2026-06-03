import 'package:cricboss/src/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  static const teams = [
    'India',
    'Australia',
    'England',
    'Pakistan',
    'New Zealand',
    'South Africa',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(favoriteTeamsProvider);
    final local = ref.watch(localCountryTeamProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.public),
          title: const Text('Detected local team'),
          subtitle: Text(local),
          trailing: FilledButton(
            onPressed: () => _toggle(ref, selected, local),
            child: const Text('Use'),
          ),
        ),
        const SizedBox(height: 12),
        for (final team in teams)
          CheckboxListTile(
            value: selected.contains(team),
            onChanged: (_) => _toggle(ref, selected, team),
            title: Text(team),
            secondary: const Icon(Icons.sports_cricket),
          ),
      ],
    );
  }

  Future<void> _toggle(
    WidgetRef ref,
    List<String> selected,
    String team,
  ) async {
    final next = selected.contains(team)
        ? selected.where((item) => item != team).toList()
        : [...selected, team];
    ref.read(favoriteTeamsProvider.notifier).state = next;
    await ref.read(storageProvider).setFavoriteTeams(next);
  }
}
