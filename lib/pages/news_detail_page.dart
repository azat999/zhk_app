import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsDetailPage extends StatefulWidget {
  final int newsId;

  const NewsDetailPage({Key? key, required this.newsId}) : super(key: key);

  @override
  _NewsDetailPageState createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late Future<Map<String, dynamic>> _newsDetail;
  String? _userRole; // Переменная для роли пользователя

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _newsDetail = fetchNewsDetail(widget.newsId);
  }

  Future<void> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role'); // Получаем роль пользователя
    });
  }

  Future<Map<String, dynamic>> fetchNewsDetail(int id) async {
    final url = Uri.parse('https://sabahome.kz/main/news/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedResponse = utf8.decode(response.bodyBytes);
      return json.decode(decodedResponse);
    } else {
      throw Exception('Ошибка загрузки новости');
    }
  }

  void _navigateToEditNews() {
    // Навигация на страницу редактирования новости
    debugPrint('Переход на экран редактирования новости');
    // Реализуйте переход на страницу редактирования
    // Navigator.push(...);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Новости',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
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
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Условное отображение кнопки "Редактировать" для роли admin
                    if (_userRole == 'admin')
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _navigateToEditNews,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.edit, color: Color(0xFFFFBB00),size: 12,),
                              SizedBox(width: 4),
                              Text(
                                'Редактировать',
                                style: TextStyle(
                                  color: Color(0xFFFFBB00),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      news['short_description'],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 16),
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
