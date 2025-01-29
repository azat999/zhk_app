import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsService {
  final String baseUrl = 'https://sabahome.kz';

  Future<List<News>> fetchNews() async {
    final response = await http.get(Uri.parse('$baseUrl/main/news'));

    if (response.statusCode == 200) {
      // Используем utf8.decode для правильной кодировки
      final decodedResponse = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(decodedResponse);
      return data.map((json) => News.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки новостей');
    }
  }
}
