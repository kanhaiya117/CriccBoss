class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.link,
    required this.source,
    required this.summary,
    this.publishedAt,
  });

  final String title;
  final String link;
  final String source;
  final String summary;
  final DateTime? publishedAt;
}
