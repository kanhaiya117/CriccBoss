import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/domain/models/news_article.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

class CricketNewsService {
  CricketNewsService(this._dio);

  final Dio _dio;

  Future<List<NewsArticle>> latest() async {
    try {
      final response = await _dio.get<String>(AppConfig.cricketNewsFeedUrl);
      final body = response.data;
      if (body == null || body.trim().isEmpty) return const [];
      final document = XmlDocument.parse(body);
      return document.findAllElements('item').take(3).map((item) {
        final title =
            item.getElement('title')?.innerText.trim() ?? 'Cricket update';
        final link = item.getElement('link')?.innerText.trim() ?? '';
        final dateText = item.getElement('pubDate')?.innerText.trim();
        return NewsArticle(
          title: title,
          link: link,
          source: 'Cricket News',
          publishedAt: dateText == null ? null : DateTime.tryParse(dateText),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }
}
