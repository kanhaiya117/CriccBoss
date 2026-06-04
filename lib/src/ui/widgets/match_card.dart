import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatefulWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.trailing,
    this.compact = false,
  });

  final CricketMatch match;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool compact;

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.match.commentary.firstOrNull?.isImportant ?? false) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final important = widget.match.commentary.firstOrNull?.isImportant ?? false;
    if (important && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!important && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final eventColor = _eventColor(widget.match.commentary.firstOrNull?.type);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = widget.match.commentary.firstOrNull?.isImportant ?? false
            ? 0.10 + (_controller.value * 0.10)
            : 0.07;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: eventColor.withValues(alpha: glow),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.all(widget.compact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusPill(status: widget.match.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.match.series,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    ?widget.trailing,
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _TeamBadge(team: widget.match.teamA),
                    const SizedBox(width: 10),
                    Text(
                      'vs',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _TeamBadge(team: widget.match.teamB),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.match.scoreSummary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.match.status == MatchStatus.upcoming
                      ? DateFormat(
                          'EEE, d MMM • h:mm a',
                        ).format(widget.match.startTime)
                      : widget.match.latestEvent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!widget.compact) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _Metric(
                        label: 'CRR',
                        value: _rate(widget.match.currentRunRate),
                      ),
                      _Metric(
                        label: 'RRR',
                        value: _rate(widget.match.requiredRunRate),
                      ),
                      _Metric(
                        label: 'Target',
                        value: widget.match.targetScore?.toString() ?? '-',
                      ),
                      _Metric(
                        label: 'Overs',
                        value: widget.match.oversProgress,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.match.venue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _eventColor(AlertEventType? type) => switch (type) {
    AlertEventType.four => Colors.blue,
    AlertEventType.six => Colors.deepPurple,
    AlertEventType.wicket => Colors.red,
    AlertEventType.fifty || AlertEventType.century => Colors.amber,
    _ => Theme.of(context).colorScheme.shadow,
  };

  String _rate(double? value) => value == null ? '-' : value.toStringAsFixed(2);
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.secondaryContainer,
            child: Text(
              _shortLogo(team.shortName),
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.shortName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortLogo(String value) => value.length <= 2
      ? value.toUpperCase()
      : value.substring(0, 2).toUpperCase();
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MatchStatus.live => Colors.red,
      MatchStatus.upcoming => Colors.blue,
      MatchStatus.completed => Colors.green,
    };
    final label = switch (status) {
      MatchStatus.live => 'LIVE',
      MatchStatus.upcoming => 'UPCOMING',
      MatchStatus.completed => 'RESULT',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
