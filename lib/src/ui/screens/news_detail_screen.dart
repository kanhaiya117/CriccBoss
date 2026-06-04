import 'package:cricboss/src/domain/models/news_article.dart';
import 'package:flutter/material.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cricket News')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            article.source,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            article.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                article.summary,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
          ),
          if (article.link.isNotEmpty) ...[
            const SizedBox(height: 18),
            SelectableText(
              article.link,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
