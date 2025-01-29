import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart';

class NewsDetailPage extends StatefulWidget {
  final int newsId;

  const NewsDetailPage({Key? key, required this.newsId}) : super(key: key);

  @override
  _NewsDetailPageState createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late Future<Map<String, dynamic>> _newsDetail;

  @override
  void initState() {
    super.initState();
    _newsDetail = fetchNewsDetail(widget.newsId);
  }

  Future<Map<String, dynamic>> fetchNewsDetail(int id) async {
    final url = Uri.parse('https://sabahome.kz/main/news/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Декодируем ответ с использованием UTF-8
      final decodedResponse = utf8.decode(response.bodyBytes);
      return json.decode(decodedResponse);
    } else {
      throw Exception('Ошибка загрузки новости');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: const Text('Новости', style: TextStyle(
          fontSize: 24,
         
          fontWeight: FontWeight.w700
        ),),
        backgroundColor: const Color(0xFFFFFFF),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _newsDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Нет данных'));
          } else {
            final news = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.only(left: 26, right: 26, top: 12, bottom: 12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   
                    Text(
                      news['short_description'],
                      style: const TextStyle(fontSize: 18, color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                    const SizedBox(height: 16),
                    // Обработка HTML-разметки
                    Html(
                      data: news['description'], // HTML-данные
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
