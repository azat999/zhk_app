import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zhk_app/services/UserRoleProvider.dart';
import 'package:zhk_app/widgets/user_role_provider.dart';
import 'pages/news_page.dart';
import 'pages/messages_page.dart';
import 'pages/my_home_page.dart';
import 'pages/menu_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserRoleProvider()..initialize()..loadRole()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ЖК Новости',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NewsListPage(),
    );
  }
}

class NewsListPage extends StatefulWidget {
  @override
  _NewsListPageState createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRoleProvider>(
      builder: (context, userRoleProvider, child) {
        final userRole = userRoleProvider.role;

        // Определяем экраны на основе роли пользователя
        final List<Widget> screens = userRole == "admin" || userRole == "executor"
            ? [NewsPage(), MyHomePage(), MenuPage()]
            : [NewsPage(), MessagesPage(), MyHomePage(), MenuPage()];

        // Определяем элементы меню на основе роли пользователя
        final List<BottomNavigationBarItem> menuItems = userRole == "admin" || userRole == "executor"
            ? [
                BottomNavigationBarItem(
                  icon: SvgPicture.asset('assets/icons/dashboard.svg', color: _currentIndex == 0 ? Color(0xFFFFBB00) : Colors.white),
                  label: 'Главная',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset('assets/icons/home.svg', color: _currentIndex == 1 ? Color(0xFFFFBB00) : Colors.white),
                  label: 'Мой дом',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset('assets/icons/profile-circle.svg', color: _currentIndex == 2 ? Color(0xFFFFBB00) : Colors.white),
                  label: 'Меню',
                ),
              ]
            : [
                BottomNavigationBarItem(
                  icon: SvgPicture.asset('assets/icons/dashboard.svg', color: _currentIndex == 0 ? Color(0xFFFFBB00): Colors.white),
                  label: 'Главная',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset('assets/icons/message-edit.svg', color: _currentIndex == 1 ? Color(0xFFFFBB00) : Colors.white),
                  label: 'Сообщения',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset('assets/icons/home.svg', color: _currentIndex == 2 ? Color(0xFFFFBB00): Colors.white),
                  label: 'Мой дом',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset('assets/icons/profile-circle.svg', color: _currentIndex == 3 ? Color(0xFFFFBB00) : Colors.white),
                  label: 'Меню',
                ),
              ];

        // Убедимся, что текущий индекс в допустимом диапазоне
        if (_currentIndex >= screens.length) {
          _currentIndex = 0; // Сброс на первый экран
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF232323),
            selectedItemColor: Color(0xFFFFBB00),
            unselectedItemColor: Colors.white,
            items: menuItems,
          ),
        );
      },
    );
  }
}
