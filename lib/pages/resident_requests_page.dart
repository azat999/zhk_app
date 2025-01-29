import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:zhk_app/pages/CreateRequestPage.dart';
import 'package:zhk_app/pages/RequestDetailsPage.dart';

class ResidentRequestsPage extends StatefulWidget {
  const ResidentRequestsPage({Key? key}) : super(key: key);

  @override
  _ResidentRequestsPageState createState() => _ResidentRequestsPageState();
}

class _ResidentRequestsPageState extends State<ResidentRequestsPage> {
  int _selectedTabIndex = 0;
  bool isLoading = true;

  List<dynamic> activeRequests = [];
  List<dynamic> historyRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // Запрос активных заявок
      final activeResponse = await http.get(
        Uri.parse('https://sabahome.kz/main/applications/active/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (activeResponse.statusCode == 200) {
        activeRequests = json.decode(utf8.decode(activeResponse.bodyBytes));
      }

      // Запрос заявок из истории
      final historyResponse = await http.get(
        Uri.parse('https://sabahome.kz/main/applications/history/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (historyResponse.statusCode == 200) {
        historyRequests = json.decode(utf8.decode(historyResponse.bodyBytes));
      }
    } catch (e) {
      debugPrint('Ошибка загрузки заявок: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Заявка',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ------ Вкладки ------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Левая кнопка "Активные"
                      Expanded(
                        child: _buildTabButton('Активные', 0,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                            )),
                      ),
                      // Правая кнопка "История"
                      Expanded(
                        child: _buildTabButton('История', 1,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                            )),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ------ Содержимое выбранной вкладки ------
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchRequests,
                    child: _selectedTabIndex == 0
                        ? _buildRequestsList(activeRequests, isActive: true)
                        : _buildRequestsList(historyRequests, isActive: false),
                  ),
                ),

                // ------ Кнопка "Создать заявку" ------
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD971),
                          Color(0xFFFFC832),
                          Color(0xFFFFBA00),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFBB00),
                          offset: Offset(0, 0),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateRequestPage()),
                        ).then((_) {
                          // После возврата обновляем список заявок
                          _fetchRequests();
                        });
                      },
                      child: const Text(
                        'Создать заявку',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Построение кнопки-табика (с кастомным скруглением углов).
  Widget _buildTabButton(String title, int index,
      {required BorderRadius borderRadius}) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        alignment: Alignment.center,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFBA00) : Colors.white,
          border: Border.all(color: const Color(0xFFFFBA00), width: 1.5),
          borderRadius: borderRadius,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : const Color(0xFFFFBA00),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<dynamic> requests, {required bool isActive}) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          isActive ? 'У вас пока нет активных заявок' : 'История заявок пуста',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final status = request['status'] ?? 'Неизвестно';
        final statusColor = _getStatusColor(status);

        return ListTile(
          title: Text(
            request['title'] ?? 'Без названия',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            _formatDate(request['created_at']),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestDetailsPage(
                  requestId: request['id'],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'created':
        return const Color(0xFF8A8A8A); // Подана
      case 'in_progress':
        return const Color(0xFFFFCD45); // В процессе
      case 'completed':
        return const Color(0xFF4BBF4F); // Завершена
      case 'rejected':
        return const Color(0xFFFF7745); // Отклонена
      default:
        return Colors.grey; // Неизвестный статус
    }
  }

  String _getStatusText(String status) {
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
        return 'Неизвестно';
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return '';
    final date = DateTime.parse(dateTime);
    return '${date.day}.${date.month}.${date.year}  '
           '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
