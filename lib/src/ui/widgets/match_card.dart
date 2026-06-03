import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.trailing,
  });

  final CricketMatch match;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusPill(status: match.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.series,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                match.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                match.scoreSummary,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                match.status == MatchStatus.upcoming
                    ? DateFormat('EEE, h:mm a').format(match.startTime)
                    : match.latestEvent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                match.venue,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
