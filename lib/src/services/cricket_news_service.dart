import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/domain/models/news_article.dart';
import 'package:dio/dio.dart';

class CricketNewsService {
  CricketNewsService(this._dio);

  final Dio _dio;

  Future<List<NewsArticle>> latest() async {
    try {
      final response = await _dio.get(
        '${AppConfig.rapidApiCricketBaseUrl}/news',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-rapidapi-host': AppConfig.rapidApiCricketHost,
            'x-rapidapi-key': AppConfig.rapidApiCricketKey,
          },
        ),
      );
      final data = response.data;
      if (data is! Map || data['data'] is! List) return const [];
      final articles = <NewsArticle>[];
      for (final item in data['data'] as List) {
        if (item is! Map) continue;
        final title = _clean('${item['title'] ?? 'Cricket update'}');
        final description = _clean('${item['description'] ?? ''}');
        final content = _clean(_contentText(item['content']));
        if (!_isCricketNews('$title $description')) continue;
        articles.add(
          NewsArticle(
            title: title,
            link: '',
            source: 'CricBoss News',
            summary: content.isNotEmpty ? content : description,
            publishedAt: null,
          ),
        );
        if (articles.length == 3) break;
      }
      return articles;
    } catch (_) {
      return const [];
    }
  }

  String _clean(String value) => value
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&ldquo;', '"')
      .replaceAll('&rdquo;', '"')
      .replaceAll('&mdash;', '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _contentText(dynamic value) {
    if (value is List) return value.join(' ');
    return '${value ?? ''}';
  }

  bool _isCricketNews(String value) {
    final text = value.toLowerCase();
    if (text.contains('fifa') || text.contains('football')) return false;
    return const [
      'cricket',
      'bcci',
      'icc',
      'ipl',
      'odi',
      't20',
      'test match',
      'team india',
      'ranji',
      'ashes',
      'wtc',
    ].any(text.contains);
  }
}
