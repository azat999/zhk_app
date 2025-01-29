import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhk_app/services/UserRoleProvider.dart';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? housingComplexName;
  String? apartment;
  List<dynamic> executors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      try {
        // Запрос для получения профиля
        final profileResponse = await http.get(
          Uri.parse('https://sabahome.kz/main/profile/'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (profileResponse.statusCode == 200) {
          final decodedProfileData = utf8.decode(profileResponse.bodyBytes);
          final profileData = json.decode(decodedProfileData);

          final housingComplex = profileData['housing_complex'];
          housingComplexName = housingComplex?['name'] ?? 'ЖК не указан';
          apartment = profileData['apartment'] ?? 'Квартира не указана';

          // Сохраняем в SharedPreferences
          await prefs.setString('housing_complex_name', housingComplexName!);
          await prefs.setString('apartment', apartment!);

          // Запрос для получения исполнителей
          final executorsResponse = await http.get(
            Uri.parse(
                'https://sabahome.kz/main/users/executors-by-housing-complex/?name=$housingComplexName'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (executorsResponse.statusCode == 200) {
            final decodedExecutorsData = utf8.decode(executorsResponse.bodyBytes);
            setState(() {
              executors = json.decode(decodedExecutorsData);
              isLoading = false;
            });
          } else {
            debugPrint('Ошибка получения исполнителей: ${executorsResponse.statusCode}');
            setState(() {
              isLoading = false;
            });
          }
        } else {
          debugPrint('Ошибка получения профиля: ${profileResponse.statusCode}');
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Ошибка: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      debugPrint('Токен отсутствует');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    ).then((value) {
      if (value == true) {
        _fetchData(); // Перезагружаем данные после возврата с экрана авторизации
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRoleProvider>(
      builder: (context, userRoleProvider, child) {
        if (!userRoleProvider.isAuthenticated) {
          return Scaffold(
            backgroundColor: Color(0xFFFFFFFF),
            appBar: AppBar(
              title: const Text(
                'Мой дом',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFFF2E594),
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: const Color(0xFF232323),
            ),
            body: _buildNotAuthenticatedUI(context),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: AppBar(
            title: const Text(
              'Мой дом',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFFF2E594),
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: const Color(0xFF232323),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildHousingInfoTile(),
                    const SizedBox(height: 24),
                    ...executors.map((executor) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildExecutorTile(executor),
                      );
                    }).toList(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildNotAuthenticatedUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/image5.png',
            width: 300,
            height: 300,
          ),
          const SizedBox(height: 60),
          OutlinedButton(
            onPressed: () => _navigateToLogin(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFBB00), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 12),
            ),
            child: const Text(
              'Авторизоваться',
              style: TextStyle(
                color: Color(0xFFFFBB00),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousingInfoTile() {
    return Container(
      width: 247,
      height: 48,
      margin: const EdgeInsets.only(top: 5, left: 5, right: 100),
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
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              width: 35,
              height: 35,
              child: SvgPicture.asset(
                'assets/icons/Group5.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ЖК ${housingComplexName ?? 'ЖК не указан'}",
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'InstrumentSans',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C9C9C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Квартира №$apartment',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'InstrumentSans',
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutorTile(Map<String, dynamic> executor) {
    final phone = executor['phone'] ?? 'Номер не указан';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          width: 30,
          height: 31,
          child: SvgPicture.asset(
            'assets/icons/user.svg',
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Менеджер объекта',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'InstrumentSans',
                color: Color(0xFF9C9C9C),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              executor['full_name'] ?? 'Имя не указано',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'InstrumentSans',
              ),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _makePhoneCall(phone),
          child: Container(
            width: 33,
            height: 33,
            child: SvgPicture.asset(
              'assets/icons/call.svg',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri callUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      debugPrint('Невозможно выполнить звонок на номер: $phone');
    }
  }
}
