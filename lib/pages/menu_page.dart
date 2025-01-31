import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:zhk_app/pages/AdminComplaintsPage.dart';
import 'package:zhk_app/pages/ComplaintsSuggestionsPage.dart';
import 'package:zhk_app/pages/CreateVotingPage.dart';
import 'package:zhk_app/pages/VotingPage.dart';
import 'package:zhk_app/pages/admin_executor_requests_page.dart';
import 'package:zhk_app/pages/login_page.dart';
import 'package:zhk_app/pages/resident_requests_page.dart';
import 'package:zhk_app/services/UserRoleProvider.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? _fullName;
  String? _phone;
  String? _housingComplex;
  String? _apartment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://sabahome.kz/main/profile/'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final decodedData = utf8.decode(response.bodyBytes);
          final data = json.decode(decodedData);

          // Сохранение данных в SharedPreferences
          await prefs.setString('full_name', data['full_name']);
          await prefs.setString('phone', data['phone']);
          await prefs.setString('housing_complex', data['housing_complex']['name']);
          await prefs.setString('apartment', data['apartment']);

          setState(() {
            _fullName = data['full_name'];
            _phone = data['phone'];
            _housingComplex = data['housing_complex']['name'];
            _apartment = data['apartment'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Provider.of<UserRoleProvider>(context, listen: false).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRoleProvider>(
      builder: (context, userRoleProvider, child) {
        final isAuthenticated = userRoleProvider.isAuthenticated;

        // Если состояние аутентификации изменилось, повторно загружаем данные
        if (isAuthenticated && _isLoading) {
          _fetchProfile();
        }

        if (_isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: AppBar(
            title: const Text(
              'Меню',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFFF2E594),
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: const Color(0xFF232323),
            centerTitle: true,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (isAuthenticated) _buildProfileTile() else _buildLoginTile(),
              const SizedBox(height: 24),
              _buildMenuTile('assets/icons/message-edit(1).svg', 'Заявки'),
              const SizedBox(height: 24),
              _buildMenuTile('assets/icons/lamp-on.svg', 'Жалобы/Предложения'),
              const SizedBox(height: 24),
              _buildMenuTile('assets/icons/messages-3.svg', 'Голосование'),
              const SizedBox(height: 24),
              _buildMenuTile('assets/icons/help_circle.svg', 'Поддержка'),
              if (isAuthenticated) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _logout(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD971),
                          Color(0xFFFFC832),
                          Color(0xFFFFBA00),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFBB00).withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Выйти',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginTile() {
    return SizedBox(
      height: 70,
      width: 350,
      child: Container(
        decoration: _tileDecoration(),
        child: ListTile(
          leading: SvgPicture.asset(
            'assets/icons/login.svg',
            width: 40,
            height: 40,
          ),
          title: const Text(
            'Вход/Регистрация',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            ).then((_) {
              // Возврат с экрана логина, проверяем состояние
              _fetchProfile();
            });
          },
        ),
      ),
    );
  }

  Widget _buildProfileTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            offset: Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/profile-circle.svg',
            width: 40,
            height: 40,
            color: const Color(0xFFFFBB00),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _fullName ?? 'Имя не указано',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phone ?? 'Телефон не указан',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9C9C9C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(String svgIconPath, String title) {
  return GestureDetector(
    onTap: () async {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');

      if (title == 'Голосование') {
        if (userRole == 'admin') {
          // Переход на страницу создания голосования для администратора
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateVotingPage(), // Страница создания голосования
            ),
          );
        } else if (userRole == 'resident') {
          // Переход на страницу просмотра голосований для жителей
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VotingPage(), // Страница просмотра голосований
            ),
          );
        } else {
          // Показываем сообщение для других ролей
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Доступно только для администратора и жителей')),
          );
        }
      } else if (title == 'Жалобы/Предложения') {
        if (userRole == 'resident') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintsSuggestionsPage(),
            ),
          );
        } else if (userRole == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminComplaintsPage(),
            ),
          );
        }
      } else if (title == 'Заявки') {
        if (userRole == 'resident') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResidentRequestsPage(),
            ),
          );
        } else if (userRole == 'admin' || userRole == 'executor') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminExecutorRequestsPage(userRole: ''),
            ),
          );
        }
      }
    },
    child: SizedBox(
      height: 60,
      width: 350,
      child: Container(
        decoration: _tileDecoration(),
        child: ListTile(
          leading: SvgPicture.asset(
            svgIconPath,
            width: 30,
            height: 30,
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}




  BoxDecoration _tileDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
