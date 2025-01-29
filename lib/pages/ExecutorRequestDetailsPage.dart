import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ExecutorRequestDetailsPage extends StatefulWidget {
  final int requestId;

  const ExecutorRequestDetailsPage({Key? key, required this.requestId}) : super(key: key);

  @override
  _ExecutorRequestDetailsPageState createState() => _ExecutorRequestDetailsPageState();
}

class _ExecutorRequestDetailsPageState extends State<ExecutorRequestDetailsPage> {
  bool isLoading = true;
  Map<String, dynamic>? requestDetails;
  String? errorMessage;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Токен отсутствует. Авторизуйтесь заново.';
      });
      return;
    }

    final url = 'https://sabahome.kz/main/applications/${widget.requestId}/executor-details/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          requestDetails = json.decode(utf8.decode(response.bodyBytes));
          selectedStatus = requestDetails?['status'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Ошибка загрузки данных. Код: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Ошибка соединения: $e';
      });
    }
  }

  Future<void> _updateRequestStatus() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Токен отсутствует. Авторизуйтесь заново.';
      });
      return;
    }

    final url = 'https://sabahome.kz/main/applications/${widget.requestId}/executor-update/';
    final body = json.encode({'status': selectedStatus});

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // Успешное обновление
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статус успешно обновлен')),
        );
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Ошибка обновления. Код: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Ошибка соединения: $e';
      });
    }
  }

  String _getFullImageUrl(String? imagePath) {
    const baseUrl = 'https://sabahome.kz';
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    if (imagePath.startsWith('/')) {
      return '$baseUrl$imagePath';
    }
    return imagePath;
  }

  String _formatDate(String? date) {
    if (date == null) return 'Не указано';
    final parsedDate = DateTime.parse(date);

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

    return '$day $month, $time';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Детали заявки')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Детали заявки')),
        body: Center(child: Text(errorMessage!)),
      );
    }

    final executor = requestDetails?['executor'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали заявки'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requestDetails?['title'] ?? 'Без названия',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (requestDetails?['photo_video'] != null) ...[
              Image.network(
                _getFullImageUrl(requestDetails!['photo_video']),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Не удалось загрузить изображение');
                },
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Комментарий:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(requestDetails?['comment'] ?? 'Нет комментария'),
            const SizedBox(height: 16),
            Text(
              'Исполнитель:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (executor != null)
              Text('${executor['full_name'] ?? 'Не указано'}')
            else
              const Text('Не назначен'),
            const SizedBox(height: 16),
            Text(
              'Когда исполнить:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_formatDate(requestDetails?['execute_at'])),
            const SizedBox(height: 16),
            Text(
              'Статус:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            DropdownButton<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'created', child: Text('Подана')),
                DropdownMenuItem(value: 'in_progress', child: Text('В процессе')),
                DropdownMenuItem(value: 'completed', child: Text('Завершена')),
                DropdownMenuItem(value: 'rejected', child: Text('Отклонена')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                   height: 48,
                      width: 326,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
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
                            color: Color(0xFFFFBB00),
                            offset: Offset(0, 0),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateRequestStatus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                    ),
                    child: const Text(
                      'Сохранить',
                      style: TextStyle(  
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 48,
                      width: 320,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Color(0xFFFFBA00),
                          width: 1.5,
                        ),
                      ),
                     
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFBB00)),
                      shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Отменить',
                      style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFBA00),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
