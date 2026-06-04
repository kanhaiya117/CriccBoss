import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/domain/models/news_article.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

class CricketNewsService {
  CricketNewsService(this._dio);

  final Dio _dio;
  List<NewsArticle> _cached = const [];
  DateTime? _cachedAt;
  static const _cacheDuration = Duration(minutes: 20);
  static const _fallbackFeed =
      'https://news.google.com/rss/search?q=(BCCI%20OR%20ICC%20OR%20IPL)%20cricket&hl=en-IN&gl=IN&ceid=IN:en';

  Future<List<NewsArticle>> latest() async {
    final cachedAt = _cachedAt;
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheDuration &&
        _cached.isNotEmpty) {
      return _cached;
    }
    var providerArticles = const <NewsArticle>[];
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
        if (!_isPriorityNews('$title $description $content')) continue;
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
      providerArticles = articles;
      if (providerArticles.length >= 3) return _remember(providerArticles);
    } catch (_) {
      if (_cached.isNotEmpty) return _cached;
    }
    final fallback = await _googleNewsFallback();
    if (fallback.isNotEmpty) return _remember(fallback);
    if (providerArticles.isNotEmpty) return _remember(providerArticles);
    return _cached;
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

  bool _isPriorityNews(String value) {
    final text = value.toLowerCase();
    if (!_isCricketNews(text)) return false;
    return const [
      'bcci',
      'icc',
      'ipl',
      'indian premier league',
      'international cricket council',
      'board of control for cricket in india',
    ].any(text.contains);
  }

  Future<List<NewsArticle>> _googleNewsFallback() async {
    try {
      final response = await _dio.get<String>(_fallbackFeed);
      final body = response.data;
      if (body == null || body.trim().isEmpty) return const [];
      final document = XmlDocument.parse(body);
      final articles = <NewsArticle>[];
      for (final item in document.findAllElements('item')) {
        final title = _clean(
          item.getElement('title')?.innerText.trim() ?? 'Cricket update',
        );
        final description = _clean(
          item.getElement('description')?.innerText.trim() ?? '',
        );
        if (!_isPriorityNews('$title $description')) continue;
        articles.add(
          NewsArticle(
            title: title,
            link: item.getElement('link')?.innerText.trim() ?? '',
            source: 'ICC/BCCI/IPL News',
            summary: description.isEmpty
                ? 'Open this update to read the latest cricket news summary.'
                : description,
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

  List<NewsArticle> _remember(List<NewsArticle> articles) {
    _cached = articles;
    _cachedAt = DateTime.now();
    return articles;
  }
}
