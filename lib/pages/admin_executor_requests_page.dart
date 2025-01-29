import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:zhk_app/pages/ExecutorRequestDetailsPage.dart';
import 'AdminRequestDetailsPage.dart';


class AdminExecutorRequestsPage extends StatefulWidget {
  final String userRole; // "admin" or "executor"

  const AdminExecutorRequestsPage({Key? key, required this.userRole}) : super(key: key);

  @override
  _AdminExecutorRequestsPageState createState() => _AdminExecutorRequestsPageState();
}

class _AdminExecutorRequestsPageState extends State<AdminExecutorRequestsPage> {
  String selectedCategory = 'all'; // Default category
  bool isLoading = false;
  List<dynamic> allRequests = [];
  List<dynamic> inProgressRequests = [];
  List<dynamic> completedRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchAllRequests();
  }

  Future<void> _fetchAllRequests() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      debugPrint('Токен отсутствует.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final allResponse = await _fetchRequests(
          'https://sabahome.kz/main/applications/by-housing-complex', token);
      final inProgressResponse = await _fetchRequests(
          'https://sabahome.kz/main/applications/in-progress', token);
      final completedResponse = await _fetchRequests(
          'https://sabahome.kz/main/applications/completed', token);

      setState(() {
        allRequests = allResponse;
        inProgressRequests = inProgressResponse;
        completedRequests = completedResponse;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки заявок: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<dynamic>> _fetchRequests(String url, String token) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      debugPrint('Ошибка загрузки данных: ${response.statusCode}');
      return [];
    }
  }

  void _navigateToDetails(Map<String, dynamic> request) async {
  // Получаем роль из SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final userRole = prefs.getString('user_role');

  debugPrint('Navigating to details. SharedPreferences Role: $userRole, Request: ${request.toString()}');

  if (userRole == 'executor') {
    Navigator.push(
      context,
      MaterialPageRoute(
         builder: (context) => ExecutorRequestDetailsPage(requestId: request['id']),
      ),
    );
  } else if (userRole == 'admin') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRequestDetailsPage(
          request,
          requestId: request['id'],
        ),
      ),
    );
  } else {
    debugPrint('Unknown role: $userRole');
  }
}

  Widget _buildRequestList(List<dynamic> requests) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22), // Паддинг у списка
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0), // Убираем внутренний отступ
              title: Text(
                request['title'] ?? 'Без названия',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _formatDate(request['created_at']),
                style: const TextStyle(
                  color: Color(0xFF8A8A8A),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Text(
                _formatStatus(request['status']),
                style: TextStyle(
                  color: _getStatusColor(request['status']),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _navigateToDetails(request),
            ),
            const Divider(
              color: Color(0xFFe5e5e5), // Цвет разделительной линии
              thickness: 1, // Толщина линии
              height: 1, // Высота Divider
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryButton(
      String category, String label, bool isFirst, bool isLast) {
    final isSelected = selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = category;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFBB00) : Colors.white,
            border: Border.all(color: const Color(0xFFFFBB00)),
            borderRadius: BorderRadius.only(
              topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
              bottomLeft: isFirst ? const Radius.circular(20) : Radius.zero,
              topRight: isLast ? const Radius.circular(20) : Radius.zero,
              bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return Row(
      children: [
        _buildCategoryButton('all', 'Все заявки', true, false),
        _buildCategoryButton('in_progress', 'В процессе', false, false),
        _buildCategoryButton('completed', 'Завершенные', false, true),
      ],
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';

    final parsedDate = DateTime.parse(date);

    // Карта названий месяцев в родительном падеже
    final monthNames = {
      1: 'января',
      2: 'февраля',
      3: 'марта',
      4: 'апреля',
      5: 'мая',
      6: 'июня',
      7: 'июля',
      8: 'августа',
      9: 'сентября',
      10: 'октября',
      11: 'ноября',
      12: 'декабря',
    };

    final day = parsedDate.day;
    final month = monthNames[parsedDate.month];
    final time = '${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}';

    return '$day $month, $time'; // Пример: "01 января, 14:30"
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'created':
        return 'Подана';
      case 'in_progress':
        return 'В процессе';
      case 'completed':
        return 'Завершена';
      case 'rejected':
        return 'Отклонена';
      case 'responsible_added':
        return 'Ответственный назначен';
      case 'responsible_change':
        return 'Ответственный переназначен';
      default:
        return 'Неизвестный';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'created':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'responsible_added':
        return const Color.fromARGB(255, 0, 0, 0); // Цвет для статуса "Ответственный назначен"
      case 'responsible_change':
        return const Color.fromARGB(255, 0, 0, 0); // Цвет для статуса "Ответственный переназначен"
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRequests = selectedCategory == 'all'
        ? allRequests
        : selectedCategory == 'in_progress'
            ? inProgressRequests
            : completedRequests;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text('Заявки'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 6),
            child: _buildCategoryButtons(),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildRequestList(currentRequests),
          ),
        ],
      ),
    );
  }
}
