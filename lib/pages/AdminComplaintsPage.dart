import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminComplaintsPage extends StatefulWidget {
  @override
  _AdminComplaintsPageState createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  late Future<List<dynamic>> _complaints;

  @override
  void initState() {
    super.initState();
    _complaints = fetchComplaints();
  }

  Future<List<dynamic>> fetchComplaints() async {
    const url = 'https://sabahome.kz/main/complaints/';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен не найден');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decodedResponse = utf8.decode(response.bodyBytes);
      return json.decode(decodedResponse);
    } else {
      throw Exception('Ошибка загрузки жалоб: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           
            
            const Text(
              'Жалобы/Предложения',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF2E594)),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF232323),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _complaints,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Жалобы отсутствуют',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          } else {
            final complaints = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: MediaQuery.of(context).size.height * 0.8, // Ограничиваем высоту
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true, // Позволяет списку сжиматься
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    itemCount: complaints.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.grey,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final complaint = complaints[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                          child: Image.asset(
                            'assets/icons/user-square.png', // Путь к пользовательской иконке
                            width: 48,
                            height: 48,
                          ),
                        ),
                        title: Text(
                          complaint['user'] ?? 'Анонимный пользователь',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          complaint['description'] ?? 'Без описания',
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          debugPrint('Жалоба ID: ${complaint['id']}');
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Сообщения',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Мой дом',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Меню',
          ),
        ],
      ),
    );
  }
}
