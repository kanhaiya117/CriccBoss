import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:cricboss/src/ui/screens/live_match_screen.dart';
import 'package:cricboss/src/ui/widgets/match_card.dart';
import 'package:flutter/material.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({
    super.key,
    required this.title,
    required this.matches,
  });

  final String title;
  final List<CricketMatch> matches;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: matches.isEmpty
          ? const Center(child: Text('No matches found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => MatchCard(
                match: matches[index],
                onTap: () => Navigator.of(context).pushNamed(
                  LiveMatchScreen.route,
                  arguments: matches[index].id,
                ),
              ),
            ),
    );
  }
}
