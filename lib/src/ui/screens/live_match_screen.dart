import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:cricboss/src/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key});

  static const route = '/match';

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  String? _announcedEventId;

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String? ?? 'm1';
    final asyncMatch = ref.watch(matchProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Live Match')),
      body: asyncMatch.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _MatchBody(match: ref.read(mockFactoryProvider).matches().first),
        data: (match) {
          _handleLiveSystems(match);
          return _MatchBody(match: match);
        },
      ),
    );
  }

  void _handleLiveSystems(CricketMatch match) {
    if (match.commentary.isEmpty) return;
    final latest = match.commentary.first;
    if (_announcedEventId == latest.id) return;
    _announcedEventId = latest.id;
    ref.read(notificationServiceProvider).showEvent(match, latest);
    ref.read(notificationServiceProvider).showPinnedScore(match);
    ref
        .read(ttsServiceProvider)
        .speak(latest, ref.read(voiceModeProvider), ref.read(languageProvider));
  }
}

class _MatchBody extends ConsumerWidget {
  const _MatchBody({required this.match});

  final CricketMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          _Header(match: match),
          TabBar(
            tabs: const [
              Tab(text: 'Live'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Players'),
              Tab(text: 'Info'),
            ],
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _Commentary(match: match),
                _Scorecard(scorecard: match.scorecard),
                _Players(players: match.players),
                _Info(match: match),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.match});
  final CricketMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.series, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              match.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              match.scoreSummary,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(overlayServiceProvider).showScoreBubble(match),
                  icon: const Icon(Icons.picture_in_picture_alt),
                  label: const Text('Bubble'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(notificationServiceProvider)
                      .showPinnedScore(match),
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Pin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Commentary extends StatelessWidget {
  const _Commentary({required this.match});
  final CricketMatch match;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: match.commentary.length,
    separatorBuilder: (_, _) => const Divider(height: 24),
    itemBuilder: (context, index) {
      final event = match.commentary[index];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              event.overLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(event.text)),
        ],
      );
    },
  );
}

class _Scorecard extends StatelessWidget {
  const _Scorecard({required this.scorecard});
  final Scorecard scorecard;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Batting', style: Theme.of(context).textTheme.titleLarge),
      DataTable(
        columns: const [
          DataColumn(label: Text('Batter')),
          DataColumn(label: Text('R')),
          DataColumn(label: Text('B')),
          DataColumn(label: Text('4/6')),
        ],
        rows: [
          for (final line in scorecard.batting)
            DataRow(
              cells: [
                DataCell(Text(line.playerName)),
                DataCell(Text('${line.runs}')),
                DataCell(Text('${line.balls}')),
                DataCell(Text('${line.fours}/${line.sixes}')),
              ],
            ),
        ],
      ),
      const SizedBox(height: 18),
      Text('Bowling', style: Theme.of(context).textTheme.titleLarge),
      DataTable(
        columns: const [
          DataColumn(label: Text('Bowler')),
          DataColumn(label: Text('O')),
          DataColumn(label: Text('R')),
          DataColumn(label: Text('W')),
        ],
        rows: [
          for (final line in scorecard.bowling)
            DataRow(
              cells: [
                DataCell(Text(line.playerName)),
                DataCell(Text('${line.overs}')),
                DataCell(Text('${line.runs}')),
                DataCell(Text('${line.wickets}')),
              ],
            ),
        ],
      ),
    ],
  );
}

class _Players extends StatelessWidget {
  const _Players({required this.players});
  final List<Player> players;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: players.length,
    itemBuilder: (_, index) => ListTile(
      leading: const Icon(Icons.person),
      title: Text(players[index].name),
      subtitle: Text(players[index].role),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.match});
  final CricketMatch match;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ListTile(title: const Text('Venue'), subtitle: Text(match.venue)),
      ListTile(
        title: const Text('Toss'),
        subtitle: Text(match.toss ?? 'Updating'),
      ),
      ListTile(
        title: const Text('Result'),
        subtitle: Text(match.result ?? 'Match in progress'),
      ),
    ],
  );
}
