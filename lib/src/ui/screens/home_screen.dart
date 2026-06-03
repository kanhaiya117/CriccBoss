import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:cricboss/src/providers/app_providers.dart';
import 'package:cricboss/src/ui/screens/favorites_screen.dart';
import 'package:cricboss/src/ui/screens/live_match_screen.dart';
import 'package:cricboss/src/ui/screens/settings_screen.dart';
import 'package:cricboss/src/ui/widgets/adaptive_banner.dart';
import 'package:cricboss/src/ui/widgets/match_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _MatchesView(onOpen: _openMatch),
      const FavoritesScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('CricBoss'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(matchesProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdaptiveBanner(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.sports_cricket),
                label: 'Matches',
              ),
              NavigationDestination(
                icon: Icon(Icons.star_border),
                selectedIcon: Icon(Icons.star),
                label: 'Favorites',
              ),
              NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
            ],
          ),
        ],
      ),
    );
  }

  void _openMatch(String id) =>
      Navigator.of(context).pushNamed(LiveMatchScreen.route, arguments: id);
}

class _MatchesView extends ConsumerWidget {
  const _MatchesView({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider);
    final favorites = ref.watch(favoriteTeamsProvider);
    return matches.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _List(
        matches: ref.read(mockFactoryProvider).matches(),
        favorites: favorites,
        onOpen: onOpen,
      ),
      data: (items) => _List(
        matches: items.isEmpty
            ? ref.read(mockFactoryProvider).matches()
            : items,
        favorites: favorites,
        onOpen: onOpen,
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.matches,
    required this.favorites,
    required this.onOpen,
  });

  final List<CricketMatch> matches;
  final List<String> favorites;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final sorted = [...matches]
      ..sort((a, b) {
        final af = favorites.any(a.involvesTeam) ? 0 : 1;
        final bf = favorites.any(b.involvesTeam) ? 0 : 1;
        return af.compareTo(bf);
      });
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => MatchCard(
        match: sorted[index],
        onTap: () => onOpen(sorted[index].id),
      ),
    );
  }
}
