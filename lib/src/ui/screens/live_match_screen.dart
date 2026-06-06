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
          return Column(
            children: [
              if (match.isCached) _CachedDataBanner(match: match),
              Expanded(child: _MatchBody(match: match)),
            ],
          );
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
              Tab(text: 'Summary'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Commentary'),
              Tab(text: 'Playing XI'),
            ],
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _Info(match: match),
                _Scorecard(match: match),
                _Commentary(match: match),
                _PlayingXi(match: match),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CachedDataBanner extends StatelessWidget {
  const _CachedDataBanner({required this.match});

  final CricketMatch match;

  @override
  Widget build(BuildContext context) {
    final updated = match.lastUpdated;
    final time = updated == null
        ? 'the last successful update'
        : TimeOfDay.fromDateTime(updated.toLocal()).format(context);
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Live updates are temporarily unavailable. Showing records from $time.',
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
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

class _Scorecard extends StatefulWidget {
  const _Scorecard({required this.match});
  final CricketMatch match;

  @override
  State<_Scorecard> createState() => _ScorecardState();
}

class _ScorecardState extends State<_Scorecard> {
  late String _teamId = widget.match.teamA.id;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final batting = match.scorecard.batting
        .where((line) => line.teamId == null || line.teamId == _teamId)
        .toList();
    final bowling = match.scorecard.bowling;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TeamSelector(
          teamA: match.teamA,
          teamB: match.teamB,
          selectedId: _teamId,
          onSelected: (id) => setState(() => _teamId = id),
        ),
        const SizedBox(height: 18),
        const _ScoreHeader(),
        if (batting.isEmpty)
          const _EmptySection(text: 'Scorecard is not available yet.')
        else
          for (final line in batting) _BatterRow(line: line),
        if (bowling.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('BOWLERS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (final line in bowling) _BowlerRow(line: line),
        ],
      ],
    );
  }
}

class _PlayingXi extends StatefulWidget {
  const _PlayingXi({required this.match});
  final CricketMatch match;

  @override
  State<_PlayingXi> createState() => _PlayingXiState();
}

class _PlayingXiState extends State<_PlayingXi> {
  late String _teamId = widget.match.teamA.id;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final players = match.players
        .where((player) => player.teamId == _teamId)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TeamSelector(
          teamA: match.teamA,
          teamB: match.teamB,
          selectedId: _teamId,
          onSelected: (id) => setState(() => _teamId = id),
        ),
        const SizedBox(height: 18),
        Text('PLAYING XI', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (players.isEmpty)
          const _EmptySection(text: 'Playing XI is not available yet.')
        else
          for (final player in players.take(11)) _PlayerRow(player: player),
        if (players.length > 11) ...[
          const SizedBox(height: 22),
          Text('SUBSTITUTES', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (final player in players.skip(11))
            _PlayerRow(player: player, substitute: true),
        ],
      ],
    );
  }
}

class _TeamSelector extends StatelessWidget {
  const _TeamSelector({
    required this.teamA,
    required this.teamB,
    required this.selectedId,
    required this.onSelected,
  });

  final Team teamA;
  final Team teamB;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final team in [teamA, teamB])
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(team.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selectedId == team.id
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    team.shortName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selectedId == team.id
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('BATTERS', style: style)),
          for (final label in const ['R', 'B', '4s', '6s', 'SR'])
            SizedBox(
              width: label == 'SR' ? 48 : 34,
              child: Text(label, textAlign: TextAlign.center, style: style),
            ),
        ],
      ),
    );
  }
}

class _BatterRow extends StatelessWidget {
  const _BatterRow({required this.line});

  final BattingLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                _InitialAvatar(name: line.playerName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        line.outText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _ScoreValue('${line.runs}', bold: true),
          _ScoreValue('${line.balls}'),
          _ScoreValue('${line.fours}'),
          _ScoreValue('${line.sixes}'),
          _ScoreValue(_strikeRate(line), wide: true),
        ],
      ),
    );
  }

  String _strikeRate(BattingLine line) => line.balls == 0
      ? '-'
      : ((line.runs / line.balls) * 100).toStringAsFixed(2);
}

class _BowlerRow extends StatelessWidget {
  const _BowlerRow({required this.line});

  final BowlingLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialAvatar(name: line.playerName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.playerName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${line.overs} O  ${line.maidens} M  ${line.runs} R  '
                  '${line.wickets} W  ${line.economy.toStringAsFixed(2)} ECO',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreValue extends StatelessWidget {
  const _ScoreValue(this.value, {this.bold = false, this.wide = false});

  final String value;
  final bool bold;
  final bool wide;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: wide ? 48 : 34,
    child: Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500),
    ),
  );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, this.substitute = false});

  final Player player;
  final bool substitute;

  @override
  Widget build(BuildContext context) {
    final role = player.role.toLowerCase();
    final hasMarker =
        player.name.contains('(C)') || player.name.contains('(WK)');
    final suffix = hasMarker
        ? ''
        : role.contains('captain')
        ? ' (C)'
        : role.contains('wicket')
        ? ' (WK)'
        : '';
    final detail = [
      if (player.battingStyle?.isNotEmpty ?? false) player.battingStyle,
      player.role,
    ].whereType<String>().join(' • ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _InitialAvatar(name: player.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.name}$suffix',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  substitute ? 'Substitute • $detail' : detail,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cleaned = name.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    final initials = parts
        .take(2)
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Icon(
          Icons.hourglass_empty,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
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
