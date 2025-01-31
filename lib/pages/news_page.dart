import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zhk_app/pages/AddNewsPage.dart';
import 'package:zhk_app/services/UserRoleProvider.dart';
import '../models/news_model.dart';
import '../widgets/news_item.dart';
import '../services/news_service.dart';
import 'login_page.dart';
import 'package:zhk_app/widgets/user_role_provider.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final NewsService _newsService = NewsService();
  late Future<List<News>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() {
    setState(() {
      _newsFuture = _newsService.fetchNews();
    });
  }

  Future<void> _refreshNews() async {
    _loadNews();
    await _newsFuture;
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _navigateToAddNews() {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => AddNewsPage()),
  );
    print('Переход на экран добавления новости');
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<UserRoleProvider>(context).role;
    final isAuthenticated = userRole != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        title: isAuthenticated
            ? Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/icons/logo.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Главная',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: _navigateToLogin,
                child: const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Вход/Регистрация',
                    style: TextStyle(
                      color: Color(0xFFF2E594),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'InstrumentSans',
                    ),
                  ),
                ),
              ),
      ),
      body: FutureBuilder<List<News>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет новостей'));
          } else {
            final newsList = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshNews,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 22, top: 20, right: 22, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Новости",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'InstrumentSans',
                            color: Color(0xFF232323),
                          ),
                        ),
                        if (userRole == 'admin')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 10,
                                  onPressed: _navigateToAddNews,
                                  icon: const Icon(Icons.add, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _navigateToAddNews,
                                child: const Text(
                                  'Добавить',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: newsList.length,
                      itemBuilder: (context, index) {
                        final news = newsList[index];
                        return NewsItem(news: news);
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
