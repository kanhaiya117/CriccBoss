import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:cricboss/src/providers/app_providers.dart';
import 'package:cricboss/src/ui/screens/favorites_screen.dart';
import 'package:cricboss/src/ui/screens/live_match_screen.dart';
import 'package:cricboss/src/ui/screens/match_list_screen.dart';
import 'package:cricboss/src/ui/screens/news_detail_screen.dart';
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
      _Dashboard(onOpen: _openMatch),
      const FavoritesScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(Icons.sports_cricket, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'CricBoss',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
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
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
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

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider);
    final favorites = ref.watch(favoriteTeamsProvider);
    final savedIds = ref.watch(savedMatchIdsProvider);
    return matches.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _DashboardContent(
        matches: const [],
        favorites: favorites,
        savedIds: savedIds,
        onOpen: onOpen,
        onRefresh: () async => ref.invalidate(matchesProvider),
        offline: true,
      ),
      data: (items) => _DashboardContent(
        matches: items,
        favorites: favorites,
        savedIds: savedIds,
        onOpen: onOpen,
        onRefresh: () async => ref.invalidate(matchesProvider),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.matches,
    required this.favorites,
    required this.savedIds,
    required this.onOpen,
    required this.onRefresh,
    this.offline = false,
  });

  final List<CricketMatch> matches;
  final List<String> favorites;
  final List<String> savedIds;
  final ValueChanged<String> onOpen;
  final Future<void> Function() onRefresh;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final live = _byStatus(MatchStatus.live);
    final upcoming = _byStatus(MatchStatus.upcoming);
    final results = _byStatus(MatchStatus.completed).take(2).toList();
    final saved = matches
        .where((match) => savedIds.contains(match.id))
        .toList();
    final featured = _featuredMatch(live);
    final cached = matches.where((match) => match.isCached).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          if (offline)
            const _InfoBanner(
              icon: Icons.cloud_off,
              text:
                  'Live API unavailable. Pull to refresh or check the RapidAPI key.',
            ),
          if (!offline && cached.isNotEmpty)
            _InfoBanner(
              icon: Icons.history,
              text: _cachedMessage(context, cached),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Live Cricket',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const _LiveDot(),
            ],
          ),
          const SizedBox(height: 14),
          if (featured != null)
            MatchCard(match: featured, onTap: () => onOpen(featured.id))
          else
            const _InfoBanner(
              icon: Icons.event_available,
              text: 'No live match available from the API right now.',
            ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              _DashboardTile(
                icon: Icons.flash_on,
                title: 'Live Matches',
                count: live.length,
                color: Colors.red,
                onTap: () => _openList(context, 'Live Matches', live),
              ),
              _DashboardTile(
                icon: Icons.event,
                title: 'Upcoming',
                count: upcoming.length,
                color: Colors.blue,
                onTap: () => _openList(context, 'Upcoming Matches', upcoming),
              ),
              _DashboardTile(
                icon: Icons.emoji_events,
                title: 'Results',
                count: results.length,
                color: Colors.green,
                onTap: () => _openList(context, 'Recent Results', results),
              ),
              _DashboardTile(
                icon: Icons.bookmark,
                title: 'Saved Matches',
                count: saved.length,
                color: Colors.orange,
                onTap: () => _openList(context, 'Saved Matches', saved),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Top Cricket News',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const _TopNewsList(),
        ],
      ),
    );
  }

  String _cachedMessage(BuildContext context, List<CricketMatch> matches) {
    final times = matches
        .map((match) => match.lastUpdated)
        .whereType<DateTime>()
        .toList();
    if (times.isEmpty) {
      return 'Live updates are temporarily unavailable. Showing the last saved records.';
    }
    times.sort();
    final time = TimeOfDay.fromDateTime(times.last.toLocal()).format(context);
    return 'Live updates are temporarily unavailable. Showing records from $time.';
  }

  List<CricketMatch> _byStatus(MatchStatus status) =>
      matches.where((match) => match.status == status).toList();

  CricketMatch? _featuredMatch(List<CricketMatch> live) {
    if (live.isEmpty) return null;
    final india = live.where((match) => match.involvesTeam('India')).toList();
    if (india.isNotEmpty) return india.first;
    final ipl = live.where((match) => match.isIpl).toList();
    if (ipl.isNotEmpty) return ipl.first;
    final favorite = live
        .where((match) => favorites.any((team) => match.involvesTeam(team)))
        .toList();
    if (favorite.isNotEmpty) return favorite.first;
    return live.first;
  }

  void _openList(
    BuildContext context,
    String title,
    List<CricketMatch> matches,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchListScreen(title: title, matches: matches),
      ),
    );
  }
}

class _TopNewsList extends ConsumerWidget {
  const _TopNewsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(cricketNewsProvider);
    return news.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const _InfoBanner(
        icon: Icons.article_outlined,
        text: 'Cricket news is unavailable right now.',
      ),
      data: (items) {
        if (items.isEmpty) {
          return const _InfoBanner(
            icon: Icons.article_outlined,
            text: 'No cricket news available right now.',
          );
        }
        return Column(
          children: [
            for (final item in items) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NewsDetailScreen(article: item),
                    ),
                  ),
                  leading: const CircleAvatar(child: Icon(Icons.newspaper)),
                  title: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    item.summary.isEmpty ? item.source : item.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .14),
                child: Icon(icon, color: color),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .45, end: 1).animate(_controller),
    child: const Row(
      children: [
        Icon(Icons.circle, color: Colors.red, size: 10),
        SizedBox(width: 6),
        Text('LIVE'),
      ],
    ),
  );
}
