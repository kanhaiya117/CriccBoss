class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.link,
    required this.source,
    this.publishedAt,
  });

  final String title;
  final String link;
  final String source;
  final DateTime? publishedAt;
}
