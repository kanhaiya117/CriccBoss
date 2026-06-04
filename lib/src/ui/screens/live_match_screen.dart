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
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Match details are unavailable from the API right now.',
            ),
          ),
        ),
        data: (match) {
          _handleLiveSystems(match);
          return _MatchBody(match: match);
        },
      ),
    );
  }

  void _handleLiveSystems(CricketMatch match) {
    if (ref.read(pinnedMatchIdProvider) == match.id) {
      ref.read(notificationServiceProvider).showPinnedScore(match);
    }
    if (match.commentary.isEmpty) return;
    final latest = match.commentary.first;
    if (_announcedEventId == latest.id) return;
    _announcedEventId = latest.id;
    if (!ref.read(enabledVoiceEventsProvider).contains(latest.type)) return;
    ref.read(notificationServiceProvider).showEvent(match, latest);
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
              Tab(text: 'Scorecard'),
              Tab(text: 'Commentary'),
              Tab(text: 'Squads'),
              Tab(text: 'Info'),
            ],
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _Scorecard(scorecard: match.scorecard),
                _Commentary(match: match),
                _Squads(match: match),
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
    final pinned = ref.watch(pinnedMatchIdProvider) == match.id;
    final saved = ref.watch(savedMatchIdsProvider).contains(match.id);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(status: match.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.series,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TeamScorePanel(team: match.teamA, match: match),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TeamScorePanel(team: match.teamB, match: match),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniStat(label: 'CRR', value: _rate(match.currentRunRate)),
                _MiniStat(label: 'RRR', value: _rate(match.requiredRunRate)),
                _MiniStat(
                  label: 'Target',
                  value: match.targetScore?.toString() ?? '-',
                ),
                _MiniStat(label: 'Overs', value: match.oversProgress),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _toggleVoice(context, ref),
                    icon: const Icon(Icons.record_voice_over),
                    label: Text(
                      ref.watch(voiceModeProvider) == VoiceMode.off
                          ? 'Voice Off'
                          : 'Voice On',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _togglePin(ref, pinned),
                  icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
                  tooltip: pinned ? 'Unpin match' : 'Pin match',
                ),
                IconButton.filledTonal(
                  onPressed: () => _toggleSaved(ref, saved),
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  tooltip: saved ? 'Remove reminder' : 'Save reminder',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(WidgetRef ref, bool pinned) async {
    final next = pinned ? null : match.id;
    ref.read(pinnedMatchIdProvider.notifier).state = next;
    await ref.read(storageProvider).setPinnedMatchId(next);
    if (next == null) {
      await ref.read(notificationServiceProvider).cancelPinnedScore();
    } else {
      await ref.read(notificationServiceProvider).init();
      await ref.read(notificationServiceProvider).showPinnedScore(match);
    }
  }

  Future<void> _toggleSaved(WidgetRef ref, bool saved) async {
    final current = ref.read(savedMatchIdsProvider);
    final next = saved
        ? current.where((id) => id != match.id).toList()
        : [...current, match.id];
    ref.read(savedMatchIdsProvider.notifier).state = next;
    await ref.read(storageProvider).setSavedMatchIds(next);
  }

  void _toggleVoice(BuildContext context, WidgetRef ref) {
    final current = ref.read(voiceModeProvider);
    final next = current == VoiceMode.off
        ? VoiceMode.importantOnly
        : VoiceMode.off;
    ref.read(voiceModeProvider.notifier).state = next;
    ref.read(storageProvider).setVoiceMode(next);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _VoiceEventSheet(),
    );
  }

  String _rate(double? value) => value == null ? '-' : value.toStringAsFixed(2);
}

class _TeamScorePanel extends StatelessWidget {
  const _TeamScorePanel({required this.team, required this.match});
  final Team team;
  final CricketMatch match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Text(_shortLogo(team.shortName)),
            ),
            const SizedBox(height: 10),
            Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              team.shortName,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              match.scoreTextForTeam(team),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  String _shortLogo(String value) => value.length <= 2
      ? value.toUpperCase()
      : value.substring(0, 2).toUpperCase();
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$label $value',
          style: TextStyle(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MatchStatus.live => Colors.red,
      MatchStatus.upcoming => Colors.blue,
      MatchStatus.completed => Colors.green,
    };
    final text = switch (status) {
      MatchStatus.live => 'LIVE',
      MatchStatus.upcoming => 'UPCOMING',
      MatchStatus.completed => 'RESULT',
    };
    return Chip(
      label: Text(text),
      avatar: Icon(Icons.circle, color: color, size: 10),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
      side: BorderSide(color: color.withValues(alpha: .28)),
      backgroundColor: color.withValues(alpha: .10),
    );
  }
}

class _VoiceEventSheet extends ConsumerWidget {
  const _VoiceEventSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(enabledVoiceEventsProvider);
    final events = const [
      AlertEventType.four,
      AlertEventType.six,
      AlertEventType.fifty,
      AlertEventType.century,
      AlertEventType.wicket,
      AlertEventType.inningsBreak,
      AlertEventType.partnership,
      AlertEventType.matchResult,
    ];
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          'Voice Events',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        for (final event in events)
          SwitchListTile(
            value: enabled.contains(event),
            title: Text(_eventLabel(event)),
            onChanged: (value) async {
              final next = {...enabled};
              value ? next.add(event) : next.remove(event);
              ref.read(enabledVoiceEventsProvider.notifier).state = next;
              await ref.read(storageProvider).setEnabledVoiceEvents(next);
            },
          ),
      ],
    );
  }

  String _eventLabel(AlertEventType event) => switch (event) {
    AlertEventType.four => 'Four',
    AlertEventType.six => 'Six',
    AlertEventType.fifty => 'Fifty',
    AlertEventType.century => 'Century',
    AlertEventType.wicket => 'Wicket',
    AlertEventType.inningsBreak => 'Innings Break',
    AlertEventType.partnership => 'Partnership Milestone',
    AlertEventType.matchResult => 'Match Result',
    AlertEventType.normal => 'Normal',
  };
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
          DataColumn(label: Text('SR')),
        ],
        rows: [
          for (final line in scorecard.batting)
            DataRow(
              color: WidgetStatePropertyAll(
                line == scorecard.batting.first
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: .35)
                    : null,
              ),
              cells: [
                DataCell(Text(line.playerName)),
                DataCell(Text('${line.runs}')),
                DataCell(Text('${line.balls}')),
                DataCell(Text('${line.fours}/${line.sixes}')),
                DataCell(Text(_strikeRate(line))),
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
          DataColumn(label: Text('M')),
          DataColumn(label: Text('R')),
          DataColumn(label: Text('W/Eco')),
        ],
        rows: [
          for (final line in scorecard.bowling)
            DataRow(
              cells: [
                DataCell(Text(line.playerName)),
                DataCell(Text('${line.overs}')),
                DataCell(Text('${line.maidens}')),
                DataCell(Text('${line.runs}')),
                DataCell(
                  Text('${line.wickets}/${line.economy.toStringAsFixed(1)}'),
                ),
              ],
            ),
        ],
      ),
    ],
  );

  String _strikeRate(BattingLine line) => line.balls == 0
      ? '-'
      : ((line.runs / line.balls) * 100).toStringAsFixed(1);
}

class _Squads extends StatelessWidget {
  const _Squads({required this.match});
  final CricketMatch match;

  @override
  Widget build(BuildContext context) {
    final teamA = match.players
        .where((player) => player.teamId == match.teamA.id)
        .toList();
    final teamB = match.players
        .where((player) => player.teamId == match.teamB.id)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SquadSection(team: match.teamA, players: teamA),
        const SizedBox(height: 18),
        _SquadSection(team: match.teamB, players: teamB),
      ],
    );
  }
}

class _SquadSection extends StatelessWidget {
  const _SquadSection({required this.team, required this.players});
  final Team team;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Playing XI', style: Theme.of(context).textTheme.labelLarge),
            for (final entry in players.take(11).indexed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person),
                title: Text(
                  '${entry.$2.name}${entry.$1 == 0
                      ? ' (C)'
                      : entry.$1 == 1
                      ? ' (WK)'
                      : ''}',
                ),
                subtitle: Text(entry.$2.role),
              ),
            if (players.length > 11) ...[
              const Divider(),
              Text(
                'Substitutes',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              for (final player in players.skip(11))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(player.name),
                  subtitle: Text(player.role),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.match});
  final CricketMatch match;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ListTile(title: const Text('Match'), subtitle: Text(match.title)),
      ListTile(title: const Text('Venue'), subtitle: Text(match.venue)),
      ListTile(
        title: const Text('Toss'),
        subtitle: Text(match.toss ?? 'Updating'),
      ),
      ListTile(
        title: const Text('Overs Progress'),
        subtitle: Text(match.oversProgress),
      ),
      ListTile(
        title: const Text('Current Run Rate'),
        subtitle: Text(match.currentRunRate?.toStringAsFixed(2) ?? '-'),
      ),
      ListTile(
        title: const Text('Required Run Rate'),
        subtitle: Text(match.requiredRunRate?.toStringAsFixed(2) ?? '-'),
      ),
      ListTile(
        title: const Text('Result'),
        subtitle: Text(match.result ?? 'Match in progress'),
      ),
    ],
  );
}
